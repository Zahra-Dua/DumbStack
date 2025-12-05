Module: Location Tracking & Safety Alerts (Clean Architecture)

Data
- datasources/
  - location_remote_datasource.dart: reads users/{parentId}/children/{childId}/lastLocation
  - geofence_remote_datasource.dart: CRUD on users/{parentId}/children/{childId}/geofences and stream zoneEvents
- models/
  - child_location_model.dart, geofence_zone_model.dart, zone_event_model.dart
- repositories/
  - location_repository_impl.dart, geofence_repository_impl.dart

Domain
- entities/: ChildLocation, GeofenceZone, ZoneEvent
- repositories/: LocationRepository, GeofenceRepository
- usecases/: GetLastLocation, StreamChildLocation, StreamGeofences, SetGeofence, DeleteGeofence, StreamZoneEvents

Presentation
- blocs/
  - map/: MapBloc streams child location + geofences (MapStarted -> MapLoaded)
  - geofence/: GeofenceBloc handles name/radius save and delete
- pages/
  - map_screen.dart: GoogleMap showing child marker and circles for geofences, Edit Safe Zone CTA
  - safe_zone_edit_screen.dart: Name input + map with draggable center and radius slider

Firestore (parent subtree)
users/{parentId}/children/{childId}
  - lastLocation (doc)
    { lat, lng, accuracy, speed, timestamp, source }
  - geofences/{zoneId}
    { name, center:{lat,lng}, radiusMeters, active }
  - zoneEvents/{eventId}
    { zoneId, type:'enter'|'exit', occurredAt }

Security Rules (essence)
- Parent can read/write only within users/{parentId} subtree
- Child app writes only its own lastLocation, locations, zoneEvents (no reading siblings)
- Only parent may create/update/delete geofences

UI Entry
- ParentHomeScreen: bottom nav Map or tap Children’s Location -> MapScreen
- MapScreen -> Edit Safe Zone -> SafeZoneEditScreen