import 'package:flutter/cupertino.dart';
import 'package:pay_app/theme/colors.dart';

class GroupTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const GroupTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'Timeline',
              0,
              CupertinoIcons.calendar,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Members',
              1,
              CupertinoIcons.person_2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = selectedIndex == index;
    
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: () => onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? whiteColor : textMutedColor,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? whiteColor : textMutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
