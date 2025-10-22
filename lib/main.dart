import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MPPracticeApp());

class MPPracticeApp extends StatelessWidget {
  const MPPracticeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lecture 7 MP Practice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomeScreen(),
      routes: {
        SubmitPostScreen.route: (_) => const SubmitPostScreen(),
        CurrencyScreen.route: (_) => const CurrencyScreen(),
      },
    );
  }
}

// ======================= HOME: GET + list + load/error =======================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Post>> futurePosts;

  @override
  void initState() {
    super.initState();
    futurePosts = fetchPosts();
  }

  Future<List<Post>> fetchPosts() async {
    final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load posts. Status: ${res.statusCode}');
    }
    final List<dynamic> list = jsonDecode(res.body) as List<dynamic>;
    final posts = list.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
    if (posts.isNotEmpty) {
      // Task 3: print first title
      // ignore: avoid_print
      print('First title: ${posts.first.title}');
    }
    return posts;
  }

  void retry() => setState(() => futurePosts = fetchPosts());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts (JSONPlaceholder)'),
        actions: [
          IconButton(
            tooltip: 'Submit Post (reqres.in)',
            icon: const Icon(Icons.send),
            onPressed: () => Navigator.pushNamed(context, SubmitPostScreen.route),
          ),
          IconButton(
            tooltip: 'Currency (CBU.uz)',
            icon: const Icon(Icons.currency_exchange),
            onPressed: () => Navigator.pushNamed(context, CurrencyScreen.route),
          ),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: futurePosts,
        builder: (context, snap) {
          // Loading (Task 5)
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Error + Retry (Task 6)
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: ${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final posts = snap.data ?? const <Post>[];
          // Show titles (Task 4)
          return ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = posts[i];
              return ListTile(
                title: Text(p.title),
                subtitle: Text('Post #${p.id} • user ${p.userId}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to Details (Tasks 7–8)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailsScreen(post: p)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class Post {
  final int userId;
  final int id;
  final String title;
  final String body;
  Post({required this.userId, required this.id, required this.title, required this.body});
  factory Post.fromJson(Map<String, dynamic> j) =>
      Post(userId: j['userId'] as int, id: j['id'] as int, title: j['title'] as String, body: j['body'] as String);
}

// ======================= DETAILS SCREEN (title + body) =======================
class DetailsScreen extends StatelessWidget {
  final Post post;
  const DetailsScreen({super.key, required this.post});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(post.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(post.body),
        ]),
      ),
    );
  }
}

// ======================= POST screen: reqres.in ==============================
class SubmitPostScreen extends StatefulWidget {
  static const route = '/submit';
  const SubmitPostScreen({super.key});
  @override
  State<SubmitPostScreen> createState() => _SubmitPostScreenState();
}

class _SubmitPostScreenState extends State<SubmitPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _bodyC = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final uri = Uri.parse('https://reqres.in/api/posts');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': _titleC.text, 'body': _bodyC.text}),
      );
      // Print response (Task 9)
      // ignore: avoid_print
      print('POST: ${res.statusCode} ${res.body}');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (mounted) {
          // SnackBar (Task 10)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post submitted successfully.')),
          );
        }
      } else {
        throw Exception('Failed: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _titleC.dispose();
    _bodyC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit a Post (reqres.in)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _titleC,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyC,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a body' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_busy ? 'Submitting…' : 'Submit'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ======================= CBU currency screen ================================
class CurrencyScreen extends StatefulWidget {
  static const route = '/currency';
  const CurrencyScreen({super.key});
  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final _dateC = TextEditingController(); // YYYY-MM-DD
  final _codeC = TextEditingController(); // USD / RUB / ALL or empty
  bool _loading = false;
  String? _error;
  List<CurrencyRate> _rates = [];

  Uri _buildCbuUrl({required String date, required String code}) {
    final up = code.toUpperCase();
    String real;
    if (date.isEmpty && (up.isEmpty || up == 'ALL')) {
      real = 'https://cbu.uz/ru/arkhiv-kursov-valyut/json/';
    } else if (date.isNotEmpty && (up.isEmpty || up == 'ALL')) {
      real = 'https://cbu.uz/ru/arkhiv-kursov-valyut/json/all/$date/';
    } else if (date.isNotEmpty && up.isNotEmpty) {
      real = 'https://cbu.uz/ru/arkhiv-kursov-valyut/json/$up/$date/';
    } else {
      real = 'https://cbu.uz/ru/arkhiv-kursov-valyut/json/';
    }
    // For web, wrap with CORS proxy; for mobile/desktop, direct URL.
    if (kIsWeb) {
      return Uri.parse('https://api.allorigins.win/raw?url=${Uri.encodeComponent(real)}');
    }
    return Uri.parse(real);
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _rates = [];
    });
    try {
      final date = _dateC.text.trim();
      final code = _codeC.text.trim().toUpperCase();
      final uri = _buildCbuUrl(date: date, code: code);
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Failed: ${res.statusCode}');
      }
      final dynamic data = jsonDecode(res.body);
      List list = (data is List) ? data : [data];

      if (date.isEmpty && code.isNotEmpty && code != 'ALL') {
        list = list.where((e) => (e['Ccy'] as String?)?.toUpperCase() == code).toList();
      }

      setState(() {
        _rates = list.map((e) => CurrencyRate.fromJson(e as Map<String, dynamic>)).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _dateC.dispose();
    _codeC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CBU Currency Rates (UZS)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _dateC,
            decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD, empty = today)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeC,
            decoration: const InputDecoration(labelText: 'Currency code (USD, RUB, or ALL)'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _fetch,
              icon: const Icon(Icons.search),
              label: const Text('Fetch Rates'),
            ),
          ),
          const SizedBox(height: 10),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _rates.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = _rates[i];
                return ListTile(
                  title: Text('${r.name} (${r.code})'),
                  subtitle: Text('Rate in UZS: ${r.rate} • Date: ${r.date}'),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class CurrencyRate {
  final String name; // e.g., Uzbek/Russian/English name (whatever is present)
  final String code; // e.g., USD
  final String rate; // e.g., "12650.12"
  final String date; // "YYYY-MM-DD"
  CurrencyRate({required this.name, required this.code, required this.rate, required this.date});
  factory CurrencyRate.fromJson(Map<String, dynamic> j) => CurrencyRate(
        name: (j['CcyNm_UZ'] ?? j['CcyNm_RU'] ?? j['CcyNm_EN'] ?? j['Ccy'] ?? '') as String,
        code: (j['Ccy'] ?? j['ccy'] ?? '') as String,
        rate: (j['Rate'] ?? j['rate'] ?? '').toString(),
        date: (j['Date'] ?? j['date'] ?? '').toString(),
      );
}
