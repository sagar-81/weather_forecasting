import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:weather_forecasting/bloc/get_temp/get_temp_cubit.dart';
import 'package:weather_forecasting/storage/local_storage.dart';

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
  void dispose() {
    _searchController.dispose();
    _isFahrenheit.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _checkLocation();
    _loadUnitPreference();
    super.initState();
  }

  Future<void> _loadUnitPreference() async {
    String? unit = LocalStorageUtils.unit;
    if (unit != null) {
      _isFahrenheit.value = unit == 'F';
    }
  }

  void _toggleTemperatureUnit(bool value) async {
    _isFahrenheit.value = value;
    await LocalStorageUtils.saveUnit(value ? 'F' : 'C');
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Weather Forecasting',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _isFahrenheit,
            builder: (context, isFahrenheit, child) {
              return Row(
                children: [
                  Switch(
                    value: isFahrenheit,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      _toggleTemperatureUnit(value);
                    },
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    "°${isFahrenheit ? 'F' : 'C'}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
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
              ValueListenableBuilder<bool>(
                valueListenable: _isFahrenheit,
                builder: (context, value, _) {
                  return BlocBuilder<GetTempCubit, GetTempState>(
                    builder: (context, state) {
                      if (state is GetTempLoadingState) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is GetTempLoadedState) {
                        var weatherData = state.model;
                        double temperature = weatherData.main?.temp ?? 0.0;
                        if (value) {
                          temperature = _convertTemperature(temperature, true);
                        }

                        if (isSearch) {
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
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Image.network(
                                  "https://openweathermap.org/img/wn/${weatherData.weather?[0].icon}@4x.png",
                                  height: 100,
                                ),
                                Text(
                                  "${temperature.toStringAsFixed(1)}°${value ? 'F' : 'C'}",
                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  weatherData.weather?[0].description?.toUpperCase() ?? "",
                                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _weatherDetail(Icons.water_drop, "Humidity", "${weatherData.main?.humidity}%"),
                                    _weatherDetail(Icons.air, "Wind Speed", "${weatherData.wind?.speed} m/s"),
                                    _weatherDetail(Icons.thermostat, "Pressure", "${weatherData.main?.pressure} hPa"),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _weatherDetail(
                                        Icons.wb_sunny, "Sunrise", _formatTime(weatherData.sys?.sunrise ?? 0)),
                                    _weatherDetail(
                                        Icons.nights_stay, "Sunset", _formatTime(weatherData.sys?.sunset ?? 0)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (state is GetTempErrorState) {
                        return Center(
                          child: Text(
                            state.error.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final DateTime time = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('hh:mm a').format(time);
  }

  Widget _weatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
