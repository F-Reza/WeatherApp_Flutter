import 'dart:convert';
import 'package:geocoding/geocoding.dart' as Geo;
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/models/current_response_model.dart';
import 'package:weather_app/models/forecast_response_model.dart';
import 'package:weather_app/utils/helper_functions.dart';

import '../utils/constants.dart';

class WeatherProvider extends ChangeNotifier {

  CurrentResponseModel? currentResponseModel;
  ForecastResponseModel? forecastResponseModel;
  double latitude = 0.0, longitude = 0.0;
  String unit = metric; //imperial
  String unitSymbol = celsius;

  bool get isFahrenheit => unit == imperial;

  bool get hasDataLoaded => currentResponseModel != null &&
      forecastResponseModel != null;

  setNewLocation(double lat, double lng) {
    latitude = lat;
    longitude = lng;
  }

  Future<bool> setTempUnitPreferenceValue(bool value) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setBool('unit', value);
  }

  Future<bool> getTempUnitPreferenceValue() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool('unit') ?? false;
  }

  getWeatherData() {
    _getCurrentData();
    _getForecastData();
  }

  void _getCurrentData() async {
    final uri = Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=$unit&appid=$WeatherApiKey');
    try {
      final response = await get(uri);
      final map = jsonDecode(response.body);
      if(response.statusCode == 200) {
        currentResponseModel = CurrentResponseModel.fromJson(map);
        print(currentResponseModel!.main!.temp!.round());
        notifyListeners();
      } else {
        print(map['message']);
      }
    } catch (error) {
      rethrow;
    }

  }

  void _getForecastData() async {
    final uri = Uri.parse('https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&units=$unit&appid=$WeatherApiKey');
    try {
      final response = await get(uri);
      final map = jsonDecode(response.body);
      if(response.statusCode == 200) {
        forecastResponseModel = ForecastResponseModel.fromJson(map);
        print(forecastResponseModel!.list!.length);
        notifyListeners();
      } else {
        print(map['message']);
      }
    } catch (error) {
      rethrow;
    }

  }


  void setTempUnit(bool value) {
    unit = value ? imperial : metric;
    unitSymbol = value ? fahrenheit : celsius;
    notifyListeners();
  }

  void convertCityToLatLng({
    required String result,
    required Function(String) onError
  }) async {
    try {
      final locList = await Geo.locationFromAddress(result);
      if(locList.isNotEmpty) {
        final location = locList.first;
        setNewLocation(location.latitude, location.longitude);
        getWeatherData();
      } else {
        onError('City not found!');
      }
    } catch(error) {
      onError(error.toString());
    }
  }

  void defaultCityToLatLng() async {
    await setNewLocation(23.7973283, 90.3666064);
    getWeatherData();
  }



}