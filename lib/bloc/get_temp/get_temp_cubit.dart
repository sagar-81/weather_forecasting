import 'dart:convert';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:weather_forecasting/constant.dart';
import 'package:weather_forecasting/model/weather_model.dart';

part 'get_temp_state.dart';

class GetTempCubit extends Cubit<GetTempState> {
  GetTempCubit() : super(GetTempInitialState());

  void fetchTempData({double? lat, double? lon, String? city}) async {
    try {
      emit(GetTempLoadingState());
      String url;
      if (city != null && city.isNotEmpty) {
        url = "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=${AppString.apiKey}&units=metric";
      } else if (lat != null && lon != null) {
        url =
            "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=${AppString.apiKey}&units=metric";
      } else {
        emit(GetTempErrorState("Invalid parameters: Provide either city or latitude/longitude"));
        return;
      }

      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        log("Response : - $result $url");
        emit(GetTempLoadedState(getTempratureModelFromJson(json.encode(result))));
      } else {
        var errorResult = jsonDecode(response.body);
        emit(GetTempErrorState(errorResult['message'] ?? "Failed to fetch weather data"));
      }
    } catch (e) {
      emit(GetTempErrorState("Error: ${e.toString()}"));
    }
  }
}
