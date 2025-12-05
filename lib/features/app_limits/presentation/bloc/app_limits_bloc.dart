import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/app_limits_repository.dart';
import '../../domain/usecases/get_app_usage_stats.dart';
import '../../domain/usecases/set_app_limit.dart';
import '../../domain/usecases/clear_app_limit.dart';
import '../../domain/usecases/set_global_limit.dart';
import '../../domain/usecases/clear_global_limit.dart';
import 'app_limits_event.dart';
import 'app_limits_state.dart';

class AppLimitsBloc extends Bloc<AppLimitsEvent, AppLimitsState> {
  final GetAppUsageStats _getAppUsageStats;
  final SetAppLimitUseCase _setAppLimit;
  final ClearAppLimitUseCase _clearAppLimit;
  final SetGlobalLimitUseCase _setGlobalLimit;
  final ClearGlobalLimitUseCase _clearGlobalLimit;
  final AppLimitsRepository _repository;

  AppLimitsBloc({
    required GetAppUsageStats getAppUsageStats,
    required SetAppLimitUseCase setAppLimit,
    required ClearAppLimitUseCase clearAppLimit,
    required SetGlobalLimitUseCase setGlobalLimit,
    required ClearGlobalLimitUseCase clearGlobalLimit,
    required AppLimitsRepository repository,
  })  : _getAppUsageStats = getAppUsageStats,
        _setAppLimit = setAppLimit,
        _clearAppLimit = clearAppLimit,
        _setGlobalLimit = setGlobalLimit,
        _clearGlobalLimit = clearGlobalLimit,
        _repository = repository,
        super(AppLimitsInitial()) {
    
    on<LoadAppUsageStats>(_onLoadAppUsageStats);
    on<SetAppLimit>(_onSetAppLimit);
    on<ClearAppLimit>(_onClearAppLimit);
    on<SetGlobalLimit>(_onSetGlobalLimit);
    on<ClearGlobalLimit>(_onClearGlobalLimit);
    on<UpdateAppUsage>(_onUpdateAppUsage);
    on<ResetDailyLimits>(_onResetDailyLimits);
  }

  Future<void> _onLoadAppUsageStats(
    LoadAppUsageStats event,
    Emitter<AppLimitsState> emit,
  ) async {
    try {
      emit(AppLimitsLoading());
      
      final appUsageStats = await _getAppUsageStats();
      final globalLimit = await _repository.getGlobalLimit();
      
      emit(AppLimitsLoaded(
        appUsageStats: appUsageStats,
        globalLimit: globalLimit,
      ));
    } catch (e) {
      emit(AppLimitsError('Failed to load app usage stats: $e'));
    }
  }

  Future<void> _onSetAppLimit(
    SetAppLimit event,
    Emitter<AppLimitsState> emit,
  ) async {
    try {
      await _setAppLimit(event.packageName, event.dailyLimitMinutes);
      
      if (state is AppLimitsLoaded) {
        final currentState = state as AppLimitsLoaded;
        add(LoadAppUsageStats());
      }
    } catch (e) {
      emit(AppLimitsError('Failed to set app limit: $e'));
    }
  }

  Future<void> _onClearAppLimit(
    ClearAppLimit event,
    Emitter<AppLimitsState> emit,
  ) async {
    try {
      await _clearAppLimit(event.packageName);
      
      if (state is AppLimitsLoaded) {
        final currentState = state as AppLimitsLoaded;
        add(LoadAppUsageStats());
      }
    } catch (e) {
      emit(AppLimitsError('Failed to clear app limit: $e'));
    }
  }

  Future<void> _onSetGlobalLimit(
    SetGlobalLimit event,
    Emitter<AppLimitsState> emit,
  ) async {
    try {
      await _setGlobalLimit(event.dailyLimitMinutes);
      
      if (state is AppLimitsLoaded) {
        final currentState = state as AppLimitsLoaded;
        add(LoadAppUsageStats());
      }
    } catch (e) {
      emit(AppLimitsError('Failed to set global limit: $e'));
    }
  }

  Future<void> _onClearGlobalLimit(
    ClearGlobalLimit event,
    Emitter<AppLimitsState> emit,
  ) async {
    try {
      await _clearGlobalLimit();
      
      if (state is AppLimitsLoaded) {
        final currentState = state as AppLimitsLoaded;
        add(LoadAppUsageStats());
      }
    } catch (e) {
      emit(AppLimitsError('Failed to clear global limit: $e'));
    }
  }

  Future<void> _onUpdateAppUsage(
    UpdateAppUsage event,
    Emitter<AppLimitsState> emit,
  ) async {
    if (state is AppLimitsLoaded) {
      final currentState = state as AppLimitsLoaded;
      final updatedStats = currentState.appUsageStats.map((app) {
        if (app.packageName == event.appUsage.packageName) {
          return event.appUsage;
        }
        return app;
      }).toList();
      
      emit(currentState.copyWith(appUsageStats: updatedStats));
    }
  }

  Future<void> _onResetDailyLimits(
    ResetDailyLimits event,
    Emitter<AppLimitsState> emit,
  ) async {
    try {
      await _repository.resetDailyIfNeeded();
      add(LoadAppUsageStats());
    } catch (e) {
      emit(AppLimitsError('Failed to reset daily limits: $e'));
    }
  }
}
