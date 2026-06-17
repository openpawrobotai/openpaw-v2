idf_component_register(
    SRCS "app_main.c"
    INCLUDE_DIRS "."
    REQUIRES net ota ble camera motion sensors nvs_flash
)

# Board name compiled in for logging / runtime guard
target_compile_definitions(${COMPONENT_LIB} PRIVATE
    CONFIG_OPENPAW_BOARD_NAME="$ENV{OPENPAW_BOARD}"
)
