part of 'get_temp_cubit.dart';

sealed class GetTempState extends Equatable {}

final class GetTempInitialState extends GetTempState {
  @override
  List<Object?> get props => [];
}

final class GetTempLoadingState extends GetTempState {
  @override
  List<Object?> get props => [];
}

final class GetTempLoadedState extends GetTempState {
  final WeatherModel model;
  GetTempLoadedState(this.model);
  @override
  List<Object?> get props => [model];
}

final class GetTempErrorState extends GetTempState {
  final String error;
  GetTempErrorState(this.error);
  @override
  List<Object?> get props => [];
}
