import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        title: const Text('Weather App'),
        //centerTitle: true,
        leading: const Icon(Icons.cloud,size: 30,),
        actions: [
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
              onPressed: () {
                _detectLocation();
              },
              icon: Icon(Icons.my_location),
          ),
        ],
      ),
      body: Center(
        child: provider.hasDataLoaded ? ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            _currentWeatherSection(),
            const SizedBox(height: 10,),
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
    return Card(
      color: Colors.white54,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SwitchListTile(
                //activeColor:  Colors.amber,
                controlAffinity: ListTileControlAffinity.leading,
                activeThumbImage: AssetImage('images/fahrenheit.jpg'),
                inactiveThumbImage: AssetImage('images/celsius.png'),
                value: provider.isFahrenheit,
                onChanged: (value) async {
                  provider.setTempUnit(value);
                  await provider.setTempUnitPreferenceValue(value);
                  provider.getWeatherData();
                }
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(getFormattedDateTime(current!.dt!, 'MMM dd, yyyyy',), style: txtDateBig18,),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${current.name}, ${current.sys!.country}', style: txtAddress25,),
              ],
            ),
            Image.network('$iconPrefix${current.weather![0].icon}$iconSuffix', fit: BoxFit.cover,),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${current.main!.temp!.round()}$degree${provider.unitSymbol}', style: txtTempBig80,),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('feels like ${current.main!.feelsLike}$degree${provider.unitSymbol}', style: txtNormal16White54,),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('${current.weather![0].main} ${current.weather![0].description}', style: txtNormal16White54,),
              ],
            ),
            const SizedBox(height: 20,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Humidity ${current.main!.humidity}%  Pressure ${current.main!.pressure}hPa ', style: txtNormal16,),
              ],
            ),
            const SizedBox(height: 5,),
            Wrap(
              children: [
                Text('Sunrise: ${getFormattedDateTime(current.sys!.sunrise!, 'hh:mm a')}', style: txtNormal16White54,),
                const SizedBox(width: 10,),
                Text('Sunset: ${getFormattedDateTime(current.sys!.sunset!, 'hh:mm a')}', style: txtNormal16White54,),
              ],
            ),
            SizedBox(height: 20,),
          ],
        ),
      ),
    );
  }
  Widget _forecastWeatherSection() {
    final forecastList = provider.forecastResponseModel!.list;
    return SizedBox(
      height: 150,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forecastList!.length,
        itemBuilder: (context, index) => Card(
          color: Colors.white54,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  getFormattedDateTime(forecastList[index].dt!, 'MMM hh:mm'),
                  //style: TextStyle(color: Colors.white),
                ),
                Image.network(
                  '$iconPrefix${forecastList[index].weather![0].icon}$iconSuffix',
                  height: 30,
                  width: 30,
                  fit: BoxFit.cover,
                ),
                Text('${forecastList[index].main!.tempMax!.round()}$degree / ${forecastList[index].main!.tempMax!.round()}$degree${provider.unitSymbol}'),
                //Text('${forecastList[index].weather!}%'),
                Text(forecastList[index].weather![0].description.toString()),
              ],
            ),
          ),
        ),
      ),
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
