import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/tmdb_movie_service.dart';
import '../movie_card.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/movie_page_footer.dart';
import '../widgets/movie_states.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final _controller = TextEditingController();

  Future<void> _submit(String value) async {
    final query = value.trim();
    final vm = context.read<PagedMoviesViewModel>();
    if (query.isEmpty) {
      vm.clear();
      return;
    }
    FocusScope.of(context).unfocus();
    final service = context.read<TmdbMovieService>();
    await vm.loadInitial(
      (page, token) =>
          service.searchMovies(query: query, page: page, cancelToken: token),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagedMoviesViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('영화 검색'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submit,
                    decoration: InputDecoration(
                      hintText: '영화 제목을 입력해 주세요',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: '검색 실행',
                        onPressed: () => _submit(_controller.text),
                        icon: const Icon(Icons.arrow_forward),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: switch (vm.phase) {
                    LoadPhase.idle => const Center(
                      child: Text('검색어를 입력해 주세요.'),
                    ),
                    LoadPhase.loading => const MovieLoadingWidget(),
                    LoadPhase.empty => const MovieEmptyWidget(
                      message: '검색 결과가 없어요.',
                    ),
                    LoadPhase.error => MovieErrorWidget(
                      message: vm.errorMessage,
                      onRetry: vm.refresh,
                    ),
                    LoadPhase.ready => _results(vm),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _results(PagedMoviesViewModel vm) {
    final movies = vm.movies;
    return ListView.separated(
      key: ValueKey(vm.generation),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: movies.length + 2,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == movies.length + 1) return const TmdbAttribution();
        if (index == movies.length) {
          return MoviePageFooter(
            hasMore: vm.hasMore,
            isLoading: vm.isLoadingMore,
            errorMessage: vm.loadMoreError,
            onLoadMore: vm.loadNextPage,
            label: '검색 결과 더 보기',
          );
        }
        final movie = movies[index];
        return MovieCard.compact(
          key: ValueKey(movie.id),
          movie: movie,
          onTap: () => context.push('/movies/${movie.id}', extra: movie),
        );
      },
    );
  }
}
