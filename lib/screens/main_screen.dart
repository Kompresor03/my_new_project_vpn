import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main_screen2.dart'; // Импортируем main_screen2.dart

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/images/main_screen.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.45,
                  left: MediaQuery.of(context).size.width * 0.5 - 175, // Центрируем кнопку
                  child: GestureDetector(
                    onTap: () {
                      // Переход на main_screen2.dart при нажатии на button1.png
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen2()),
                      );
                    },
                    child: Image.asset(
                      'assets/images/button1.png',
                      width: 350,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.36,
                  left: MediaQuery.of(context).size.width * 0.5 - 175, // Центрируем кнопку
                  child: GestureDetector(
                    onTap: () {
                      // Логика для нажатия на button2.png
                    },
                    child: Image.asset(
                      'assets/images/button2.png',
                      width: 350,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.26,
                  left: MediaQuery.of(context).size.width * 0.5 - 175, // Центрируем кнопку
                  child: GestureDetector(
                    onTap: () {
                      // Логика для нажатия на button3.png
                    },
                    child: Image.asset(
                      'assets/images/button3.png',
                      width: 350,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.17,
                  left: MediaQuery.of(context).size.width * 0.5 - 175, // Центрируем кнопку
                  child: GestureDetector(
                    onTap: () {
                      // Переход на main_screen2.dart при нажатии на button4.png
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen2()),
                      );
                    },
                    child: Image.asset(
                      'assets/images/button4.png',
                      width: 350,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Остальные Positioned виджеты
                Positioned(
                  bottom: 20,
                  left: MediaQuery.of(context).size.width * 0.25 - 75,
                  child: GestureDetector(
                    onTap: () async {
                      const url = 'https://spydogvpn.com/terms-of-use';
                      if (await canLaunch(url)) {
                        await launch(url);
                      }
                    },
                    child: Text(
                      'Terms of use',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5F719F),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: MediaQuery.of(context).size.width * 0.56 - 50,
                  child: GestureDetector(
                    onTap: () async {
                      const url = 'https://spydogvpn.com/about-us';
                      if (await canLaunch(url)) {
                        await launch(url);
                      }
                    },
                    child: Text(
                      'About Us',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5F719F),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: MediaQuery.of(context).size.width * 0.25 - 75,
                  child: GestureDetector(
                    onTap: () async {
                      const url = 'https://spydogvpn.com/privacy-policy';
                      if (await canLaunch(url)) {
                        await launch(url);
                      }
                    },
                    child: Text(
                      'Privacy policy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5F719F),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 70,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen2()),
                      );
                    },
                    child: Image.asset(
                      'assets/images/buttoncross.png',
                      fit: BoxFit.none,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
