import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_colors.dart';
import 'data/models/tmdb_genre_dto.dart';
import 'movie_card.dart';
import 'view_models/movie_list_view_model.dart';
import 'view_models/movie_request_state.dart';
import 'widgets/movie_states.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  MovieListViewModel? _vm;
  int _presentedFailure = 0;
  bool _dialogScheduled = false;
  bool _dialogOpen = false;
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<MovieListViewModel>();
    if (identical(vm, _vm)) return;
    _vm?.removeListener(_onStateChanged);
    _vm = vm;
    _presentedFailure = 0;
    vm.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _vm?.removeListener(_onStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final vm = _vm;
    if (!mounted ||
        vm == null ||
        vm.isLoading ||
        vm.errorMessage == null ||
        vm.failureVersion <= _presentedFailure ||
        _dialogScheduled ||
        _dialogOpen) {
      return;
    }
    _dialogScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _dialogScheduled = false;
      if (!mounted ||
          !identical(vm, _vm) ||
          vm.isLoading ||
          vm.errorMessage == null ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      _presentedFailure = vm.failureVersion;
      _dialogOpen = true;
      final retry = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('영화 불러오기 실패'),
          content: Text(
            '${vm.errorMessage}${vm.movies.isEmpty ? '' : '\n\n이전에 불러온 영화 목록은 유지했어요.'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('재시도'),
            ),
          ],
        ),
      );
      _dialogOpen = false;
      if (!mounted || !identical(vm, _vm)) return;
      if (retry == true) await vm.retry();
    });
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (!_searching) {
      _searchController.clear();
      context.read<MovieListViewModel>().setQuery('');
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _openGenres() async {
    final vm = context.read<MovieListViewModel>();
    if (!vm.canSelectGenres) return;
    FocusScope.of(context).unfocus();
    final ids = await showModalBottomSheet<List<int>>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          MovieGenreSheet(genres: vm.genres, selected: vm.selectedGenreIds),
    );
    if (!mounted || ids == null) return;
    await vm.selectGenres(ids);
  }

  Future<void> _openSort() async {
    final vm = context.read<MovieListViewModel>();
    final sort = await showModalBottomSheet<MovieSort>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => MovieSortSheet(selected: vm.sort),
    );
    if (!mounted || sort == null) return;
    vm.setSort(sort);
  }

  @override
  Widget build(BuildContext context) => Consumer<MovieListViewModel>(
    builder: (context, vm, child) {
      // Also recheck when returning to this route after another page covered it.
      ModalRoute.of(context);
      _onStateChanged();
      final visible = vm.visibleMovies;
      return Scaffold(
        appBar: AppBar(
          title: const Text('영화'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: _searching ? '검색 닫기' : '영화 검색',
              onPressed: _toggleSearch,
              icon: Icon(_searching ? Icons.close : Icons.search),
            ),
            IconButton(
              tooltip: '장르 여러 개 선택',
              onPressed: vm.canSelectGenres ? _openGenres : null,
              icon: const Icon(Icons.tune),
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
                    onChanged: context.read<MovieListViewModel>().setQuery,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      hintText: '불러온 영화에서 제목 검색',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              MovieGenreFilter(
                genres: vm.genres,
                selected: vm.selectedGenreIds,
                enabled: vm.canSelectGenres,
                onSelected: (ids) =>
                    context.read<MovieListViewModel>().selectGenres(ids),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '영화 ${vm.movies.length}편',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openSort,
                      icon: const Icon(Icons.sort),
                      label: Text('정렬: ${vm.sort.label}'),
                    ),
                  ],
                ),
              ),
              if (vm.preferenceMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(vm.preferenceMessage!),
                ),
              if (vm.status == MovieLoadStatus.error && vm.movies.isNotEmpty)
                Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            vm.showingPreviousGenre
                                ? '새 목록을 불러오지 못해 이전 ${vm.displayedGenreLabel} 목록을 표시해요.'
                                : '업데이트에 실패해 이전 목록을 표시해요.',
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.read<MovieListViewModel>().retry(),
                          child: const Text('재시도'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (vm.isLoading && vm.movies.isNotEmpty)
                const LinearProgressIndicator(minHeight: 2),
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
                    Widget? state;
                    if ((vm.status == MovieLoadStatus.idle || vm.isLoading) &&
                        vm.movies.isEmpty) {
                      state = const MovieLoadingWidget();
                    } else if (vm.status == MovieLoadStatus.error &&
                        vm.movies.isEmpty) {
                      state = MovieErrorWidget(
                        message: vm.errorMessage,
                        onRetry: () =>
                            context.read<MovieListViewModel>().retry(),
                      );
                    } else if (visible.isEmpty) {
                      state = MovieEmptyWidget(
                        message: vm.movies.isEmpty
                            ? '선택한 장르의 영화가 없어요.'
                            : '검색어에 맞는 영화가 없어요.',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () =>
                          context.read<MovieListViewModel>().refresh(),
                      notificationPredicate: (notification) =>
                          !vm.isLoading && notification.depth == 0,
                      child: CustomScrollView(
                        key: ValueKey(
                          'movies-${vm.selectedGenreIds.join('|')}',
                        ),
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          if (state != null)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: state,
                            )
                          else ...[
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                24,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 24,
                                      mainAxisExtent:
                                          width * 1.5 + captionHeight,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final movie = visible[index];
                                  return MovieCard(
                                    key: ValueKey(movie.id),
                                    movie: movie,
                                    genres: vm.genres,
                                    onTap: () => context.push(
                                      '/movies/${movie.id}',
                                      extra: movie,
                                    ),
                                  );
                                }, childCount: visible.length),
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
    },
  );
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
