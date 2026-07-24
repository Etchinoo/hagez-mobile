import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/models/business.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../home/widgets/business_card.dart';

/// Route: '/search' — search bar + category/district/rating filters + results.
///
/// KNOWN GAP: GET /search/businesses has no free-text `q` param (only
/// category/district/date/party_size/min_rating/station_type/
/// has_group_rooms/lat/lng/page/limit). The text field below therefore
/// filters CLIENT-SIDE on name_ar/name_en against whatever page of results
/// the server already returned for the active category/district/rating —
/// it does not search the full catalogue. A real search would need a
/// server-side `q` param; flagging this as a backend follow-up rather than
/// inventing a capability that doesn't exist.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Order mirrors AppStrings.ar.home.categories (5 Phase 1+2 categories;
  // 'medical' has no UI convention yet, excluded per project convention).
  static const _categoryOrder = ['restaurant', 'salon', 'court', 'gaming_cafe', 'car_wash'];

  // Hardcoded starting set of common Cairo districts, matching the old
  // app's i18n districts section. district_filter is a fixed chip list
  // rather than free text since we don't have a districts endpoint.
  static const _districts = ['القاهرة الجديدة', 'المعادي', 'الزمالك', 'الشيخ زايد'];

  final _searchController = TextEditingController();
  Timer? _debounce;

  // The API only accepts ONE category value per request (query schema is
  // singular), so this is single-select even though chips could visually
  // suggest multi-select. Same choice applied to district for consistency
  // with how a single GET query param behaves.
  String? _selectedCategory;
  String? _selectedDistrict;
  int? _minRating;

  List<Business> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _fetchResults();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() => setState(() {});

  bool get _hasActiveFilters => _selectedCategory != null || _selectedDistrict != null || _minRating != null;

  /// Client-side name filter — see the class doc for why this can't be a
  /// server-side `q` param.
  List<Business> get _visibleResults {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _results;
    return _results.where((b) {
      final nameAr = b.nameAr.toLowerCase();
      final nameEn = (b.nameEn ?? '').toLowerCase();
      return nameAr.contains(query) || nameEn.contains(query);
    }).toList();
  }

  void _scheduleRefetch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetchResults);
  }

  Future<void> _fetchResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiClient.instance.dio.get('/search/businesses', queryParameters: {
        if (_selectedCategory != null) 'category': _selectedCategory,
        if (_selectedDistrict != null) 'district': _selectedDistrict,
        if (_minRating != null) 'min_rating': _minRating,
        'page': 1,
        'limit': 30,
      });
      final businesses = _parseResults(response.data);
      if (!mounted) return;
      setState(() {
        _results = businesses;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (e.error is SessionExpiredException) {
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppStrings.ar.errors.network;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppStrings.ar.errors.generic;
      });
    }
  }

  /// Defensive parsing: the exact response envelope for GET
  /// /search/businesses wasn't available to verify while building this
  /// screen, so this accepts either a bare list or a map with the payload
  /// under 'data' / 'businesses' / 'results'.
  List<Business> _parseResults(dynamic data) {
    List<dynamic> rawList = const [];
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      final candidate = data['data'] ?? data['businesses'] ?? data['results'];
      if (candidate is List) rawList = candidate;
    }
    return rawList.whereType<Map<String, dynamic>>().map(Business.fromListJson).toList();
  }

  void _toggleCategory(String? category) {
    setState(() => _selectedCategory = _selectedCategory == category ? null : category);
    _scheduleRefetch();
  }

  void _toggleDistrict(String? district) {
    setState(() => _selectedDistrict = _selectedDistrict == district ? null : district);
    _scheduleRefetch();
  }

  void _toggleRating(int rating) {
    setState(() => _minRating = _minRating == rating ? null : rating);
    _scheduleRefetch();
  }

  void _clearFilters() {
    _debounce?.cancel();
    setState(() {
      _selectedCategory = null;
      _selectedDistrict = null;
      _minRating = null;
      _searchController.clear();
    });
    _fetchResults();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ar;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(strings),
            _buildFiltersSection(strings),
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildResultsArea(strings)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: strings.home.searchPlaceholder,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _searchController.clear,
                      ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            strings.home.categoryLabel,
            trailing: _hasActiveFilters
                ? TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off, size: 16),
                    label: Text(strings.home.clearFilters, style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  )
                : null,
          ),
          _buildCategoryChips(strings),
          const SizedBox(height: 10),
          _sectionHeader(strings.home.districtLabel),
          _buildDistrictChips(strings),
          const SizedBox(height: 10),
          _sectionHeader(strings.home.ratingLabel),
          _buildRatingSelector(),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildCategoryChips(AppStrings strings) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categoryOrder.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _chip(
              label: strings.home.allLabel,
              selected: _selectedCategory == null,
              color: AppColors.navy,
              onTap: () => _toggleCategory(null),
            );
          }
          final key = _categoryOrder[index - 1];
          return _chip(
            label: strings.home.categories[key] ?? key,
            selected: _selectedCategory == key,
            color: AppColors.forCategory(key),
            onTap: () => _toggleCategory(key),
          );
        },
      ),
    );
  }

  Widget _buildDistrictChips(AppStrings strings) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _districts.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _chip(
              label: strings.home.allLabel,
              selected: _selectedDistrict == null,
              color: AppColors.teal,
              onTap: () => _toggleDistrict(null),
            );
          }
          final district = _districts[index - 1];
          return _chip(
            label: district,
            selected: _selectedDistrict == district,
            color: AppColors.teal,
            onTap: () => _toggleDistrict(district),
          );
        },
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 1; i <= 5; i++) ...[
            GestureDetector(
              onTap: () => _toggleRating(i),
              child: Icon(
                _minRating != null && i <= _minRating! ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.warning,
                size: 26,
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (_minRating != null)
            Text(
              '$_minRating+',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required bool selected, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.navy,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsArea(AppStrings strings) {
    if (_isLoading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _fetchResults, child: Text(strings.common.retry)),
            ],
          ),
        ),
      );
    }

    final visible = _visibleResults;
    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                strings.home.noResults,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.navy),
              ),
              const SizedBox(height: 4),
              Text(
                strings.home.tryAdjustingFilters,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (_hasActiveFilters || _searchController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: _clearFilters, child: Text(strings.home.clearFilters)),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchResults,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final business in visible) BusinessCard(business: business)],
        ),
      ),
    );
  }
}
