import 'package:flutter/material.dart';
import 'main_screen2.dart'; // Импортируйте ваш main_screen2.dart
import 'main_screen.dart'; // Импортируйте ваш main_screen.dart

class LanguageScreen extends StatefulWidget {
  @override
  _LanguageScreenState createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  bool isDarkTheme = false;

  // Состояние выбранного языка
  String? selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkTheme ? Color(0xFF101B36) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Общий отступ
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхняя панель
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Кнопка назад
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen2()),
                      );
                    },
                    child: Image.asset(
                      isDarkTheme
                          ? 'assets/images/arrowleft1.png'
                          : 'assets/images/arrowleft2.png',
                      width: 24,
                      height: 24,
                      semanticLabel: 'Back',
                    ),
                  ),
                  // Текст "Language" или "Язык" отцентрирован
                  Expanded(
                    child: Center(
                      child: Text(
                        selectedLanguage == 'Russian' ? 'Язык' : 'Language',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600, // SemiBold
                          fontSize: 16,
                          color: isDarkTheme ? Colors.white : Color(0xFF101B36),
                        ),
                      ),
                    ),
                  ),
                  // Вложенный Row для king.png и кнопки переключения темы
                  Row(
                    children: [
                      // Кнопка king.png
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => MainScreen()),
                          );
                        },
                        child: Image.asset(
                          'assets/images/king.png',
                          width: 24,
                          height: 24,
                          semanticLabel: 'King',
                        ),
                      ),
                      SizedBox(width: 15), // Отступ 15px между king.png и кнопкой темы
                      // Кнопка переключения темы
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isDarkTheme = !isDarkTheme;
                          });
                        },
                        child: Image.asset(
                          isDarkTheme ? 'assets/images/moon.png' : 'assets/images/sun.png',
                          width: 24,
                          height: 24,
                          semanticLabel: 'Toggle Theme',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 30),
              // Блок "English"
              buildLanguageBlock(
                iconPath: 'assets/images/english.png',
                languageText: 'English',
                isSelected: selectedLanguage == 'English',
                onTap: () {
                  setState(() {
                    selectedLanguage = 'English';
                  });
                },
              ),
              SizedBox(height: 15),
              // Блок "Russian"
              buildLanguageBlock(
                iconPath: 'assets/images/russian.png',
                languageText: 'Russian',
                isSelected: selectedLanguage == 'Russian',
                onTap: () {
                  setState(() {
                    selectedLanguage = 'Russian';
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Функция для создания блока языка
  Widget buildLanguageBlock({
    required String iconPath,
    required String languageText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // Обработка нажатия на весь блок
      child: Container(
        width: 370, // Изменено на 310 согласно первоначальным требованиям
        height: 55, // Изменено на 45 согласно первоначальным требованиям
        decoration: BoxDecoration(
          color: isDarkTheme ? Color(0xFF0C1630) : Color(0xFFECF3FB),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            SizedBox(width: 15),
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
            ),
            SizedBox(width: 15),
            Text(
              languageText,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                color: isDarkTheme ? Colors.white : Color(0xFF101B36),
              ),
            ),
            Spacer(),
            // Чекбокс или галочка
            isSelected
                ? Image.asset(
              isDarkTheme ? 'assets/images/galka.png' : 'assets/images/galka1.png',
              width: 24,
              height: 24,
              semanticLabel: 'Selected',
            )
                : Image.asset(
              isDarkTheme ? 'assets/images/chekbox.png' : 'assets/images/chekbox1.png',
              width: 24,
              height: 24,
              semanticLabel: 'Not Selected',
            ),
            SizedBox(width: 15),
          ],
        ),
      ),
    );
  }
}
