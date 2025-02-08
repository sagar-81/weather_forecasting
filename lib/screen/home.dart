import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_forecasting/bloc/get_temp/get_temp_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _isFahrenheit = ValueNotifier(false);
  bool isSearch = false;

  @override
  void initState() {
    _checkLocation();
    super.initState();
  }

  Future<void> _checkLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showPermissionDialog("Location services are disabled. Enable them in settings.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDialog("Location permission is required to fetch weather details.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDialog("Location permission is permanently denied. Enable it in settings.");
      return;
    }

    _fetchWeatherByLocation();
  }

  Future<void> _fetchWeatherByLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      context.read<GetTempCubit>().fetchTempData(lat: position.latitude, lon: position.longitude);
    }
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Location Permission Required"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                _checkLocation();
              },
              child: const Text("Try Again"),
            ),
          ],
        );
      },
    );
  }

  double _convertTemperature(double tempInCelsius, bool isFahrenheit) {
    return isFahrenheit ? (tempInCelsius * 9 / 5) + 32 : tempInCelsius;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather Forecasting',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _isFahrenheit,
            builder: (context, isFahrenheit, child) {
              return Switch(
                value: isFahrenheit,
                onChanged: (value) {
                  _isFahrenheit.value = value;
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    isSearch = true;
                    String city = _searchController.text.trim();
                    if (city.isNotEmpty) {
                      context.read<GetTempCubit>().fetchTempData(city: city);
                    }
                  },
                ),
                hintText: "Enter city name...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            BlocBuilder<GetTempCubit, GetTempState>(
              builder: (context, state) {
                if (state is GetTempLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is GetTempLoadedState) {
                  var weatherData = state.model;
                  double temperature = weatherData.main?.temp;
                  if (_isFahrenheit.value) {
                    temperature = _convertTemperature(temperature,true);
                  }

                  if(isSearch){
                    LocalStorageUtils.saveLastCity(weatherData.name ?? "");
                    LocalStorageUtils.saveLastTemp(temperature.toStringAsFixed(1));
                  }
                  return Card(
                    elevation: 4,
                    surfaceTintColor: Colors.white,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            weatherData.name ?? "",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Image.network(
                            "https://openweathermap.org/img/wn/${weatherData.weather?[0].icon}@2x.png",
                            height: 80,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${weatherData.main?.temp?.toStringAsFixed(1)}°C",
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            weatherData.weather?[0].description?.toUpperCase() ?? "",
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.water_drop, color: Colors.blue),
                                  const SizedBox(height: 4),
                                  Text("${weatherData.main?.humidity}%"),
                                  const Text("Humidity", style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(Icons.air, color: Colors.green),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${weatherData.wind?.speed} m/s",
                                  ),
                                  const Text("Wind Speed", style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is GetTempErrorState) {
                  return Center(child: Text(state.error, style: const TextStyle(color: Colors.red)));
                }
                return const Center(child: Text("Search for a city to get weather details."));
              },
            ),
          ],
        ),
      ),
    );
  }
}
