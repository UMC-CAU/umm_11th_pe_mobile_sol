/// Local dialog result; the future rating API can use these same fields.
class MovieRatingDraft {
  const MovieRatingDraft({required this.movieId, required this.score});
  final int movieId;
  final double score;
}
