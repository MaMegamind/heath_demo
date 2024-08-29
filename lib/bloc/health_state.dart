part of 'health_bloc.dart';

@immutable
sealed class HealthState {}

final class HealthInitial extends HealthState {}

final class HealthDataFetched extends HealthState {
  HealthDataFetched(this.data);

  final List<HealthDataPoint> data;
}

final class HealthDataFetchInProgress extends HealthState {}

final class HealthDataFetchFailure extends HealthState {
  HealthDataFetchFailure(this.error);

  final String error;
}

// steps
final class StepsFetched extends HealthState {
  StepsFetched(this.steps);

  final int steps;
}

final class StepsFetchInProgress extends HealthState {}

final class StepsFetchFailure extends HealthState {
  StepsFetchFailure(this.error);

  final String error;
}

// authorize
final class HealthAuthorized extends HealthState {}

final class HealthNotAuthorized extends HealthState {}

final class HealthAuthorizationInProgress extends HealthState {}

// getHealthConnectSdkStatus
final class HealthConnectSdkStatus extends HealthState {}
