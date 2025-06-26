import 'package:flutter/material.dart';

/// A reusable custom button
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.color = Colors.blue, // Default color
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}

/// A reusable custom card
class CustomCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double elevation;

  const CustomCard({
    Key? key,
    required this.child,
    this.color = Colors.white,
    this.elevation = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}

/// A reusable custom text widget
class CustomText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign align;

  const CustomText({
    Key? key,
    required this.text,
    this.style,
    this.align = TextAlign.left,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? const TextStyle(fontSize: 16, color: Colors.black),
      textAlign: align,
    );
  }
}