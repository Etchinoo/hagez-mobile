import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/models/business.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import 'widgets/business_card.dart';
import 'widgets/category_chip.dart';

enum _LoadState { loading, loaded, error }

/// Route: '/home' — discovery/landing screen shown after login: greeting +
/// tappable search bar, horizontal category chip row, and two
/// horizontally-scrollable "featured"/"nearby" business sections.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Hard-referencing Arabic per the current pass — a real language
  // preference wire-up (reading the user's languagePref / a locale
  // provider) is out of scope here, see AGENT notes.
  final _strings = AppStrings.ar;

  _LoadState _state = _LoadState.loading;
  List<Business> _featured = const [];
  List<Business> _nearby = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _LoadState.loading);
    try {
      // The /search/businesses list endpoint has no dedicated "featured"
      // filter today, so this does a single fetch and splits the results
      // roughly in half between "featured" and "nearby" — good enough for
      // a first pass. A follow-up could fetch twice with different params
      // (e.g. add min_rating=4 for the featured query) once product wants
      // the two sections to actually mean different things.
      final response = await ApiClient.instance.dio.get(
        '/search/businesses',
        queryParameters: {'limit': '10'},
      );
      final raw = response.data as Map<String, dynamic>;
      final list = ((raw['businesses'] as List?) ?? const [])
          .map((e) => Business.fromListJson(e as Map<String, dynamic>))
          .toList();

      final splitAt = (list.length / 2).ceil();
      if (!mounted) return;
      setState(() {
        _featured = list.sublist(0, splitAt);
        _nearby = list.sublist(splitAt);
        _state = _LoadState.loaded;
      });
    } on DioException catch (e) {
      if (e.error is SessionExpiredException) {
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() => _state = _LoadState.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _LoadState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.teal,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _buildHeader(context),
              const SizedBox(height: 18),
              _buildCategoryRow(context),
              const SizedBox(height: 24),
              _buildSection(title: _strings.home.featuredTitle, businesses: _featured),
              const SizedBox(height: 24),
              _buildSection(title: _strings.home.nearbyTitle, businesses: _nearby),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _strings.home.greeting,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy),
          ),
          const SizedBox(height: 12),
          // Non-editable, tappable search-bar-shaped button — the real
          // search input lives on the /search screen.
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/search'),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _strings.home.searchPlaceholder,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context) {
    final categories = _strings.home.categories.entries.toList();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final entry = categories[index];
          return CategoryChip(
            categoryKey: entry.key,
            label: entry.value,
            // FOLLOW-UP: there's no go_router `extra` wiring yet to
            // pre-fill /search's category filter from here, so a category
            // tap just opens plain search for now. Once /search reads a
            // category filter from `extra`, pass entry.key through.
            onTap: () => context.push('/search'),
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required List<Business> businesses}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(height: 212, child: _buildSectionBody(businesses)),
      ],
    );
  }

  Widget _buildSectionBody(List<Business> businesses) {
    if (_state == _LoadState.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    }

    if (_state == _LoadState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_strings.errors.generic, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: Text(_strings.common.retry)),
          ],
        ),
      );
    }

    if (businesses.isEmpty) {
      return Center(
        child: Text(_strings.home.noResults, style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: businesses.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) => BusinessCard(business: businesses[index]),
    );
  }
}
