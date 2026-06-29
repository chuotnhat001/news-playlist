export 'cache_service_interface.dart' show CacheServiceBase;

import 'cache_service_interface.dart';
import 'cache_service_web.dart'
    if (dart.library.io) 'cache_service_native.dart' as platform;

typedef CacheService = CacheServiceBase;

CacheServiceBase createCacheService() => platform.createCacheService();
