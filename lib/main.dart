import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health/health.dart';
import 'package:heath_demo/bloc/health_bloc.dart';

void main() => runApp(const HealthApp());

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  // UI building below

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HealthBloc(),
      child: BlocConsumer<HealthBloc, HealthState>(
        listener: (context, state) {},
        builder: (context, state) {
          final bloc = BlocProvider.of<HealthBloc>(context);
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Health Demo'),
              ),
              body: Column(
                children: [
                  Wrap(
                    spacing: 10,
                    children: [
                      TextButton(
                          onPressed: () {
                            bloc.add(AuthorizeHealth());
                          },
                          style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                          child: const Text("Authenticate", style: TextStyle(color: Colors.white))),
                      if (Platform.isAndroid)
                        TextButton(
                            onPressed: () {},
                            style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                            child: const Text("Check Health Connect Status", style: TextStyle(color: Colors.white))),
                      TextButton(
                          onPressed: () {
                            bloc.add(FetchData(bloc.types));
                          },
                          style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                          child: const Text("Fetch Data", style: TextStyle(color: Colors.white))),
                      TextButton(
                          onPressed: () {
                            bloc.add(FetchSteps(HealthDataType.HEART_RATE));
                          },
                          style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                          child: const Text("Fetch Step Data", style: TextStyle(color: Colors.white))),
                      // TextButton(
                      //     onPressed: revokeAccess,
                      //     style: const ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.blue)),
                      //     child: const Text("Revoke Access", style: TextStyle(color: Colors.white))),
                      // if (Platform.isAndroid)
                      //   TextButton(
                      //       onPressed: installHealthConnect,
                      //       style: const ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.blue)),
                      //       child: const Text("Install Health Connect", style: TextStyle(color: Colors.white))),
                    ],
                  ),
                  const Divider(thickness: 3),
                  Expanded(child: Center(child: bloc.content))
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
