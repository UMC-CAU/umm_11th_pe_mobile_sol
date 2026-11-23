import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/favorite_list_item.dart';
import '../movie_card.dart';
import '../movie_poster.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/movie_states.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel?>();
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('내 즐겨찾기'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child:
                vm == null ||
                    !vm.isCurrent ||
                    auth.status != AuthStatus.signedIn
                ? _memberState(auth)
                : switch (vm.phase) {
                    LoadPhase.idle ||
                    LoadPhase.loading => const MovieLoadingWidget(),
                    LoadPhase.empty => const MovieEmptyWidget(
                      message: '아직 즐겨찾기한 영화가 없어요.',
                    ),
                    LoadPhase.error => MovieErrorWidget(
                      message: vm.errorMessage,
                      onRetry: vm.refresh,
                    ),
                    LoadPhase.ready => _list(vm),
                  },
          ),
        ),
      ),
    );
  }

  Widget _memberState(AuthViewModel auth) {
    if (auth.memberStatus == MemberLoadStatus.error) {
      return MovieErrorWidget(
        message: auth.message,
        onRetry: () => auth.loadMember(force: true),
      );
    }
    return const MovieLoadingWidget();
  }

  Widget _list(FavoritesViewModel vm) {
    final items = vm.items;
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => index == items.length
            ? const TmdbAttribution()
            : _card(context, vm, items[index]),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    FavoritesViewModel vm,
    FavoriteListItem item,
  ) {
    final id = item.favorite.movieId;
    final movie = item.movie;

    Future<void> openMovie() async {
      await context.push('/movies/$id', extra: movie);
      if (context.mounted) await vm.refresh();
    }

    final action = TmdbPoster.imageUrl(movie?.posterPath) != null
        ? null
        : TextButton(
            onPressed: vm.canRetry(id) ? () => vm.retryMovie(id) : null,
            style: TextButton.styleFrom(
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: Text(vm.isRetrying(id) ? '영화 정보 조회 중' : '정보 다시 불러오기'),
          );
    if (movie != null) {
      return MovieCard.compact(
        key: ValueKey(id),
        movie: movie,
        onTap: openMovie,
        action: action,
      );
    }
    return MovieCardRow(
      key: ValueKey(id),
      title: '영화 #$id',
      subtitle: '영화 정보를 불러오지 못했어요.',
      poster: const MoviePosterPlaceholder(),
      onTap: openMovie,
      action: action,
    );
  }
}
