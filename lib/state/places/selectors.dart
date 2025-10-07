import 'package:rimba/models/place.dart';
import 'package:rimba/state/interactions/interactions.dart';
import 'package:rimba/state/places/places.dart';

List<Place> Function(PlacesState) selectFilteredPlaces(
    InteractionState interactionsState) {
  return (PlacesState state) {
    final places = state.places
        .where((place) =>
            !interactionsState.interactionsMap.containsKey(place.account))
        .toList();
    return state.searchQuery.isEmpty
        ? List<Place>.from(places)
        : List<Place>.from(places)
            .where((place) => place.name
                .toLowerCase()
                .contains(state.searchQuery.toLowerCase()))
            .toList();
  };
}
