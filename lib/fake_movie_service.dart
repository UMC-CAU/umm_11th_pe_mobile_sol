import 'mock_movies.dart';

enum FakeMovieMode {
  success,
  empty,
  error,
  failOnce,
}

class FakeMovieService {
  FakeMovieService({this.mode = FakeMovieMode.failOnce});

  final FakeMovieMode mode;
  int _requestCount = 0;

  Future<List<Movie>> fetchMovies() async {
    final requestNumber = ++_requestCount;
    // 실제 서버 요청처럼 1초 동안 기다립니다.
    await Future<void>.delayed(const Duration(seconds: 1));

    // TODO(5주차 유저별 평점 조회 API): 실제 API 호출로 교체합니다.
    if (mode == FakeMovieMode.error ||
        (mode == FakeMovieMode.failOnce && requestNumber == 1)) {
      throw Exception('테스트용 영화 목록 요청 실패');
    }
    if (mode == FakeMovieMode.empty) {
      return <Movie>[];
    }
    return mockMovies;
  }
}
