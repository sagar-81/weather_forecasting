import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_forecasting/screen/home.dart';
import 'package:weather_forecasting/storage/local_storage.dart';

import 'bloc/get_temp/get_temp_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageUtils.init().then(
    (e) => {
      log("Storage Get Initialized ....."),
    },
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetTempCubit(),
      child: MaterialApp(
        theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
            )),
        debugShowCheckedModeBanner: false,
        title: 'Wether App',
        home: const HomeScreen(),
      ),
    );
  }
}
