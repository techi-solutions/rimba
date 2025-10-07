import 'package:flutter/cupertino.dart';
import 'package:rimba/l10n/app_localizations.dart';
import 'package:rimba/widgets/settings_row.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.notifications,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
        ),
        const SizedBox(height: 10),
        SettingsRow(
          label: AppLocalizations.of(context)!.pushNotifications,
          icon: 'assets/icons/notification_bell.svg',
          trailing: CupertinoSwitch(
            value: true,
            onChanged: (value) {},
          ),
        )
      ],
    );
  }
}
