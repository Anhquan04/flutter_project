import 'dart:async';
import 'package:project_btl/repositories/history_repository.dart';

import '../model/history.dart';
import '../model/manga.dart';

enum HistoryEvent { fetch, add, clear, remove }

class HistoryState {
  final bool isLoading;
  final List<ReadingHistory> history;
  final String? error;

  HistoryState({
    this.isLoading = false,
    this.history = const [],
    this.error,
  });

  HistoryState copyWith({
    bool? isLoading,
    List<ReadingHistory>? history,
    String? error,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      history: history ?? this.history,
      error: error,
    );
  }
}

class HistoryReadingBloc {
  final HistoryRepository _historyRepository = HistoryRepository();

  // State management
  final _stateController = StreamController<HistoryState>.broadcast();
  Stream<HistoryState> get state => _stateController.stream;
  HistoryState _state = HistoryState();

  // Event controller
  final _eventController = StreamController<HistoryEvent>();
  StreamSink<HistoryEvent> get event => _eventController.sink;

  HistoryReadingBloc() {
    _eventController.stream.listen(_mapEventToState);
    _fetchHistory();
  }

  void _mapEventToState(HistoryEvent event) async {
    switch (event) {
      case HistoryEvent.fetch:
        await _fetchHistory();
        break;
      case HistoryEvent.add:
        // Được xử lý bởi phương thức addToHistory
        break;
      case HistoryEvent.clear:
        await _clearHistory();
        break;
      case HistoryEvent.remove:
        // Điều này sẽ được xử lý bởi phương thức removeFromHistory
        break;
    }
  }

  Future<void> _fetchHistory() async {
    _state = _state.copyWith(isLoading: true);
    _stateController.add(_state);

    try {
      final history = await _historyRepository.getReadingHistory();
      _state = _state.copyWith(isLoading: false, history: history, error: null);
    } catch (e) {
      _state = _state.copyWith(
          isLoading: false, error: 'Không thể tải lịch sử đọc: $e');
    }

    _stateController.add(_state);
  }

  Future<void> addToHistory(Manga manga, {String? chapterId}) async {
    try {
      await _historyRepository.addToHistory(manga, chapterId: chapterId);
      _fetchHistory(); // Refresh the history list
    } catch (e) {
      _state = _state.copyWith(error: 'Không thể thêm vào lịch sử: $e');
      _stateController.add(_state);
    }
  }

  Future<void> _clearHistory() async {
    _state = _state.copyWith(isLoading: true);
    _stateController.add(_state);

    try {
      await _historyRepository.clearHistory();
      _state = _state.copyWith(isLoading: false, history: [], error: null);
    } catch (e) {
      _state = _state.copyWith(
          isLoading: false, error: 'Không thể xóa lịch sử: $e');
    }

    _stateController.add(_state);
  }

  // Phương thức mới để xóa một truyện khỏi lịch sử
  Future<void> removeFromHistory(String mangaId) async {
    try {
      await _historyRepository.removeFromHistory(mangaId);
      _fetchHistory(); // Refresh the history list
    } catch (e) {
      _state = _state.copyWith(error: 'Không thể xóa truyện khỏi lịch sử: $e');
      _stateController.add(_state);
    }
  }

  void dispose() {
    _stateController.close();
    _eventController.close();
  }
}