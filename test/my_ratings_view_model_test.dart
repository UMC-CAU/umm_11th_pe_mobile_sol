import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/session_ratings.dart';
import 'support/week6_fakes.dart';
import 'support/week8_fakes.dart';
void main() {
  test('created rating can be updated and deleted in the current session', () async {
    final auth = testAuth(); final session = SessionRatings(auth); final vm = MyRatingsViewModel(FakeRatingApiService(), session, auth);
    addTearDown(() { vm.dispose(); session.dispose(); auth.dispose(); });
    session.add(testRating(id: 12, comment: '기존 후기'), null, auth.sessionVersion);
    await vm.updateRating(ratingId: 12, score: 4, comment: null); expect(vm.ratings.single.rating.score, 4); expect(vm.ratings.single.rating.comment, isNull);
    await vm.deleteRating(12); expect(vm.ratings, isEmpty);
  });
  test('late update after logout cannot repopulate a later session', () async {
    final auth = testAuth(); final session = SessionRatings(auth); final pending = Completer<void>();
    final service = FakeRatingApiService()..onUpdate = (_, _, _, _) => pending.future;
    final vm = MyRatingsViewModel(service, session, auth); addTearDown(() { vm.dispose(); session.dispose(); auth.dispose(); });
    session.add(testRating(id: 12), null, auth.sessionVersion); final write = vm.updateRating(ratingId: 12, score: 4);
    await auth.logout(); expect(session.ratings, isEmpty); pending.complete(); await expectLater(write, throwsA(isA<RatingWriteException>())); expect(session.ratings, isEmpty);
  });
}
