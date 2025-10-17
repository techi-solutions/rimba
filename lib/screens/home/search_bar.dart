import 'package:flutter/cupertino.dart';
import 'package:pay_app/widgets/search_bar.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSearch;
  final Color? backgroundColor;

  final bool isFocused;
  const SearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSearch,
    this.isFocused = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final double searchBarHeight = (screenHeight * 0.08).clamp(50.0, 64.0);

    return Container(
      height: searchBarHeight,
      decoration: BoxDecoration(
        color: backgroundColor ?? CupertinoColors.systemBackground,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: CustomSearchBar(
        controller: controller,
        focusNode: focusNode,
        placeholder: 'Search for groups',
        onChanged: onSearch,
        isFocused: isFocused,
      ),
    );
  }
}
