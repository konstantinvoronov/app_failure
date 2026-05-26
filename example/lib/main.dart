import 'dart:async';
import 'dart:developer';

import 'package:app_failure/app_failure.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AppFailureDemoApp());
}

final class AppFailureDemoApp extends StatelessWidget {
  const AppFailureDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_failure demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: SearchScreen(
        repository: PostSearchRepositoryImpl(api: FakePostSearchApi()),
      ),
    );
  }
}

/// Public interface.
///
/// The UI does not know whether the repository uses HTTP, cache, Firebase,
/// local database, or a fake API.
abstract interface class PostSearchRepository {
  Future<AppResult<List<Post>>> searchPosts(String query);
}

final class PostSearchRepositoryImpl implements PostSearchRepository {
  final FakePostSearchApi api;

  const PostSearchRepositoryImpl({required this.api});

  @override
  Future<AppResult<List<Post>>> searchPosts(String query) async {
    try {
      if (query.isEmpty) {
        return AppResult.failure(
          ValidationFailure('Enter a search query.'),
        );
      }

      /// Local early-exit pattern.
      ///
      /// Inside one function, we may throw a failure locally to keep the happy
      /// path linear, but we catch it inside the same function and return
      /// AppResult again.
      final posts = (await api.searchPosts(query,)
        ).fold((posts) => posts, (failure) => throw failure);

      return AppResult.success(posts);
    } catch (e, st) {
      return AppResult.failure(
        RepositoryFailure(
          error: e,
          stackTrace: st,
          logMessage: 'Post search repository failed',
          uiMessage: 'Could not load posts.',
        ),
      );
    }
  }
}

/// Fake remote API.
///
/// This keeps the example runnable without Dio, API keys, or internet.
/// In a real app, this class would use Dio, http, Firebase, gRPC, etc.
final class FakePostSearchApi {
  Future<AppResult<List<Post>>> searchPosts(String query) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));

      if (query == 'timeout') {
        final httpFailure = HttpFailure(
          logMessage: 'Fake request timed out',
          failureKind: HttpFailureKind.connectionTimeout,
          request: HttpFailureRequestModel(
            method: 'GET',
            uri: Uri.dataFromString('https://example.com/posts?q=timeout'),
          ),
          response: null,
          stackTrace: StackTrace.current,
        );

        return AppResult.failure(
          ApiFailure(
            logMessage: 'Post search API request failed',
            cause: httpFailure,
            stackTrace: StackTrace.current,
          ),
        );
      }

      if (query == 'bad-response') {
        final httpFailure = HttpFailure(
          logMessage: 'Fake API returned unexpected response',
          failureKind: HttpFailureKind.badResponse,
          request: HttpFailureRequestModel(
            method: 'GET',
            uri: Uri.dataFromString('https://example.com/posts?q=timeout'),
          ),
          response: const HttpFailureResponseModel(
            statusCode: 500,
            statusMessage: 'Internal Server Error',
            body: 'Expected List<Map<String, dynamic>>, got String',
          ),
          debugDescription: 'Expected List<Map<String, dynamic>>, got String',
          stackTrace: StackTrace.current,
        );

        return AppResult.failure(
          ApiFailure(
            logMessage: 'Post search API returned invalid response',
            cause: httpFailure,
            stackTrace: StackTrace.current,
          ),
        );
      }

      final posts = _fakePosts
          .where(
            (post) =>
        post.title.toLowerCase().contains(query.toLowerCase()) ||
            post.body.toLowerCase().contains(query.toLowerCase()),
      )
          .toList();

      return AppResult.success(posts);
    } catch (e, st) {
      return AppResult.failure(
        ApiFailure(
          error: e,
          stackTrace: st,
          logMessage: 'Post search API processing failed',
        ),
      );
    }
  }
}

final class SearchScreen extends StatefulWidget {
  final PostSearchRepository repository;

  const SearchScreen({required this.repository, super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

final class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController(
    text: 'flutter',
  );

  bool loading = false;
  List<Post> posts = const [];
  AppFailure? failure;

  Future<void> search() async {
    setState(() {
      loading = true;
      failure = null;
    });

    try {
      final result = await widget.repository.searchPosts(controller.text);

      result.fold(
        (posts) {
          setState(() {
            this.posts = posts;
            loading = false;
          });
        },
        (failure) {
          /// UI/controller consumes the failure.
          ///
          /// This is the place where we log the entire chain once.
          log('$failure');

          setState(() {
            this.failure = failure;
            loading = false;
          });
        },
      );
    } catch (e, st) {
      /// Safety net for unexpected UI/controller failures.
      final failure = AppFailure.controllerFailure(
        cause: e,
        stackTrace: st,
        logMessage: 'Search screen failed',
        uiMessage: 'Search failed.',
      );

      log('$failure');

      setState(() {
        this.failure = failure;
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final failure = this.failure;

    return Scaffold(
      appBar: AppBar(title: const Text('app_failure remote search demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Search posts',
                helperText:
                    'Try: flutter, dart, timeout, bad-response, or empty',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => search(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: loading ? null : search,
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            if (loading) const LinearProgressIndicator(),
            if (failure != null) ...[
              UiFailureView(failure: failure),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: posts.isEmpty
                  ? const Center(child: Text('No posts found.'))
                  : ListView.separated(
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final post = posts[index];

                        return ListTile(
                          title: Text(post.title),
                          subtitle: Text(post.body),
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

/// Simple UI-level failure handling.
///
/// In a real app, some failures may show snackbars, some may render inline
/// widgets, some may block a feature, and some may open a report dialog.
final class UiFailureView extends StatelessWidget {
  final AppFailure failure;

  const UiFailureView({required this.failure, super.key});

  @override
  Widget build(BuildContext context) {
    if (failure.fatalLevel == FatalLevel.silent) {
      return const SizedBox.shrink();
    }

    final title = switch (failure) {
      ValidationFailure() => 'Validation failure',
      HttpFailure() => 'HTTP failure',
      ApiFailure() => 'API failure',
      RepositoryFailure() => 'Repository failure',
      ControllerFailure() => 'Controller failure',
      _ => 'Unknown failure',
    };

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(failure.uiMessage ?? 'Something went wrong.'),
                    const SizedBox(height: 8),
                    Text(
                      'Open logs to see the full AppFailure chain.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class Post {
  final int id;
  final String title;
  final String body;

  const Post({required this.id, required this.title, required this.body});
}

const List<Post> _fakePosts = [
  Post(
    id: 1,
    title: 'Flutter state handling',
    body: 'A post about explicit UI state and predictable async flows.',
  ),
  Post(
    id: 2,
    title: 'Dart Result patterns',
    body: 'A post about returning success and failure as data.',
  ),
  Post(
    id: 3,
    title: 'Remote search',
    body: 'A post about API calls, validation, and failure mapping.',
  ),
  Post(
    id: 4,
    title: 'Failure chains',
    body: 'A post about preserving root cause and application context.',
  ),
];
