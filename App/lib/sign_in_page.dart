import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_page.dart';

const Color kBackgroundColor = Color(0xFF0A0E14);
const Color kAccentBlue = Color(0xFF00A3FF);
const Color kButtonBlue = Color(0xFF007BFF);

final GoogleSignIn _googleSignIn = GoogleSignIn();

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isSigningIn = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isSigningIn = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isSigningIn = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(user.uid);
        await userRef.update({
          "name": user.displayName,
          "email": user.email,
          "last_login": ServerValue.timestamp,
        });

        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => HomePage(user: user),
          ));
        }
      } else {
        setState(() => _isSigningIn = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        alignment: Alignment.topCenter, // Ensures centering for the "portal" look
        children: [
          // 1. Large Circular Glow positioned to frame the logos
          Positioned(
            top: -100, // Moves the circle up to encompass the logo row
            child: Container(
              width: 500, // Large circle as seen in your target image
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kAccentBlue.withOpacity(0.15),
                    kAccentBlue.withOpacity(0.0),
                  ],
                ),
                border: Border.all(
                  color: kAccentBlue.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // 2. Logo Row: Icon and Wordmark Side-by-Side with Blending
                  // Using BlendMode.multiply to remove white backgrounds
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/pawme_logo_icon.png',
                        height: 55,
                        colorBlendMode: BlendMode.multiply, // White becomes transparent
                        color: Colors.white, // Required for multiply on dark bg
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/images/pawme_logo_wordmark.png',
                        height: 40,
                        colorBlendMode: BlendMode.multiply,
                        color: Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // 3. Centered Content (Next Gen Pet Care)
                  const Text(
                    "Next Gen",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    "Pet Care",
                    style: TextStyle(
                      color: kAccentBlue,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      height: 0.9,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    "Connect, monitor, and care for your furry friends with our advanced IoT robot companion.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 4. Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: _isSigningIn
                            ? const Center(child: CircularProgressIndicator(color: kAccentBlue))
                            : ElevatedButton(
                          onPressed: _signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kButtonBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Get Started →", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            backgroundColor: Colors.white.withOpacity(0.05),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("View Demo", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 5. Robot Image Card at the Bottom (robot.jpeg)
                  Container(
                    width: double.infinity,
                    height: 250,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/robot.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                            SizedBox(width: 8),
                            Text(
                              "System Online",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
