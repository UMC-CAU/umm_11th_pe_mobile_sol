import 'package:flutter/material.dart' show Rect;

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genres,
    required this.year,
    required this.minutes,
    required this.rating,
    required this.posterAsset,
    required this.synopsis,
    required this.ratingCount,
    this.tags = const [],
    this.posterCrop,
    this.sourceWidth,
    this.sourceHeight,
  });

  final String id;
  final String title;
  final List<String> genres;
  final int year;
  final int minutes;
  final double rating;
  final String posterAsset;
  final String synopsis;
  final String ratingCount;
  final List<String> tags;
  final Rect? posterCrop;
  final double? sourceWidth;
  final double? sourceHeight;

  String get genre => genres.join(' · ');
  String get metadata => '$year · ${genres.join('/')} · $minutes분';
}

// 홈과 목록은 같은 객체를 사용합니다. 제목/ID/연도/평점이 일치합니다.
const featuredMovie = Movie(
  id: 'starlight', title: '별빛 아래 우리',
  ratingCount: '1,245', tags: ['로맨스', '드라마', '감동적인'],
  synopsis: '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.\n\n'
      '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 되는데…\n\n'
      '별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? 눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 겨울 최고의 로맨스 영화.\n\n'
      '잔잔한 감동과 함께 삶의 의미를 다시 한번 되돌아보게 만드는 수작입니다.',
  genres: ['로맨스', '드라마'], year: 2024, minutes: 124, rating: 4.5,
  posterAsset: 'assets/images/home_starlight_reference.png',
  posterCrop: Rect.fromLTWH(10, 193, 640, 960),
  sourceWidth: 660, sourceHeight: 1534,
);

const mockMovies = <Movie>[
  featuredMovie,
  Movie(
    ratingCount: '842', tags: ['SF', '모험'],
    synopsis: '오랜 탐사 끝에 미지의 행성에 도착한 우주비행사. 고요한 사막 위에 나타난 빛의 신호를 따라가며 우주와 자신에 관한 비밀을 발견합니다.',
    id: 'void', title: '우주의 끝에서', genres: ['SF'],
    year: 2024, minutes: 118, rating: 4.2,
    posterAsset: 'assets/images/movies_reference.png',
    posterCrop: Rect.fromLTWH(364, 322, 248, 370),
    sourceWidth: 654, sourceHeight: 1478,
  ),
  Movie(
    ratingCount: '2,106', tags: ['애니메이션', '따뜻한'],
    synopsis: '길을 잃은 아이와 작은 숲의 정령이 함께 떠나는 여행. 잊힌 기억이 나무마다 반짝이는 숲에서 소중한 인연과 용기를 찾아갑니다.',
    id: 'woods', title: '기억의 숲', genres: ['애니메이션'],
    year: 2023, minutes: 102, rating: 4.9,
    posterAsset: 'assets/images/movies_reference.png',
    posterCrop: Rect.fromLTWH(52, 865, 256, 404),
    sourceWidth: 654, sourceHeight: 1478,
  ),
  Movie(
    ratingCount: '567', tags: ['스릴러', '미스터리'],
    synopsis: '비가 내리는 도시, 사라진 사람의 마지막 흔적을 좇는 형사. 익숙했던 골목이 낯설어지는 밤, 오래 감춰진 진실이 모습을 드러냅니다.',
    id: 'shadows', title: '밤의 그림자', genres: ['스릴러'],
    year: 2024, minutes: 110, rating: 3.8,
    posterAsset: 'assets/images/movies_reference.png',
    posterCrop: Rect.fromLTWH(348, 867, 278, 404),
    sourceWidth: 654, sourceHeight: 1478,
  ),
];

const movieGenres = ['전체', '드라마', 'SF', '애니메이션', '스릴러', '로맨스'];

Movie? findMovieById(String id) {
  for (final movie in mockMovies) {
    if (movie.id == id) return movie;
  }
  return null;
}

List<Movie> filterMovies(String genre, String query) {
  final keyword = query.trim().toLowerCase();
  return mockMovies.where((movie) {
    final matchesGenre = genre == '전체' || movie.genres.contains(genre);
    return matchesGenre && movie.title.toLowerCase().contains(keyword);
  }).toList(growable: false);
}
