import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(buttonText1 ?? l10n.ok),
              onPressed: onPressFunction,
            ),
            if (onPressFunction2 != null)
              CupertinoDialogAction(
                child: Text(buttonText2 ?? l10n.cancel),
                onPressed: onPressFunction2,
              ),
          ],
        );
      },
    );
  }
}
