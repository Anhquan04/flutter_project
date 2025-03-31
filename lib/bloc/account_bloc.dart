import 'dart:async';
import 'package:project_btl/repositories/auth_repository.dart';
import '../model/user.dart';

enum AccountEvent { fetch, update, logout }

class AccountState {
  final bool isLoading;
  final User? user;
  final String? error;

  AccountState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AccountState copyWith({
    bool? isLoading,
    User? user,
    String? error,
  }) {
    return AccountState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AccountBloc {
  final AuthRepository _authRepository = AuthRepository();

  // State management
  final _stateController = StreamController<AccountState>.broadcast();
  Stream<AccountState> get state => _stateController.stream;
  AccountState _state = AccountState();

  // Event controller
  final _eventController = StreamController<AccountEvent>();
  StreamSink<AccountEvent> get event => _eventController.sink;

  AccountBloc() {
    _eventController.stream.listen(_mapEventToState);
    _fetchCurrentUser();
  }

  void _mapEventToState(AccountEvent event) async {
    switch (event) {
      case AccountEvent.fetch:
        await _fetchCurrentUser();
        break;
      case AccountEvent.update:
        // This would be implemented if profile updates were needed
        break;
      case AccountEvent.logout:
        await _logout();
        break;
    }
  }

  Future<void> _fetchCurrentUser() async {
    _state = _state.copyWith(isLoading: true);
    _stateController.add(_state);

    try {
      final user = await _authRepository.getCurrentUser();
      _state = _state.copyWith(isLoading: false, user: user, error: null);
    } catch (e) {
      _state = _state.copyWith(
          isLoading: false, error: 'Failed to fetch user data: $e');
    }

    _stateController.add(_state);
  }

  Future<void> _logout() async {
    _state = _state.copyWith(isLoading: true);
    _stateController.add(_state);

    try {
      await _authRepository.logout();
      _state = _state.copyWith(isLoading: false, user: null, error: null);
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: 'Failed to logout: $e');
    }

    _stateController.add(_state);
  }

  void dispose() {
    _stateController.close();
    _eventController.close();
  }
}
