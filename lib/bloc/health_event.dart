part of 'health_bloc.dart';

@immutable
sealed class HealthEvent {}

class FetchData extends HealthEvent {
  FetchData(this.dataType);

  final List<HealthDataType> dataType;
}

// fetch steps
class FetchSteps extends HealthEvent {
  final HealthDataType dataType;

  FetchSteps(this.dataType);
}

// authorize
class AuthorizeHealth extends HealthEvent {}

// getHealthConnectSdkStatus
class GetHealthConnectSdkStatus extends HealthEvent {}
