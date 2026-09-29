import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  test('Comment fromJson aman terhadap field yang hilang (AI Challenge)', () {
    // Memberikan JSON dengan field name dan email hilang
    final json = {'id': 1, 'postId': 2, 'body': 'This is a comment'};
    final comment = Comment.fromJson(json);

    expect(comment.id, 1);
    expect(comment.postId, 2);
    // name dan email harus bernilai default (empty string) karena null safety di model
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, 'This is a comment');
  });
}
