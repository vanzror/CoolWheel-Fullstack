import 'package:flutter/material.dart';

class LoadingPopup {
  static void show({
    required BuildContext context,
    String message = "Loading...",
    Color textColor = Colors.black,
    Color loaderColor = Colors.blue,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup dengan tap di luar popup
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: TextStyle(color: textColor, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
