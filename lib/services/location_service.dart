import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_model.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance {
    _instance ??= LocationService._internal();
    return _instance!;
  }

  LocationService._internal();

  /// 위치 권한 확인
  Future<bool> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return true;
        case LocationPermission.denied:
        case LocationPermission.deniedForever:
        case LocationPermission.unableToDetermine:
          return false;
      }
    } catch (e) {
      debugPrint('위치 권한 확인 오류: $e');
      return false;
    }
  }

  /// 위치 권한 요청
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // 사용자가 영구히 거부한 경우, 설정 화면으로 이동
        debugPrint('위치 권한이 영구히 거부되었습니다. 설정에서 권한을 허용해주세요.');
        return false;
      }

      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      debugPrint('위치 권한 요청 오류: $e');
      return false;
    }
  }

  /// 위치 서비스 사용 가능 여부 확인
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('위치 서비스 확인 오류: $e');
      return false;
    }
  }

  /// 현재 위치 가져오기
  Future<LocationModel?> getCurrentLocation() async {
    try {
      // 위치 서비스 활성화 확인
      if (!await isLocationServiceEnabled()) {
        debugPrint('위치 서비스가 비활성화되어 있습니다.');
        return null;
      }

      // 권한 확인 및 요청
      if (!await checkLocationPermission()) {
        final hasPermission = await requestLocationPermission();
        if (!hasPermission) {
          debugPrint('위치 권한이 필요합니다.');
          return null;
        }
      }

      debugPrint('🌍 현재 위치 가져오기 시작...');
      
      // 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // 10m 이상 움직일 때만 업데이트
          timeLimit: Duration(seconds: 10), // 10초 타임아웃
        ),
      );

      debugPrint('✅ 위치 획득 성공: ${position.latitude}, ${position.longitude}');

      // 주소 정보 가져오기 (옵션)
      String? address;
      String? city;
      String? district;
      
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = '${placemark.street ?? ''} ${placemark.subThoroughfare ?? ''}'.trim();
          city = placemark.locality ?? placemark.administrativeArea;
          district = placemark.subLocality ?? placemark.subAdministrativeArea;
          
          debugPrint('📍 주소 정보: $address, $city, $district');
        }
      } catch (e) {
        debugPrint('⚠️ 주소 정보 가져오기 실패: $e');
      }

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        city: city,
        district: district,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

    } catch (e) {
      debugPrint('❌ 위치 가져오기 실패: $e');
      return null;
    }
  }

  /// 위치 변화 감지 스트림
  Stream<LocationModel>? getLocationStream() {
    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // 20m 이상 이동할 때만 업데이트
      );

      return Geolocator.getPositionStream(locationSettings: locationSettings)
          .asyncMap((position) async {
        // 주소 정보 가져오기 (옵션)
        String? address;
        String? city;
        String? district;
        
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude, 
            position.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            address = '${placemark.street ?? ''} ${placemark.subThoroughfare ?? ''}'.trim();
            city = placemark.locality ?? placemark.administrativeArea;
            district = placemark.subLocality ?? placemark.subAdministrativeArea;
          }
        } catch (e) {
          debugPrint('주소 정보 가져오기 실패: $e');
        }

        return LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
          city: city,
          district: district,
          accuracy: position.accuracy,
          timestamp: DateTime.now(),
        );
      });
    } catch (e) {
      debugPrint('위치 스트림 생성 실패: $e');
      return null;
    }
  }

  /// 두 위치 간의 거리 계산 (미터)
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 위치 모델을 Google Maps URL로 변환
  String getGoogleMapsUrl(LocationModel location) {
    return 'https://maps.google.com/maps?q=${location.latitude},${location.longitude}';
  }

  /// 위치 정보를 문자열로 포맷
  String formatLocationInfo(LocationModel location) {
    final parts = <String>[];
    
    if (location.address != null && location.address!.isNotEmpty) {
      parts.add(location.address!);
    }
    
    if (location.district != null && location.district!.isNotEmpty) {
      parts.add(location.district!);
    }
    
    if (location.city != null && location.city!.isNotEmpty) {
      parts.add(location.city!);
    }
    
    if (parts.isEmpty) {
      parts.add('위도: ${location.latitude.toStringAsFixed(6)}');
      parts.add('경도: ${location.longitude.toStringAsFixed(6)}');
    }
    
    return parts.join(', ');
  }

  /// 위치 정확도를 문자열로 변환
  String formatAccuracy(double? accuracy) {
    if (accuracy == null) return '알 수 없음';
    
    if (accuracy < 5) {
      return '매우 정확함 (${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy < 10) {
      return '정확함 (${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy < 50) {
      return '보통 (${accuracy.toStringAsFixed(1)}m)';
    } else {
      return '부정확함 (${accuracy.toStringAsFixed(1)}m)';
    }
  }

  /// 설정 화면으로 이동 (권한이 영구히 거부된 경우)
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('설정 화면 열기 실패: $e');
    }
  }
  

  /// 앱 설정 화면으로 이동 (권한 설정용)
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('앱 설정 화면 열기 실패: $e');
    }
  }
}