import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider with ChangeNotifier {
  double _latitude = -1.2921;
  double _longitude = 36.8219;
  bool _locationEnabled = false;
  bool _isLoading = false;

  double get latitude => _latitude;
  double get longitude => _longitude;
  bool get locationEnabled => _locationEnabled;
  bool get isLoading => _isLoading;

  LocationProvider() {
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationEnabled = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationEnabled = false;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationEnabled = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationEnabled = true;
      
      print('📍 GPS Location fetched: $_latitude, $_longitude');
    } catch (e) {
      print('Error getting location: $e');
      _locationEnabled = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateLocation(double lat, double lon) {
    _latitude = lat;
    _longitude = lon;
    notifyListeners();
  }

  void toggleLocation() {
    _locationEnabled = !_locationEnabled;
    notifyListeners();
  }
}
