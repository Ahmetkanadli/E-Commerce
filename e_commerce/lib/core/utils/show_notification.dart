import 'package:flutter/cupertino.dart';

class ShowNotification {
  static void showNotification({
    required String title,
    required String message,
    required BuildContext context,
    required VoidCallback onPressFunction,
    VoidCallback? onPressFunction2,
    String? buttonText1,
    String? buttonText2,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(buttonText1 ?? 'OK'),
              onPressed: onPressFunction,
            ),
            if (onPressFunction2 != null)
              CupertinoDialogAction(
                child: Text(buttonText2 ?? 'Cancel'),
                onPressed: onPressFunction2,
              ),
          ],
        );
      },
    );
  }
}
