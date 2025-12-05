import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'url_tracking_event.dart';
import 'url_tracking_state.dart';
import '../../data/models/visited_url.dart';
import '../../data/datasources/url_tracking_service.dart';

class UrlTrackingBloc extends Bloc<UrlTrackingEvent, UrlTrackingState> {
  final UrlTrackingService _urlTrackingService;
  StreamSubscription<VisitedUrl>? _urlStreamSubscription;

  UrlTrackingBloc({
    required UrlTrackingService urlTrackingService,
  })  : _urlTrackingService = urlTrackingService,
        super(const UrlTrackingInitial()) {
    
    on<LoadVisitedUrls>(_onLoadVisitedUrls);
    on<AddVisitedUrl>(_onAddVisitedUrl);
    on<UpdateUrlBlockStatus>(_onUpdateUrlBlockStatus);
    on<DeleteVisitedUrl>(_onDeleteVisitedUrl);
    on<StartUrlTracking>(_onStartUrlTracking);
    on<StopUrlTracking>(_onStopUrlTracking);
    on<CheckPermissions>(_onCheckPermissions);
    on<RequestPermissions>(_onRequestPermissions);
  }

  Future<void> _onLoadVisitedUrls(
    LoadVisitedUrls event,
    Emitter<UrlTrackingState> emit,
  ) async {
    try {
      emit(const UrlTrackingLoading());
      
      // LOAD FROM LOCAL STORAGE - Proper list maintenance
      final trackingUrls = await _urlTrackingService.loadVisitedUrls();
      
      // Load URLs from storage for proper list display
      final allUrls = <VisitedUrl>[];
      
      // Add URLs from local storage
      for (final url in trackingUrls) {
        allUrls.add(url);
      }
      
      print('📊 BLOC: Loaded ${allUrls.length} URLs from local storage');
      
      // Sort by visit time (newest first)
      allUrls.sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
      
      final hasPermissions = await _checkUsageStatsPermission();
      
      emit(UrlTrackingLoaded(
        visitedUrls: allUrls,
        hasPermissions: hasPermissions,
      ));
    } catch (e) {
      emit(UrlTrackingError('Failed to load visited URLs: $e'));
    }
  }

  Future<void> _onAddVisitedUrl(
    AddVisitedUrl event,
    Emitter<UrlTrackingState> emit,
  ) async {
    try {
      print('UrlTrackingBloc: Adding new URL: ${event.url.url}');
      
      // ADD TO REAL-TIME LIST AND UPDATE STORAGE
      if (state is UrlTrackingLoaded) {
        final currentState = state as UrlTrackingLoaded;
        
        // ADD NEW URL to existing list
        final updatedUrls = List<VisitedUrl>.from(currentState.visitedUrls);
        
        // Check if URL already exists (prevent duplicates)
        final exists = updatedUrls.any((existingUrl) => existingUrl.url == event.url.url);
        if (!exists) {
          updatedUrls.insert(0, event.url); // Add at the beginning
          print('UrlTrackingBloc: Added new URL to list: ${event.url.url}');
          
          // Update local storage
          try {
            await _urlTrackingService.localStorage.addVisitedUrl(event.url);
            print('💾 Bloc: URL saved to local storage: ${event.url.url}');
          } catch (e) {
            print('⚠️ Bloc: Error saving to storage: $e');
          }
        } else {
          print('UrlTrackingBloc: URL already exists, skipping: ${event.url.url}');
        }
        
        // NO LIMIT - Keep all URLs for complete tracking
        // Removed URL limit to track unlimited URLs
        
        emit(currentState.copyWith(visitedUrls: updatedUrls));
      } else {
        // If not in loaded state, start with new URL
        print('UrlTrackingBloc: Starting with new URL');
        emit(UrlTrackingLoaded(
          visitedUrls: [event.url],
          hasPermissions: true,
        ));
        
        // Save to storage
        try {
          await _urlTrackingService.localStorage.addVisitedUrl(event.url);
          print('💾 Bloc: Initial URL saved to storage: ${event.url.url}');
        } catch (e) {
          print('⚠️ Bloc: Error saving initial URL: $e');
        }
      }
    } catch (e) {
      print('UrlTrackingBloc: Error adding visited URL: $e');
      emit(UrlTrackingError('Failed to add visited URL: $e'));
    }
  }

