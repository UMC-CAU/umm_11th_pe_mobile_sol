import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'mock_movies.dart';
import 'movie_card.dart';
import 'fake_movie_service.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key, this.genre = '전체'});

  final String genre;

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  // success: 성공 / empty: 빈 목록 / error: 계속 실패 / failOnce: 첫 요청만 실패
  final movieService = FakeMovieService(mode: FakeMovieMode.failOnce);
  late Future<List<Movie>> _moviesFuture;

  static const _genreKey = 'last_selected_movie_genre';
  final _preferences = SharedPreferencesAsync();
  Future<void> _genreSaveQueue = Future<void>.value();
  bool _genreWasChanged = false;

  String _genre = '전체';
  MovieSort _sort = MovieSort.original;
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _genre = widget.genre;
    _moviesFuture = movieService.fetchMovies();
    unawaited(_restoreGenre());
  }

  @override
  void didUpdateWidget(covariant MoviesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.genre != widget.genre) {
      // 같은 화면에서 주소의 장르만 바뀌어도 선택값을 갱신합니다.
      // 영화 목록 Future는 그대로 재사용합니다.
      _genreWasChanged = true;
      _genre = widget.genre;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _restoreGenre() async {
    // 주소에 특정 장르가 전달되면 해당 장르를 우선 적용합니다.
    if (widget.genre != '전체') return;

    try {
      final savedGenre = await _preferences.getString(_genreKey);
      // 복원 도중 사용자가 고른 장르를 이전 저장값으로 덮어쓰지 않습니다.
      if (!mounted || _genreWasChanged || savedGenre == null) return;
      if (!movieGenres.contains(savedGenre)) return;
      setState(() => _genre = savedGenre);
    } catch (_) {
      // 저장값을 읽지 못해도 현재 장르로 영화 화면을 사용할 수 있습니다.
    }
  }

  void _selectGenre(String genre) {
    _genreWasChanged = true;
    setState(() => _genre = genre);

    // 빠르게 여러 Chip을 눌러도 마지막 선택이 마지막에 저장되게 합니다.
    _genreSaveQueue = _genreSaveQueue.then((_) async {
      try {
        await _preferences.setString(_genreKey, genre);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택한 장르를 저장하지 못했어요.')),
        );
      }
    });
  }

  void _retry() {
    setState(() {
      // 처음 요청 이후에는 재시도 버튼을 누를 때만 새 Future를 만듭니다.
      _moviesFuture = movieService.fetchMovies();
    });
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _searchController.clear();
    });
    if (!_searching) FocusScope.of(context).unfocus();
  }

  Future<void> _openSortSheet() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<MovieSort>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => MovieSortSheet(selected: _sort),
    );
    // 바깥 영역을 누르거나 아래로 내려 닫으면 기존 정렬을 유지합니다.
    if (!mounted || selected == null || selected == _sort) return;
    setState(() => _sort = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: _searching ? '검색 닫기' : '영화 검색',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: '영화 제목을 검색하세요',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            MovieGenreFilter(
              selected: _genre,
              onSelected: _selectGenre,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _openSortSheet,
                  icon: const Icon(Icons.sort),
                  label: Text('정렬: ${_sort.label}'),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Movie>>(
                future: _moviesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const MovieLoadingWidget();
                  }

                  if (snapshot.hasError) {
                    return MovieErrorWidget(onRetry: _retry);
                  }

                  final loadedMovies = snapshot.data ?? <Movie>[];
                  if (loadedMovies.isEmpty) {
                    return const MovieEmptyWidget();
                  }
                  final keyword = _searchController.text.trim().toLowerCase();
                  // 받은 목록에서 필터링한 복사본만 정렬합니다.
                  final movies = loadedMovies.where((movie) {
                    final matchesGenre =
                        _genre == '전체' || movie.genres.contains(_genre);
                    return matchesGenre &&
                        movie.title.toLowerCase().contains(keyword);
                  }).toList();

                  if (_sort != MovieSort.original) {
                    movies.sort((a, b) {
                      final comparison = _sort == MovieSort.rating
                          ? b.rating.compareTo(a.rating)
                          : b.year.compareTo(a.year);
                      return comparison != 0
                          ? comparison
                          : loadedMovies
                                .indexOf(a)
                                .compareTo(loadedMovies.indexOf(b));
                    });
                  }

                  if (movies.isEmpty) {
                    return const MovieEmptyWidget(
                      message: '선택한 장르나 검색어에 맞는 영화가 없어요.',
                    );
                  }
                  return MovieGrid(movies: movies);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 목록 요청을 기다리는 동안 표시합니다.
class MovieLoadingWidget extends StatelessWidget {
  const MovieLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

// 요청 결과 또는 필터 결과에 영화가 없을 때 표시합니다.
class MovieEmptyWidget extends StatelessWidget {
  const MovieEmptyWidget({
    super.key,
    this.message = '표시할 영화가 없어요.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

// 내부 Exception이나 StackTrace 대신 사용자를 위한 안내만 표시합니다.
class MovieErrorWidget extends StatelessWidget {
  const MovieErrorWidget({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              '영화 목록을 불러오지 못했어요.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

// 기존 영화 카드와 Grid 배치를 재사용합니다.
class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        final width =
            (constraints.maxWidth - 32 - 16 * (columns - 1)) / columns;
        final scaler = MediaQuery.textScalerOf(context);
        final captionHeight =
            scaler.scale(16) * 1.4 + scaler.scale(14) * 1.5 + 22;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 24,
            mainAxisExtent: width * 1.5 + captionHeight,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) => MovieCard(
            movie: movies[index],
            onTap: () => context.push('/movies/${movies[index].id}'),
          ),
        );
      },
    );
  }
}

enum MovieSort {
  original('기본순'),
  rating('평점순'),
  newest('최신순');

  const MovieSort(this.label);
  final String label;
}

// 영화 정렬 옵션을 선택하는 하단 패널입니다.
class MovieSortSheet extends StatelessWidget {
  const MovieSortSheet({super.key, required this.selected});

  final MovieSort selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                '영화 정렬',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final sort in MovieSort.values)
              ListTile(
                title: Text(sort.label),
                selected: sort == selected,
                trailing: sort == selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(sort),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class MovieGenreFilter extends StatelessWidget {
  const MovieGenreFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68 + (MediaQuery.textScalerOf(context).scale(14) - 14),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: movieGenres.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = movieGenres[index];
          final isSelected = selected == genre;
          return Center(
            child: ChoiceChip(
              label: Text(genre),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (_) => onSelected(genre),
              selectedColor: AppColors.primary,
              backgroundColor: const Color(0xFFE8E3EC),
              side: BorderSide.none,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}

