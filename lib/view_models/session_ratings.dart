import 'package:flutter/foundation.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import 'auth_view_model.dart';
class SessionRatings extends ChangeNotifier {
  SessionRatings(this._auth) : _version = _auth.sessionVersion { _auth.addListener(_onAuthChanged); }
  final AuthViewModel _auth;
  int _version;
  final List<RatingWithMovie> _ratings = [];
  List<RatingWithMovie> get ratings => List.unmodifiable(_ratings);
  void _onAuthChanged() {
    if (_version == _auth.sessionVersion) return;
    _version = _auth.sessionVersion;
    if (_ratings.isNotEmpty) { _ratings.clear(); notifyListeners(); }
  }
  bool _current(int version) => version == _auth.sessionVersion && _auth.status == AuthStatus.signedIn;
  void add(RatingDto rating, TmdbMovieDto? movie, int version) {
    if (!_current(version)) return;
    _ratings.removeWhere((item) => item.rating.ratingId == rating.ratingId);
    _ratings.insert(0, RatingWithMovie(rating: rating, movie: movie)); notifyListeners();
  }
  void update(RatingDto rating, int version) {
    if (!_current(version)) return;
    final index = _ratings.indexWhere((item) => item.rating.ratingId == rating.ratingId);
    if (index < 0) return;
    _ratings[index] = RatingWithMovie(rating: rating, movie: _ratings[index].movie); notifyListeners();
  }
  void remove(int id, int version) {
    if (!_current(version)) return;
    _ratings.removeWhere((item) => item.rating.ratingId == id); notifyListeners();
  }
  @override
  void dispose() { _auth.removeListener(_onAuthChanged); super.dispose(); }
}
