import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:parental_control_app/features/user_management/data/datasources/user_remote_datasource.dart';
import 'package:parental_control_app/features/user_management/data/datasources/pairing_remote_datasource.dart';
import 'package:parental_control_app/features/user_management/data/repositories/user_repository_impl.dart';
import 'package:parental_control_app/features/user_management/data/repositories/pairing_repository_impl.dart';
import 'package:parental_control_app/features/user_management/domain/repositories/user_repository.dart';
import 'package:parental_control_app/features/user_management/domain/repositories/pairing_repository.dart';
import 'package:parental_control_app/features/user_management/domain/usecases/login_usecase.dart';
import 'package:parental_control_app/features/user_management/domain/usecases/signup_usecase.dart';
import 'package:parental_control_app/features/user_management/domain/usecases/reset_password_usecase.dart';
import 'package:parental_control_app/features/user_management/domain/usecases/generate_parent_qr_usecase.dart';
import 'package:parental_control_app/features/user_management/domain/usecases/link_child_to_parent_usecase.dart';
import 'package:parental_control_app/features/user_management/domain/usecases/get_parent_children_usecase.dart';
import 'package:parental_control_app/features/user_management/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:parental_control_app/features/location_tracking/data/datasources/geofence_remote_datasource.dart';
import 'package:parental_control_app/features/location_tracking/data/datasources/location_remote_datasource.dart';
import 'package:parental_control_app/features/location_tracking/data/repositories/geofence_repository_impl.dart';
import 'package:parental_control_app/features/location_tracking/data/repositories/location_repository_impl.dart';
import 'package:parental_control_app/features/location_tracking/domain/repositories/geofence_repository.dart';
import 'package:parental_control_app/features/location_tracking/domain/repositories/location_repository.dart';
import 'package:parental_control_app/features/location_tracking/domain/usecases/get_last_location_usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/usecases/stream_child_location_usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/usecases/stream_geofences_usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/usecases/set_geofence_usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/usecases/delete_geofence_usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/usecases/stream_zone_events_usecase.dart';
import 'package:parental_control_app/features/location_tracking/presentation/blocs/map/map_bloc.dart';
import 'package:parental_control_app/features/location_tracking/presentation/blocs/geofence/geofence_bloc.dart';
import 'package:parental_control_app/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:parental_control_app/features/reports/data/repositories/report_repository_impl.dart';
import 'package:parental_control_app/features/reports/data/services/pdf_generator_service.dart';
import 'package:parental_control_app/features/reports/domain/repositories/report_repository.dart';
import 'package:parental_control_app/features/reports/domain/usecases/fetch_report_data_usecase.dart';
import 'package:parental_control_app/features/reports/domain/usecases/generate_report_usecase.dart';
import 'package:parental_control_app/features/reports/domain/usecases/get_reports_usecase.dart';
import 'package:parental_control_app/features/reports/domain/usecases/delete_report_usecase.dart';
import 'package:parental_control_app/features/reports/domain/usecases/rename_report_usecase.dart';
import 'package:parental_control_app/features/reports/presentation/bloc/report_bloc.dart';
import 'package:parental_control_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:parental_control_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:parental_control_app/features/notifications/data/services/fcm_service.dart';
import 'package:parental_control_app/features/notifications/data/services/alert_sender_service.dart';
import 'package:parental_control_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:parental_control_app/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:parental_control_app/features/notifications/domain/usecases/stream_notifications_usecase.dart';
import 'package:parental_control_app/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:parental_control_app/features/notifications/presentation/bloc/notification_bloc.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Firebase instances
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Data source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(auth: sl(), firestore: sl()),
  );
  sl.registerLazySingleton<PairingRemoteDataSource>(
    () => PairingRemoteDataSourceImpl(firestore: sl(), auth: sl()),
  );

  // Location & geofence data sources
  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<GeofenceRemoteDataSource>(
    () => GeofenceRemoteDataSourceImpl(firestore: sl()),
  );

  // Report data sources
  sl.registerLazySingleton<ReportRemoteDataSource>(
    () => ReportRemoteDataSourceImpl(
      firestore: sl(),
    ),
  );

  // Notification data sources
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton<PairingRepository>(
    () => PairingRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton<GeofenceRepository>(
    () => GeofenceRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );

  // Notification services
  sl.registerLazySingleton(() => FCMService());
  sl.registerLazySingleton(() => AlertSenderService());

  // Use cases
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => GenerateParentQRUseCase(sl()));
  sl.registerLazySingleton(() => LinkChildToParentUseCase(sl()));
  sl.registerLazySingleton(() => GetParentChildrenUseCase(sl()));

  // Location / geofence use cases
  sl.registerLazySingleton(() => GetLastLocationUseCase(sl()));
  sl.registerLazySingleton(() => StreamChildLocationUseCase(sl()));
  sl.registerLazySingleton(() => StreamGeofencesUseCase(sl()));
  sl.registerLazySingleton(() => SetGeofenceUseCase(sl()));
  sl.registerLazySingleton(() => DeleteGeofenceUseCase(sl()));
  sl.registerLazySingleton(() => StreamZoneEventsUseCase(sl()));

  // Report use cases
  sl.registerLazySingleton(() => FetchReportDataUseCase(sl()));
  sl.registerLazySingleton(() => GenerateReportUseCase(sl()));
  sl.registerLazySingleton(() => GetReportsUseCase(sl()));
  sl.registerLazySingleton(() => DeleteReportUseCase(sl()));
  sl.registerLazySingleton(() => RenameReportUseCase(sl()));

  // Notification use cases
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => StreamNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));

  // Report services
  sl.registerLazySingleton(() => PdfGeneratorService());

  // Bloc (factory so new instance per screen if needed)
  sl.registerFactory(
    () => AuthBloc(
      signUpUseCase: sl<SignUpUseCase>(),
      signInUseCase: sl<LoginUseCase>(),
      resetPasswordUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => MapBloc(
      streamChildLocationUseCase: sl(),
      streamGeofencesUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => GeofenceBloc(
      setGeofenceUseCase: sl(),
      deleteGeofenceUseCase: sl(),
      getLastLocationUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ReportBloc(
      fetchReportDataUseCase: sl(),
      generateReportUseCase: sl(),
      getReportsUseCase: sl(),
      deleteReportUseCase: sl(),
      renameReportUseCase: sl(),
      pdfGeneratorService: sl(),
    ),
  );

  sl.registerFactory(
    () => NotificationBloc(
      getNotificationsUseCase: sl(),
      streamNotificationsUseCase: sl(),
      markNotificationReadUseCase: sl(),
    ),
  );
}
