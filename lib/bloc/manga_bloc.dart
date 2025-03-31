import 'dart:async';
import 'package:project_btl/repositories/history_repository.dart';
import 'package:project_btl/repositories/manga_repository.dart';

import '../model/manga.dart';

enum MangaEvent { fetchHotMangas, fetchMangas, loadMore, refresh }

class MangaState {
  final bool isLoading;
  final List<Manga> hotMangas;
  final List<Manga> mangas;
  final int currentPage;
  final bool hasMore;
  final String? error;
  final int totalPages;

  MangaState({
    this.isLoading = false,
    this.hotMangas = const [],
    this.mangas = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.error,
    this.totalPages = 1,
  });

  MangaState copyWith({
    bool? isLoading,
    List<Manga>? hotMangas,
    List<Manga>? mangas,
    int? currentPage,
    bool? hasMore,
    String? error,
    int? totalPages,
  }) {
    return MangaState(
      isLoading: isLoading ?? this.isLoading,
      hotMangas: hotMangas ?? this.hotMangas,
      mangas: mangas ?? this.mangas,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class MangaBloc {
  final MangaRepository _mangaRepository = MangaRepository();
  final HistoryRepository _historyRepository = HistoryRepository();

  // State management
  final _stateController = StreamController<MangaState>.broadcast();
  Stream<MangaState> get state => _stateController.stream;
  MangaState _state = MangaState();

  // Event controller
  final _eventController = StreamController<MangaEvent>();
  StreamSink<MangaEvent> get event => _eventController.sink;

  // Constants
  static const int _itemsPerPage = 10;

  MangaBloc() {
    _eventController.stream.listen(_mapEventToState);
    _init();
  }

  void _init() async {
    event.add(MangaEvent.fetchHotMangas);
    event.add(MangaEvent.fetchMangas);
  }

  void _mapEventToState(MangaEvent event) async {
    switch (event) {
      case MangaEvent.fetchHotMangas:
        await _fetchHotMangas();
        break;
      case MangaEvent.fetchMangas:
        await _fetchMangas();
        break;
      case MangaEvent.loadMore:
        await _loadMoreMangas();
        break;
      case MangaEvent.refresh:
        await _refreshData();
        break;
    }
  }

  Future<void> _fetchHotMangas() async {
    _state = _state.copyWith(isLoading: true);
    _stateController.add(_state);

    try {
      final hotMangas = await _mangaRepository.getHotMangas();
      _state =
          _state.copyWith(isLoading: false, hotMangas: hotMangas, error: null);
    } catch (e) {
      _state = _state.copyWith(
          isLoading: false, error: 'Failed to fetch hot mangas: $e');
    }

    _stateController.add(_state);
  }

  Future<void> _fetchMangas() async {
    _state = _state.copyWith(isLoading: true);
    _stateController.add(_state);

    try {
      final result =
          await _mangaRepository.getMangas(page: 1, limit: _itemsPerPage);

      final mangas = result['mangas'] as List<Manga>;
      final hasMore = result['hasMore'] as bool;
      final totalPages = result['totalPages'] as int;

      _state = _state.copyWith(
          isLoading: false,
          mangas: mangas,
          currentPage: 1,
          hasMore: hasMore,
          totalPages: totalPages,
          error: null);
    } catch (e) {
      _state = _state.copyWith(
          isLoading: false, error: 'Failed to fetch mangas: $e');
    }

    _stateController.add(_state);
  }

  Future<void> _loadMoreMangas() async {
    if (_state.isLoading || !_state.hasMore) return;

    _state = _state.copyWith(isLoading: true);
    _stateController.add(_state);

    try {
      final nextPage = _state.currentPage + 1;
      final result = await _mangaRepository.getMangas(
          page: nextPage, limit: _itemsPerPage);

      final moreMangas = result['mangas'] as List<Manga>;
      final hasMore = result['hasMore'] as bool;

      _state = _state.copyWith(
          isLoading: false,
          mangas: [..._state.mangas, ...moreMangas],
          currentPage: nextPage,
          hasMore: hasMore,
          error: null);
    } catch (e) {
      _state = _state.copyWith(
          isLoading: false, error: 'Failed to load more mangas: $e');
    }

    _stateController.add(_state);
  }

  Future<void> _refreshData() async {
    _state = _state.copyWith(currentPage: 0, mangas: []);
    _stateController.add(_state);

    event.add(MangaEvent.fetchHotMangas);
    event.add(MangaEvent.fetchMangas);
  }

  // Add manga to reading history
  Future<void> addToHistory(Manga manga) async {
    await _historyRepository.addToHistory(manga);
  }

  void dispose() {
    _stateController.close();
    _eventController.close();
  }
}
