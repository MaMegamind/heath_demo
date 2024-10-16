import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils.dart';

part 'health_event.dart';
part 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  HealthBloc() : super(HealthInitial()) {
    Health().configure(useHealthConnectIfAvailable: true);

    on<HealthEvent>((event, emit) async {
      switch (event) {
        case FetchData():
          await _fetchData(event, emit);
          break;
        case FetchSteps():
          await _fetchSteps(event, emit);
          break;
        case AuthorizeHealth():
          await _authorizeHealth(event, emit);
          break;
        case GetHealthConnectSdkStatus():
          await _getHealthConnectSdkStatus(event, emit);
          break;
      }
    });
  }

  List<HealthDataPoint> _healthDataList = [];
  AppState appState = AppState.DATA_NOT_FETCHED;
  int _nofSteps = 0;

  // All types available depending on platform (iOS ot Android).
  List<HealthDataType> get types => (Platform.isAndroid)
      ? dataTypesAndroid
      : (Platform.isIOS)
          ? dataTypesIOS
          : [];

  List<HealthDataAccess> get permissions => types.map((e) => HealthDataAccess.READ).toList();

  Future<void> _authorizeHealth(AuthorizeHealth event, Emitter<HealthState> emit) async {
    // If we are trying to read Step Count, Workout, Sleep or other data that requires
    // the ACTIVITY_RECOGNITION permission, we need to request the permission first.
    // This requires a special request authorization call.
    //
    // The location permission is requested for Workouts using the Distance information.
    emit(HealthAuthorizationInProgress());
    await Permission.activityRecognition.request();
    await Permission.location.request();

    // Check if we have health permissions
    bool? hasPermissions = await Health().hasPermissions(types, permissions: permissions);

    // hasPermissions = false because the hasPermission cannot disclose if WRITE access exists.
    // Hence, we have to request with WRITE as well.
    hasPermissions = false;

    bool authorized = false;
    if (!hasPermissions) {
      // requesting access to the data types before reading them
      try {
        authorized = await Health().requestAuthorization(types, permissions: permissions);
      } catch (error) {
        debugPrint("Exception in authorize: $error");
      }
    }

    if (authorized) {
      appState = AppState.AUTHORIZED;
      emit(HealthAuthorized());
    } else {
      appState = AppState.AUTH_NOT_GRANTED;
      emit(HealthNotAuthorized());
    }
    // setState(() => appState = (authorized) ? AppState.AUTHORIZED : AppState.AUTH_NOT_GRANTED);
  }

  Future<void> _fetchData(FetchData event, Emitter<HealthState> emit) async {
    // setState(() => appState = AppState.FETCHING_DATA);
    appState = AppState.FETCHING_DATA;
    emit(HealthDataFetchInProgress());
    // get data within the last 24 hours
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 48));

    // Clear old data points
    _healthDataList.clear();

    // try {
    // fetch health data
    List<HealthDataPoint> healthData = await Health().getHealthDataFromTypes(
      types: event.dataType,
      startTime: yesterday,
      endTime: now,
    );

    debugPrint('Total number of data points: ${healthData.length}. '
        '${healthData.length > 100 ? 'Only showing the first 100.' : ''}');

    // save all the new data points (only the first 100)
    _healthDataList.addAll((healthData.length < 100) ? healthData : healthData.sublist(0, 100));
    // } catch (error) {
    //   debugPrint("Exception in getHealthDataFromTypes: $error");
    // }

    // filter out duplicates
    _healthDataList = Health().removeDuplicates(_healthDataList);

    for (var data in _healthDataList) {
      print(data.toJson());
    }

    // update the UI to display the results
    if (_healthDataList.isNotEmpty) {
      appState = AppState.DATA_READY;
      emit(HealthDataFetched(_healthDataList));
    } else {
      appState = AppState.NO_DATA;
      emit(HealthDataFetchFailure('No data available'));
    }
    // setState(() {
    //   appState = _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
    // });
  }

  Future<void> _fetchSteps(FetchSteps event, Emitter<HealthState> emit) async {
    emit(StepsFetchInProgress());
    int? steps;

    // get steps for today (i.e., since midnight)
    final now = DateTime.now();
    final midnight = now.subtract(const Duration(hours: 8));

    bool stepsPermission = await Health().hasPermissions([event.dataType]) ?? false;
    if (!stepsPermission) {
      stepsPermission = await Health().requestAuthorization([event.dataType]);
    }

    if (stepsPermission) {
      try {
        steps = await Health().getTotalStepsInInterval(midnight, now);
      } catch (error) {
        debugPrint("Exception in getTotalStepsInInterval: $error");
      }

      debugPrint('Total number of steps: $steps');

      // setState(() {
      //   _nofSteps = (steps == null) ? 0 : steps;
      //   appState = (steps == null) ? AppState.NO_DATA : AppState.STEPS_READY;
      // });
      if (steps != null) {
        _nofSteps = steps;
        appState = AppState.STEPS_READY;
        emit(StepsFetched(steps));
      } else {
        appState = AppState.NO_DATA;
        emit(StepsFetchFailure('No data available'));
      }
    } else {
      appState = AppState.DATA_NOT_FETCHED;
      emit(StepsFetchFailure('Authorization not granted - error in authorization'));
      // debugPrint("Authorization not granted - error in authorization");
      // setState(() => appState = AppState.DATA_NOT_FETCHED);
    }
  }

  /// Install Google Health Connect on this phone.
  Future<void> installHealthConnect() async {
    await Health().installHealthConnect();
  }

  // getHealthConnectSdkStatus
  Future<void> _getHealthConnectSdkStatus(GetHealthConnectSdkStatus event, Emitter<HealthState> emit) async {
    assert(Platform.isAndroid, "This is only available on Android");

    final status = await Health().getHealthConnectSdkStatus();

    // setState(() {
    //   _contentHealthConnectStatus = Text('Health Connect Status: $status');
    //   appState = AppState.HEALTH_CONNECT_STATUS;
    // });

    _contentHealthConnectStatus = Text('Health Connect Status: $status');
    appState = AppState.HEALTH_CONNECT_STATUS;

    emit(HealthConnectSdkStatus());
  }

  Widget get _contentFetchingData => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
              padding: const EdgeInsets.all(20),
              child: const CircularProgressIndicator(
                strokeWidth: 10,
              )),
          const Text('Fetching data...')
        ],
      );

  Widget get _contentDataReady => ListView.builder(
      itemCount: _healthDataList.length,
      itemBuilder: (_, index) {
        HealthDataPoint p = _healthDataList[index];
        if (p.value is AudiogramHealthValue) {
          return ListTile(
            title: Text("${p.typeString}: ${p.value}"),
            trailing: Text(p.unitString),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
          );
        }
        if (p.value is WorkoutHealthValue) {
          return ListTile(
            title: Text(
                "${p.typeString}: ${(p.value as WorkoutHealthValue).totalEnergyBurned} ${(p.value as WorkoutHealthValue).totalEnergyBurnedUnit?.name}"),
            trailing: Text((p.value as WorkoutHealthValue).workoutActivityType.name),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
          );
        }
        if (p.value is NutritionHealthValue) {
          return ListTile(
            title: Text("${p.typeString} ${(p.value as NutritionHealthValue).mealType}: ${(p.value as NutritionHealthValue).name}"),
            trailing: Text('${(p.value as NutritionHealthValue).calories} kcal'),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
          );
        }
        return ListTile(
          title: Text("${p.typeString}: ${p.value}"),
          trailing: Text(p.unitString),
          subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
        );
      });

  final Widget _contentNoData = const Text('No Data to show');

  final Widget _contentNotFetched = const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text("Press 'Auth' to get permissions to access health data."),
    Text("Press 'Fetch Dat' to get health data."),
    Text("Press 'Add Data' to add some random health data."),
    Text("Press 'Delete Data' to remove some random health data."),
  ]);

  final Widget _authorized = const Text('Authorization granted!');

  final Widget _authorizationNotGranted = const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Authorization not given.'),
      Text('For Google Fit please check your OAUTH2 client ID is correct in Google Developer Console.'),
      Text('For Google Health Connect please check if you have added the right permissions and services to the manifest file.'),
      Text('For Apple Health check your permissions in Apple Health.'),
    ],
  );

  Widget _contentHealthConnectStatus = const Text('No status, click getHealthConnectSdkStatus to get the status.');

  final Widget _dataAdded = const Text('Data points inserted successfully.');

  final Widget _dataDeleted = const Text('Data points deleted successfully.');

  Widget get _stepsFetched => Text('Total number of steps: $_nofSteps.');

  final Widget _dataNotAdded = const Text('Failed to add data.\nDo you have permissions to add data?');

  final Widget _dataNotDeleted = const Text('Failed to delete data');

  Widget get content => switch (appState) {
        AppState.DATA_READY => _contentDataReady,
        AppState.DATA_NOT_FETCHED => _contentNotFetched,
        AppState.FETCHING_DATA => _contentFetchingData,
        AppState.NO_DATA => _contentNoData,
        AppState.AUTHORIZED => _authorized,
        AppState.AUTH_NOT_GRANTED => _authorizationNotGranted,
        AppState.DATA_ADDED => _dataAdded,
        AppState.DATA_DELETED => _dataDeleted,
        AppState.DATA_NOT_ADDED => _dataNotAdded,
        AppState.DATA_NOT_DELETED => _dataNotDeleted,
        AppState.STEPS_READY => _stepsFetched,
        AppState.HEALTH_CONNECT_STATUS => _contentHealthConnectStatus,
      };
}
