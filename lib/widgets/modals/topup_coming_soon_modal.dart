import 'package:flutter/cupertino.dart';
import 'package:pay_app/l10n/app_localizations.dart';
import 'package:pay_app/theme/colors.dart';

class TopupComingSoonModal extends StatelessWidget {
  const TopupComingSoonModal({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: blackColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: whiteColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    CupertinoIcons.money_dollar_circle,
                    size: 40,
                    color: whiteColor,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  l10n.topupComingSoon,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: whiteColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  l10n.topupComingSoonDescription,
                  style: TextStyle(
                    fontSize: 16,
                    color: whiteColor.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Close button
                CupertinoButton(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.done,
                    style: const TextStyle(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
