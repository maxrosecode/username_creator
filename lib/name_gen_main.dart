import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp()); // Entry point: launch MyApp
}

/// Root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Provide the app state to all widgets in the tree
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 105, 212, 255),
          ),
        ),
        home: MyHomePage(), // Main screen of the app
      ),
    );
  }
}

/// Application state, holds current word pair, history, and favorites.
class MyAppState extends ChangeNotifier {
  WordPair current = WordPair.random(); // Current word pair shown
  final List<WordPair> history = []; // Previously shown word pairs
  final List<WordPair> favorites = []; // User-favorited word pairs

  /// Advance to the next random word pair, storing the old one in history.
  void getNext() {
    history.insert(0, current);
    current = WordPair.random();
    notifyListeners(); // Notify UI to rebuild
  }

  /// Toggle favorite status for a given pair (defaults to current).
  void toggleFavorite([WordPair? pair]) {
    final w = pair ?? current;
    if (favorites.contains(w)) {
      favorites.remove(w);
    } else {
      favorites.add(w);
    }
    notifyListeners();
  }
}

/// Home page with navigation rail to switch between pages.
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0; // Tracks the current navigation index

  @override
  Widget build(BuildContext context) {
    Widget page;
    // Select the page widget based on the navigation index
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      case 2:
        page = MixerPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.shuffle),
                      label: Text('Mixer'),
                    ),
                  ],
                ),
              ),
              Expanded(
                // Display the selected page in the remaining space
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Page that generates and displays word pairs, plus history and controls.
class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final history = appState.history;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // History list: shows previously generated pairs
          Expanded(
            child: history.isEmpty
                ? Center(child: Text('No history yet.'))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, i) {
                      final pair = history[i];
                      final isFav = appState.favorites.contains(pair);
                      return ListTile(
                        title: Text(pair.asLowerCase),
                        trailing: IconButton(
                          icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border),
                          onPressed: () => appState.toggleFavorite(pair),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: 20),
          // Big card for current word pair
          BigCard(pair: appState.current),
          SizedBox(height: 10),
          // Control buttons: Like and Next
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: Icon(appState.favorites.contains(appState.current)
                    ? Icons.favorite
                    : Icons.favorite_border),
                label: Text('Like'),
                onPressed: () => appState.toggleFavorite(),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => appState.getNext(),
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Large card widget to display a WordPair prominently.
class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pair});
  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

/// Page to list user-favorited word pairs.
class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(child: Text('No favorites yet.'));
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have ${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}

/// Page to mix first and second halves of seen word pairs.
class MixerPage extends StatefulWidget {
  @override
  State<MixerPage> createState() => _MixerPageState();
}

class _MixerPageState extends State<MixerPage> {
  String? firstHalf;
  String? secondHalf;

  @override
  void initState() {
    super.initState();
    final appState = context.read<MyAppState>();
    firstHalf = appState.current.first;
    secondHalf = appState.current.second;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    // Gather seen word pairs to build dropdown options
    final allPairs = {
      appState.current,
      ...appState.history,
      ...appState.favorites
    };
    final firsts = allPairs.map((w) => w.first).toSet().toList()..sort();
    final seconds = allPairs.map((w) => w.second).toSet().toList()..sort();

    // Combined word from selected halves
    final combo = WordPair(firstHalf!, secondHalf!);
    final isFav = appState.favorites.contains(combo);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Dropdowns to pick first and second halves
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                value: firstHalf,
                items: firsts
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => firstHalf = v),
              ),
              SizedBox(width: 16),
              DropdownButton<String>(
                value: secondHalf,
                items: seconds
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => secondHalf = v),
              ),
            ],
          ),

          SizedBox(height: 24),
          // Display mixed word
          BigCard(pair: combo),

          SizedBox(height: 10),
          // Favorite/unfavorite the mixed combo
          ElevatedButton.icon(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            label: Text(isFav ? 'Unfavorite' : 'Favorite'),
            onPressed: () => appState.toggleFavorite(combo),
          ),
        ],
      ),
    );
  }
}
