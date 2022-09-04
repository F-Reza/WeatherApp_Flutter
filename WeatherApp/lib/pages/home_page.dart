import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/pages/settings_page.dart';
import 'package:weather_app/provider/weather_provider.dart';

import '../utils/constants.dart';
import '../utils/helper_functions.dart';
import '../utils/location_service.dart';
import '../utils/text_styles.dart';

class HomePage extends StatefulWidget {
  static const String routeName = '/';
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late WeatherProvider provider;
  bool isFirst = true;

  @override
  void didChangeDependencies() {
    if(isFirst) {
      provider = Provider.of<WeatherProvider>(context);
      _detectLocation();
      isFirst = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Weather'),
        //centerTitle: true,
        leading: const Icon(Icons.cloud,size: 30,),
        actions: [
          IconButton(
              onPressed: () {
                _detectLocation();
              },
              icon: Icon(Icons.my_location),
          ),
          IconButton(
            onPressed: () async {
              final result = await showSearch(
                  context: context, delegate: _CitySearchDelegate());
              if(result != null && result.isNotEmpty) {
                print(result);
                provider.convertCityToLatLng(result: result,onError: (msg) {
                  showMessage(context, msg);
                });
              }
            },
            icon: Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, SettingsPage.routeName),
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child: provider.hasDataLoaded ? ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          children: [
            _currentWeatherSection(),
            _forecastWeatherSection(),
          ],
        ) :
        const Text('Please Wait....'),
      ),
    );
  }

  void _detectLocation() async {
    provider.defaultCityToLatLng();
    final position = await determinePosition();
    provider.setNewLocation(position.latitude, position.longitude);
    provider.setTempUnit(await provider.getTempUnitPreferenceValue());
    provider.getWeatherData();
  }

  Widget _currentWeatherSection() {
    final current = provider.currentResponseModel;
    return Column(
      children: [
        Text(getFormattedDateTime(current!.dt!, 'MMM dd, yyyyy',), style: txtDateBig18,),
        Text('${current.name}, ${current.sys!.country}', style: txtAddress25,),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network('$iconPrefix${current.weather![0].icon}$iconSuffix', fit: BoxFit.cover,),
              Text('${current.main!.temp!.round()}$degree${provider.unitSymbol}', style: txtTempBig80,),
            ],
          ),
        ),
        Text('feels like ${current.main!.feelsLike}$degree${provider.unitSymbol}', style: txtNormal16White54,),
        Text('${current.weather![0].main} ${current.weather![0].description}', style: txtNormal16White54,),
        const SizedBox(height: 10,),
        Card(
          color: Colors.grey.shade500,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              children: [
                Text('Humidity ${current.main!.humidity}% ', style: txtNormal16,),
                Text('Pressure ${current.main!.pressure}hPa ', style: txtNormal16,),
                Text('Visibility ${current.visibility}meter ', style: txtNormal16,),
                Text('Wind Speed ${current.wind!.speed}meter/sec ', style: txtNormal16,),
                Text('Degree ${current.wind!.deg}$degree ', style: txtNormal16,),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5,),
        Wrap(
          children: [
            Text('Sunrise: ${getFormattedDateTime(current.sys!.sunrise!, 'hh:mm a')}', style: txtNormal16White54,),
            const SizedBox(width: 10,),
            Text('Sunset: ${getFormattedDateTime(current.sys!.sunset!, 'hh:mm a')}', style: txtNormal16White54,),
          ],
        )
      ],
    );
  }

  Widget _forecastWeatherSection() {
    final forecast = provider.forecastResponseModel;
    return Column(
      children: forecast!.list!.map((item) =>
      ListTile(
        leading: Image.network('$iconPrefix${item.weather![0].icon}$iconSuffix', fit: BoxFit.cover,),
        title: Text(item.weather![0].main.toString()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${item.main!.tempMax.toString()}$degree',style: TextStyle(color: Colors.white),),
            const SizedBox(width: 10,),
            Text('${item.main!.tempMin.toString()}$degree',style: TextStyle(color: Colors.grey),),
          ],
        ),
      )
      ).toList()
    );
  }

}



class _CitySearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: () {
            query = '';
          },
          icon: Icon(Icons.clear),),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    IconButton(
        onPressed: () {

        },
        icon: Icon(Icons.arrow_back)
    );
    //return null;
  }

  @override
  Widget buildResults(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.search),
      title: Text(query),
      onTap: () {
        close(context, query);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredList = query.isEmpty ? cities : 
    cities.where((city) => city.toLowerCase().startsWith(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(filteredList[index]),
        onTap: () {
          query = filteredList[index];
          close(context, query);
        },
      ),
    );
  }

}
