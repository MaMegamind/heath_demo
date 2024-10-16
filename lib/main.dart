// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:health/health.dart';
// import 'package:heath_demo/bloc/health_bloc.dart';
//
// void main() => runApp(const HealthApp());
//
// // todo check for return model for android and ios
// // todo check how to send data us package for app
// class HealthApp extends StatelessWidget {
//   const HealthApp({super.key});
//
//   // UI building below
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => HealthBloc(),
//       child: BlocConsumer<HealthBloc, HealthState>(
//         listener: (context, state) {},
//         builder: (context, state) {
//           final bloc = BlocProvider.of<HealthBloc>(context);
//           return MaterialApp(
//             home: Scaffold(
//               appBar: AppBar(
//                 title: const Text('Health Demo'),
//               ),
//               body: Column(
//                 children: [
//                   Wrap(
//                     spacing: 10,
//                     children: [
//                       TextButton(
//                           onPressed: () {
//                             bloc.add(AuthorizeHealth());
//                           },
//                           style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
//                           child: const Text("Authenticate", style: TextStyle(color: Colors.white))),
//                       if (Platform.isAndroid)
//                         TextButton(
//                             onPressed: () {
//                               bloc.add(GetHealthConnectSdkStatus());
//                             },
//                             style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
//                             child: const Text("Check Health Connect Status", style: TextStyle(color: Colors.white))),
//                       TextButton(
//                           onPressed: () {
//                             bloc.add(FetchData(bloc.types));
//                           },
//                           style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
//                           child: const Text("Fetch Data", style: TextStyle(color: Colors.white))),
//                       TextButton(
//                           onPressed: () {
//                             bloc.add(FetchSteps(HealthDataType.HEART_RATE));
//                           },
//                           style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
//                           child: const Text("Fetch Step Data", style: TextStyle(color: Colors.white))),
//                       // TextButton(
//                       //     onPressed: revokeAccess,
//                       //     style: const ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.blue)),
//                       //     child: const Text("Revoke Access", style: TextStyle(color: Colors.white))),
//                       // if (Platform.isAndroid)
//                       //   TextButton(
//                       //       onPressed: installHealthConnect,
//                       //       style: const ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.blue)),
//                       //       child: const Text("Install Health Connect", style: TextStyle(color: Colors.white))),
//                     ],
//                   ),
//                   const Divider(thickness: 3),
//                   Expanded(child: Center(child: bloc.content))
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WhistleBox HR Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _heartRate = 0;
  final MethodChannel channel = const MethodChannel('com.example.watchApp');
  Future<void> sendDataToNative() async {
    // Send data to Native
    await channel.invokeMethod("flutterToWatch", {"method": "sendHRToNative", "data": _heartRate});
  }

  Future<void> _initFlutterChannel() async {
    channel.setMethodCallHandler((call) async {
      // Receive data from Native
      switch (call.method) {
        case "sendHRToFlutter":
          _heartRate = call.arguments["data"]["counter"];
          sendDataToNative();
          break;
        default:
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initFlutterChannel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF27C0C1),
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset("assets/logo.png", height: 50),
            SizedBox(
              height: 100,
            ),
            Text(
              '$_heartRate BPM',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 50,
            ),
            Text(
              'Personalize Your Mental Health State',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
