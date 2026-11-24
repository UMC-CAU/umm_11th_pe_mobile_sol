import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_colors.dart';
import 'data/models/tmdb_genre_dto.dart';
import 'movie_card.dart';
import 'view_models/load_phase.dart';
import 'view_models/movie_list_view_model.dart';
import 'widgets/movie_page_footer.dart';
import 'widgets/movie_states.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});

  Future<void> _openGenres(BuildContext context, MovieListViewModel vm) async {
    final ids = await showModalBottomSheet<List<int>>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          MovieGenreSheet(genres: vm.genres, selected: vm.selectedGenreIds),
    );
    if (!context.mounted || ids == null) return;
    await vm.selectGenres(ids);
  }

  Future<void> _openSort(BuildContext context, MovieListViewModel vm) async {
    final sort = await showModalBottomSheet<MovieSort>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => MovieSortSheet(selected: vm.sort),
    );
    if (!context.mounted || sort == null) return;
    vm.setSort(sort);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MovieListViewModel>();
    final movies = vm.visibleMovies;
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: '장르 여러 개 선택',
            onPressed: vm.canSelectGenres
                ? () => _openGenres(context, vm)
                : null,
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: '영화 검색',
            onPressed: () => context.push('/movies/search'),
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MovieGenreFilter(
              genres: vm.genres,
              selected: vm.selectedGenreIds,
              enabled: vm.canSelectGenres,
              onSelected: vm.selectGenres,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '영화 ${movies.length}편',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openSort(context, vm),
                    icon: const Icon(Icons.sort),
                    label: Text('정렬: ${vm.sort.label}'),
                  ),
                ],
              ),
            ),
            if (vm.preferenceMessage case final message?)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(message),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 600
                      ? 3
                      : 2;
                  final width =
                      (constraints.maxWidth - 32 - 16 * (columns - 1)) /
                      columns;
                  final textScaler = MediaQuery.textScalerOf(context);
                  final captionHeight =
                      textScaler.scale(16) * 1.4 +
                      textScaler.scale(14) * 1.5 +
                      24;
                  final state = switch (vm.phase) {
                    LoadPhase.idle ||
                    LoadPhase.loading => const MovieLoadingWidget(),
                    LoadPhase.error => MovieErrorWidget(
                      message: vm.errorMessage,
                      onRetry: vm.refresh,
                    ),
                    LoadPhase.empty => const MovieEmptyWidget(
                      message: '선택한 장르의 영화가 없어요.',
                    ),
                    LoadPhase.ready => null,
                  };

                  return RefreshIndicator(
                    onRefresh: vm.refresh,
                    notificationPredicate: (notification) =>
                        vm.phase != LoadPhase.loading &&
                        notification.depth == 0,
                    child: CustomScrollView(
                      key: ValueKey(vm.generation),
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (state != null)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: state,
                          )
                        else ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 24,
                                    mainAxisExtent: width * 1.5 + captionHeight,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final movie = movies[index];
                                return MovieCard(
                                  key: ValueKey(movie.id),
                                  movie: movie,
                                  genres: vm.genres,
                                  onTap: () => context.push(
                                    '/movies/${movie.id}',
                                    extra: movie,
                                  ),
                                );
                              }, childCount: movies.length),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: MoviePageFooter(
                              hasMore: vm.hasMore,
                              isLoading: vm.isLoadingMore,
                              errorMessage: vm.loadMoreError,
                              onLoadMore: vm.loadNextPage,
                            ),
                          ),
                          const SliverToBoxAdapter(child: TmdbAttribution()),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MovieGenreFilter extends StatelessWidget {
  const MovieGenreFilter({
    super.key,
    required this.genres,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });
  final List<TmdbGenreDto> genres;
  final List<int> selected;
  final bool enabled;
  final ValueChanged<List<int>> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 68 + (MediaQuery.textScalerOf(context).scale(14) - 14),
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: genres.length + 1,
      separatorBuilder: (_, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final genre = index == 0 ? null : genres[index - 1];
        final isSelected = genre == null
            ? selected.isEmpty
            : selected.contains(genre.id);
        return Center(
          child: ChoiceChip(
            label: Text(genre?.name ?? '전체'),
            selected: isSelected,
            showCheckmark: false,
            onSelected: enabled
                ? (_) => onSelected(
                    genre == null || (selected.length == 1 && isSelected)
                        ? []
                        : [genre.id],
                  )
                : null,
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

class MovieGenreSheet extends StatefulWidget {
  const MovieGenreSheet({
    super.key,
    required this.genres,
    required this.selected,
  });
  final List<TmdbGenreDto> genres;
  final List<int> selected;

  @override
  State<MovieGenreSheet> createState() => _MovieGenreSheetState();
}

class _MovieGenreSheetState extends State<MovieGenreSheet> {
  late final Set<int> _draft = widget.selected.toSet();

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: 0.7,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('어떤 장르를 볼까요?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('여러 개를 선택하면 그중 하나에 해당하는 영화를 보여드려요.'),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('전체'),
                    selected: _draft.isEmpty,
                    onSelected: (_) => setState(_draft.clear),
                  ),
                  for (final genre in widget.genres)
                    FilterChip(
                      label: Text(genre.name),
                      selected: _draft.contains(genre.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _draft.add(genre.id);
                        } else {
                          _draft.remove(genre.id);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_draft.toList()..sort()),
            child: const Text('확인'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    ),
  );
}

class MovieSortSheet extends StatelessWidget {
  const MovieSortSheet({super.key, required this.selected});
  final MovieSort selected;

  @override
  Widget build(BuildContext context) => SafeArea(
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
