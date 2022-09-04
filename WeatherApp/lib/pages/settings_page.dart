import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/provider/weather_provider.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text('Settings'),
        //centerTitle: true,
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, provider, child) => ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            SwitchListTile(
              title: const Text('Show temperature in Fahrenheit'),
              subtitle: const Text('Default is Celsius'),
              value: provider.isFahrenheit,
              onChanged: (value) async {
                provider.setTempUnit(value);
                await provider.setTempUnitPreferenceValue(value);
                provider.getWeatherData();
              }
            ),
          ],
        ),
      ),
    );
  }
}
