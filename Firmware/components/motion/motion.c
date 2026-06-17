#include "motion.h"

#include <math.h>

#include "driver/gpio.h"
#include "driver/ledc.h"
#include "esp_timer.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "motion";

/* Motor pins (DRV8833) */
#define MOTOR_A_FWD 1
#define MOTOR_A_REV 2
#define MOTOR_B_FWD 4
#define MOTOR_B_REV 3
#define MOTOR_PWM_FREQ 1000
#define MOTOR_PWM_RES 8
#define MOTOR_TIMEOUT_MS 2000
#define MOTOR_MIN_PCT 40
#define MOTOR_KICK_PCT 80
#define MOTOR_KICK_MS 100
#define MOTOR_RAMP_RATE 15.0f

#define LASER_GPIO GPIO_NUM_9  /* active-low: HIGH = OFF */
#define SERVO_GPIO 43

static volatile int motor_target_drive = 0;
static volatile int motor_target_turn = 0;
static float motor_current_drive_f = 0.0f;
static float motor_current_turn_f = 0.0f;
static bool motor_a_was_stopped = true;
static bool motor_b_was_stopped = true;
static volatile bool motors_running = false;
static int64_t last_motor_cmd_us = 0;

static volatile bool g_laser_on = false;

static int apply_dead_zone(int abs_speed)
{
    if (abs_speed <= 0) return 0;
    int min_pwm = (MOTOR_MIN_PCT * 255) / 100;
    return min_pwm + (abs_speed - 1) * (255 - min_pwm) / 254;
}

static void kick_start(int fwd_ch, int rev_ch, int speed)
{
    int kick = (MOTOR_KICK_PCT * 255) / 100;
    ledc_set_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)fwd_ch, speed > 0 ? kick : 0);
    ledc_update_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)fwd_ch);
    ledc_set_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)rev_ch, speed < 0 ? kick : 0);
    ledc_update_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)rev_ch);
    vTaskDelay(pdMS_TO_TICKS(MOTOR_KICK_MS));
}

static void set_one_motor(int fwd_ch, int rev_ch, int speed, bool *was_stopped, bool skip_kick)
{
    if (speed != 0) {
        if (*was_stopped && !skip_kick) kick_start(fwd_ch, rev_ch, speed);
        *was_stopped = false;
        int fwd_duty = speed > 0 ? apply_dead_zone(speed) : 0;
        int rev_duty = speed < 0 ? apply_dead_zone(-speed) : 0;
        ledc_set_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)fwd_ch, fwd_duty);
        ledc_update_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)fwd_ch);
        ledc_set_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)rev_ch, rev_duty);
        ledc_update_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)rev_ch);
    } else {
        ledc_set_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)fwd_ch, 0);
        ledc_update_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)fwd_ch);
        ledc_set_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)rev_ch, 0);
        ledc_update_duty(LEDC_LOW_SPEED_MODE, (ledc_channel_t)rev_ch);
        *was_stopped = true;
    }
}

static void set_motors(int drive, int turn, bool skip_kick)
{
    int left = drive + turn;
    int right = drive - turn;
    if (left > 255) left = 255;
    if (left < -255) left = -255;
    if (right > 255) right = 255;
    if (right < -255) right = -255;
    set_one_motor(LEDC_CHANNEL_0, LEDC_CHANNEL_1, left, &motor_a_was_stopped, skip_kick);
    set_one_motor(LEDC_CHANNEL_2, LEDC_CHANNEL_3, right, &motor_b_was_stopped, skip_kick);
    motors_running = (drive != 0 || turn != 0);
}

static void motors_stop(void)
{
    motor_target_drive = 0;
    motor_target_turn = 0;
    motor_current_drive_f = 0.0f;
    motor_current_turn_f = 0.0f;
    set_motors(0, 0, false);
    motors_running = false;
    motor_a_was_stopped = true;
    motor_b_was_stopped = true;
}

static void motor_ramp_task(void *pv)
{
    while (true) {
        vTaskDelay(pdMS_TO_TICKS(20));
        float td = (float)motor_target_drive;
        float tt = (float)motor_target_turn;
        float dd = td - motor_current_drive_f;
        if (dd > MOTOR_RAMP_RATE) dd = MOTOR_RAMP_RATE;
        if (dd < -MOTOR_RAMP_RATE) dd = -MOTOR_RAMP_RATE;
        motor_current_drive_f += dd;
        if (fabsf(motor_current_drive_f - td) < 0.5f) motor_current_drive_f = td;
        float dt = tt - motor_current_turn_f;
        if (dt > MOTOR_RAMP_RATE) dt = MOTOR_RAMP_RATE;
        if (dt < -MOTOR_RAMP_RATE) dt = -MOTOR_RAMP_RATE;
        motor_current_turn_f += dt;
        if (fabsf(motor_current_turn_f - tt) < 0.5f) motor_current_turn_f = tt;
        set_motors((int)motor_current_drive_f, (int)motor_current_turn_f, true);
    }
}

