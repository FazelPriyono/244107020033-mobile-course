import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/comment.dart';
import 'repositories/comment_repository.dart';
import 'providers.dart' show dioProvider;

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

final commentListProvider = FutureProvider.family<List<Comment>, int>((ref, postId) async {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.fetchComments(postId);
});
