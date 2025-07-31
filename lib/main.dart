import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'kids_game_screen.dart';
import 'adults_game_screen.dart';

// void main() {
//   runApp(const BubbleShotApp());
// }

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const BubbleShotApp());
}

class BubbleShotApp extends StatelessWidget {
  const BubbleShotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubble Shot Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'ComicSans',
            ),
      ),
      home: const HomeScreen(),
      routes: {
        '/kids': (context) => const KidsGameScreen(),
        '/adults': (context) => const AdultsGameScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final double cardWidth = 300;
  final double cardHeight = 120;
  final double cardSpacing = 16;
  final double cardBottomPadding = 60;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              'Bubble Shot Game',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _buildCard(
                          title: 'Bubble Shot Game for Kids',
                          onTap: () => Navigator.pushNamed(context, '/kids'),
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _buildCard(
                          title: 'Bubble Shot Game for Adults',
                          onTap: () => Navigator.pushNamed(context, '/adults'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: cardBottomPadding),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                '© $year Made in India - Bubble Shot Game',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
