import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/meal_api.dart';
import '../services/recipe_repository.dart';
import '../state/favorites_store.dart';
import '../state/repository_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/recipe_card.dart';
import '../widgets/swipeable_card.dart';
import 'recipe_detail_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  static const _initialBatch = 8;

  static const _refillBatch = 5;

  static const _refillThreshold = 3;

  final List<Recipe> _deck = [];
  final SwipeCardController _cardController = SwipeCardController();

  final ValueNotifier<double> _progress = ValueNotifier(0);

  late RecipeRepository _repository;
  int _index = 0;
  bool _loading = true;
  bool _refilling = false;
  String? _error;
  bool _started = false;

  Recipe? get _current => _index < _deck.length ? _deck[_index] : null;

  Recipe? get _next => _index + 1 < _deck.length ? _deck[_index + 1] : null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _repository = RepositoryScope.of(context);
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final recipes = await _repository.fetchRandomBatch(_initialBatch);
      if (!mounted) return;
      setState(() {
        _deck
          ..clear()
          ..addAll(recipes);
        _index = 0;
        _loading = false;
      });
    } on MealApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  void _reload() {
    _progress.value = 0;
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  Future<void> _refill() async {
    if (_refilling) return;
    _refilling = true;

    try {
      final more = await _repository.fetchRandomBatch(
        _refillBatch,
        exclude: _deck.map((recipe) => recipe.id).toSet(),
      );
      if (!mounted) return;
      setState(() => _deck.addAll(more));
    } on MealApiException catch (error) {
      debugPrint('Découvrir : rechargement impossible — $error');
    } finally {
      _refilling = false;
    }
  }

  void _handleSwiped(SwipeDirection direction) {
    final recipe = _current;
    if (recipe == null) return;

    if (direction == SwipeDirection.right) {
      FavoritesScope.of(context).add(recipe);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1400),
            backgroundColor: AppColors.like,
            content: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('${recipe.name} ajoutée aux favoris')),
              ],
            ),
          ),
        );
    }

    _progress.value = 0;
    setState(() => _index++);

    if (_deck.length - _index <= _refillThreshold) {
      _refill();
    }
  }

  void _openDetail(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RecipeDetailPage(recipe: recipe, heroTag: 'discover-${recipe.id}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(onReload: _reload, busy: _loading),
          Expanded(child: _buildDeck(current)),
          if (current != null)
            _ActionBar(
              onPass: _cardController.swipeLeft,
              onDetail: () => _openDetail(current),
              onFavorite: _cardController.swipeRight,
            ),
        ],
      ),
    );
  }

  Widget _buildDeck(Recipe? current) {
    if (_loading) return const _DeckLoading();
    if (_error != null) return _DeckError(message: _error!, onRetry: _reload);
    if (current == null) return _DeckExhausted(onReload: _reload);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          if (_next case final next?)
            Positioned.fill(
              child: ValueListenableBuilder<double>(
                valueListenable: _progress,
                builder: (context, progress, child) {
                  final t = progress.abs().clamp(0.0, 1.0);
                  return Transform.scale(
                    scale: 0.93 + 0.07 * t,
                    child: Opacity(opacity: 0.75 + 0.25 * t, child: child),
                  );
                },
                child: IgnorePointer(
                  child: RecipeCard(key: ValueKey(next.id), recipe: next),
                ),
              ),
            ),
          Positioned.fill(
            child: SwipeableCard(
              key: ValueKey(current.id),
              controller: _cardController,
              onProgress: (value) => _progress.value = value,
              onSwiped: _handleSwiped,
              onTap: () => _openDetail(current),
              child: RecipeCard(
                recipe: current,
                heroTag: 'discover-${current.id}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onReload, required this.busy});

  final VoidCallback onReload;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Découvrir',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Swipe à droite ce qui te fait envie',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8A7B75)),
                ),
              ],
            ),
          ),
          AppRoundButton(
            icon: Icons.casino_outlined,
            color: AppColors.red,
            size: 46,
            tooltip: 'Tirer de nouvelles recettes',
            onPressed: busy ? null : onReload,
          ),
        ],
      ),
    );
  }
}

class _DeckLoading extends StatelessWidget {
  const _DeckLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.orange),
          SizedBox(height: 20),
          Text(
            'On dresse la table…',
            style: TextStyle(fontSize: 15, color: Color(0xFF8A7B75)),
          ),
        ],
      ),
    );
  }
}

class _DeckError extends StatelessWidget {
  const _DeckError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 50,
                color: AppColors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Service indisponible',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF8A7B75),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            AppButton(
              label: 'Réessayer',
              icon: Icons.refresh,
              variant: AppButtonVariant.solid,
              width: 220,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckExhausted extends StatelessWidget {
  const _DeckExhausted({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.ramen_dining,
                size: 54,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tu as tout vu !',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Retrouve tes coups de cœur dans l\'onglet Favoris, '
              'ou tire une nouvelle série de recettes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: Color(0xFF8A7B75),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            AppButton(
              label: 'Nouvelles recettes',
              icon: Icons.refresh,
              variant: AppButtonVariant.solid,
              width: 220,
              onPressed: onReload,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onPass,
    required this.onDetail,
    required this.onFavorite,
  });

  final VoidCallback onPass;
  final VoidCallback onDetail;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppRoundButton(
            icon: Icons.close,
            color: AppColors.nope,
            tooltip: 'Passer',
            onPressed: onPass,
          ),
          const SizedBox(width: 22),
          AppRoundButton(
            icon: Icons.restaurant_menu,
            color: AppColors.orange,
            size: 50,
            tooltip: 'Voir la recette',
            onPressed: onDetail,
          ),
          const SizedBox(width: 22),
          AppRoundButton(
            icon: Icons.favorite,
            color: AppColors.like,
            tooltip: 'Ajouter aux favoris',
            onPressed: onFavorite,
          ),
        ],
      ),
    );
  }
}
