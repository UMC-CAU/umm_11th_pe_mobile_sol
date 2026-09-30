import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_colors.dart';
import 'mock_movies.dart';
import 'movie_card.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  String _genre = '전체';
  MovieSort _sort = MovieSort.original;
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    // 필터링 결과의 복사본만 정렬하므로 공통 Mock 목록은 바뀌지 않습니다.
    final movies = List<Movie>.of(filterMovies(_genre, _searchController.text));
    if (_sort != MovieSort.original) {
      movies.sort((a, b) {
        final comparison = _sort == MovieSort.rating
            ? b.rating.compareTo(a.rating)
            : b.year.compareTo(a.year);
        // 평점/연도가 같으면 원래 Mock 목록 순서를 유지합니다.
        return comparison != 0
            ? comparison
            : mockMovies.indexOf(a).compareTo(mockMovies.indexOf(b));
      });
    }
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
      body: SafeArea(top: false, child: Column(children: [
        if (_searching) Padding(
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        MovieGenreFilter(
          selected: _genre,
          onSelected: (genre) => setState(() => _genre = genre),
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
        Expanded(child: movies.isEmpty
          ? const Center(child: Text('조건에 맞는 영화가 없어요.'))
          : LayoutBuilder(builder: (context, constraints) {
              // 휴대폰은 참고 화면처럼 2열, 넓은 화면에서는 카드 폭을 제한합니다.
              final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 600 ? 3 : 2;
              final width = (constraints.maxWidth - 32 - 16 * (columns - 1)) / columns;
              final scaler = MediaQuery.textScalerOf(context);
              final captionHeight = scaler.scale(16) * 1.4 + scaler.scale(14) * 1.5 + 22;
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
            }),
        ),
      ])),
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
              child: Text('영화 정렬', style: Theme.of(context).textTheme.titleLarge),
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
  const MovieGenreFilter({super.key, required this.selected, required this.onSelected});
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
          return Center(child: ChoiceChip(
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
              fontSize: 14, fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ));
        },
      ),
    );
  }
}
