import 'package:collection/collection.dart';
import 'package:rimba/models/interaction.dart';
import 'package:rimba/state/interactions/interactions.dart';

List<Interaction> sortByUnreadAndDate(InteractionState state) {
  return List<Interaction>.from(state.interactions)
      .where((interaction) => interaction.name
          .toLowerCase()
          .contains(state.searchQuery.toLowerCase()))
      .sortedByCompare(
          (interaction) => interaction.lastMessageAt, (a, b) => b.compareTo(a))
      .toList();
}