static void motor_safety_task(void *pv)
{
    while (true) {
        if (motors_running && (esp_timer_get_time() - last_motor_cmd_us > MOTOR_TIMEOUT_MS * 1000)) {
            motors_stop();
        }
        vTaskDelay(pdMS_TO_TICKS(200));
    }
}

static void init_motors(void)
{
    ledc_timer_config_t timer = {
        .speed_mode = LEDC_LOW_SPEED_MODE,
        .duty_resolution = (ledc_timer_bit_t)MOTOR_PWM_RES,
        .timer_num = LEDC_TIMER_0,
        .freq_hz = MOTOR_PWM_FREQ,
        .clk_cfg = LEDC_AUTO_CLK,
    };
    ESP_ERROR_CHECK(ledc_timer_config(&timer));
    const int pins[4] = { MOTOR_A_FWD, MOTOR_A_REV, MOTOR_B_FWD, MOTOR_B_REV };
    const ledc_channel_t chs[4] = { LEDC_CHANNEL_0, LEDC_CHANNEL_1, LEDC_CHANNEL_2, LEDC_CHANNEL_3 };
    for (int i = 0; i < 4; i++) {
        ledc_channel_config_t ch = {
            .gpio_num = pins[i],
            .speed_mode = LEDC_LOW_SPEED_MODE,
            .channel = chs[i],
            .intr_type = LEDC_INTR_DISABLE,
            .timer_sel = LEDC_TIMER_0,
            .duty = 0,
            .hpoint = 0,
        };
        ESP_ERROR_CHECK(ledc_channel_config(&ch));
    }
    motors_stop();
}

static void init_laser(void)
{
    gpio_reset_pin(LASER_GPIO);
    gpio_set_direction(LASER_GPIO, GPIO_MODE_OUTPUT);
    gpio_set_level(LASER_GPIO, 1);  /* OFF (active-low) */
}

static void init_servo(void)
{
    ledc_timer_config_t timer = {
        .speed_mode = LEDC_LOW_SPEED_MODE,
        .duty_resolution = LEDC_TIMER_14_BIT,
        .timer_num = LEDC_TIMER_2,
        .freq_hz = 50,
        .clk_cfg = LEDC_AUTO_CLK,
    };
    ledc_timer_config(&timer);
    ledc_channel_config_t ch = {
        .gpio_num = SERVO_GPIO,
        .speed_mode = LEDC_LOW_SPEED_MODE,
        .channel = LEDC_CHANNEL_5,
        .intr_type = LEDC_INTR_DISABLE,
        .timer_sel = LEDC_TIMER_2,
        .duty = 0,
        .hpoint = 0,
    };
    ledc_channel_config(&ch);
    ledc_set_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_5, 1987);  /* ~centre */
    ledc_update_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_5);
}

void motion_init(void)
{
    init_motors();
    init_laser();
    init_servo();
    xTaskCreate(motor_ramp_task, "motor_ramp", 2048, NULL, 2, NULL);
    xTaskCreate(motor_safety_task, "motor_safety", 1536, NULL, 1, NULL);
    ESP_LOGI(TAG, "Motion ready (DRV8833 motors, laser GPIO9, servo centred)");
}

void motion_set_motor(int drive, int turn)
{
    if (drive > 255) drive = 255;
    if (drive < -255) drive = -255;
    if (turn > 255) turn = 255;
    if (turn < -255) turn = -255;
    motor_target_drive = drive;
    motor_target_turn = turn;
    last_motor_cmd_us = esp_timer_get_time();
}

bool motion_toggle_laser(void)
{
    g_laser_on = !g_laser_on;
    gpio_set_level(LASER_GPIO, g_laser_on ? 0 : 1);  /* active-low */
    return g_laser_on;
}

bool motion_laser_on(void) { return g_laser_on; }
int motion_drive(void) { return motor_target_drive; }
int motion_turn(void) { return motor_target_turn; }