  Future<void> _onUpdateUrlBlockStatus(
    UpdateUrlBlockStatus event,
    Emitter<UrlTrackingState> emit,
  ) async {
    try {
      // UPDATE UI STATE AND STORAGE
      if (state is UrlTrackingLoaded) {
        final currentState = state as UrlTrackingLoaded;
        final updatedUrls = currentState.visitedUrls.map((url) {
          if (url.id == event.urlId) {
            final updatedUrl = url.copyWith(isBlocked: event.isBlocked);
            // Update in storage
            _urlTrackingService.localStorage.updateVisitedUrl(updatedUrl);
            return updatedUrl;
          }
          return url;
        }).toList();
        
        emit(currentState.copyWith(visitedUrls: updatedUrls));
      }
    } catch (e) {
      emit(UrlTrackingError('Failed to update URL block status: $e'));
    }
  }

  Future<void> _onDeleteVisitedUrl(
    DeleteVisitedUrl event,
    Emitter<UrlTrackingState> emit,
  ) async {
    try {
      // UPDATE UI STATE AND STORAGE
      if (state is UrlTrackingLoaded) {
        final currentState = state as UrlTrackingLoaded;
        final updatedUrls = currentState.visitedUrls
            .where((url) => url.id != event.urlId)
            .toList();
        
        // Delete from storage
        await _urlTrackingService.localStorage.deleteVisitedUrl(event.urlId);
        
        emit(currentState.copyWith(visitedUrls: updatedUrls));
      }
    } catch (e) {
      emit(UrlTrackingError('Failed to delete visited URL: $e'));
    }
  }

  Future<void> _onStartUrlTracking(
    StartUrlTracking event,
    Emitter<UrlTrackingState> emit,
  ) async {
    try {
      final hasPermissions = await _checkUsageStatsPermission();
      if (!hasPermissions) {
        emit(const PermissionsDenied());
        return;
      }

      await _urlTrackingService.startTracking();
      
      // Listen to URL updates from the service - ONE URL AT A TIME
      _urlStreamSubscription?.cancel();
      _urlStreamSubscription = _urlTrackingService.urlStream.listen((visitedUrl) {
        print('UrlTrackingBloc: Processing URL from stream: ${visitedUrl.url}');
        add(AddVisitedUrl(visitedUrl));
      });

      if (state is UrlTrackingLoaded) {
        final currentState = state as UrlTrackingLoaded;
        emit(currentState.copyWith(isTrackingActive: true));
      }
    } catch (e) {
      emit(UrlTrackingError('Failed to start URL tracking: $e'));
    }
  }

  Future<void> _onStopUrlTracking(
    StopUrlTracking event,
    Emitter<UrlTrackingState> emit,
  ) async {
    try {
      await _urlTrackingService.stopTracking();
      _urlStreamSubscription?.cancel();
      _urlStreamSubscription = null;

      if (state is UrlTrackingLoaded) {
        final currentState = state as UrlTrackingLoaded;
        emit(currentState.copyWith(isTrackingActive: false));
      }
    } catch (e) {
      emit(UrlTrackingError('Failed to stop URL tracking: $e'));
    }
  }

  Future<void> _onCheckPermissions(
    CheckPermissions event,
    Emitter<UrlTrackingState> emit,
  ) async {
    final hasPermissions = await _checkUsageStatsPermission();
    if (hasPermissions) {
      emit(const PermissionsGranted());
    } else {
      emit(const PermissionsDenied());
    }
  }

  Future<void> _onRequestPermissions(
    RequestPermissions event,
    Emitter<UrlTrackingState> emit,
  ) async {
    try {
      // Request accessibility permission first (for real URL tracking)
      await _urlTrackingService.requestAccessibilityPermission();
      
      // Also request usage stats permission as fallback
      await _urlTrackingService.requestUsageStatsPermission();
      
      // Check if any permission was granted
      final hasPermission = await _checkUsageStatsPermission();
      if (hasPermission) {
        emit(const PermissionsGranted());
      } else {
        emit(const PermissionsDenied());
      }
    } catch (e) {
      emit(UrlTrackingError('Failed to request permissions: $e'));
    }
  }

  Future<bool> _checkUsageStatsPermission() async {
    // For usage stats permission, we need to check if it's granted
    // This is a special permission that requires user to manually enable
    try {
      final hasUsageStats = await _urlTrackingService.hasUsageStatsPermission();
      final hasAccessibility = await _urlTrackingService.hasAccessibilityPermission();
      return hasUsageStats || hasAccessibility;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> close() {
    _urlStreamSubscription?.cancel();
    return super.close();
  }
}
