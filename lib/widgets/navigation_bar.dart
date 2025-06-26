import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:main/utils/theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const CustomNavigationBar({super.key, 
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabChanged,
      type: BottomNavigationBarType.fixed,
      elevation: 4.0,
      backgroundColor: AppTheme.lightBackgroundGrey,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: AppTheme.mediumGrey,
      selectedFontSize: 14.0,
      unselectedFontSize: 12.0,
      items: const [
        BottomNavigationBarItem(
          icon: const FaIcon(FontAwesomeIcons.house, size: 20),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: const FaIcon(FontAwesomeIcons.circlePlus, size: 20),
          label: "Add",
        ),
        BottomNavigationBarItem(
          icon: const FaIcon(FontAwesomeIcons.pills, size: 20),
          label: "My Meds",
        ),
        BottomNavigationBarItem(
          icon: const FaIcon(FontAwesomeIcons.commentMedical, size: 20),
          label: "Zira AI",
        ),
      ],
    );
  }
}
