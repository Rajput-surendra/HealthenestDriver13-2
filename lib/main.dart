import  'dart:async';
import 'dart:convert';
import 'package:deliveryboy_multivendor/Helper/string.dart';
import 'package:deliveryboy_multivendor/Screens/Dashboard.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:deliveryboy_multivendor/Screens/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'Helper/Session.dart';
import 'Helper/color.dart';
import 'Helper/constant.dart';
import 'Helper/push_notification_service.dart';
import 'Screens/Splash/splash.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
     Geolocator.openAppSettings();
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(myForgroundMessageHandler);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // status bar color
    systemNavigationBarColor: Colors.transparent,
  ));
  /*final pushNotificationService = PushNotificationService();
  pushNotificationService.initialise();*/


  bool _isNetworkAvail = true;

  CUR_USERID = await getPrefrence(ID);
  CUR_USERNAME = await getPrefrence(USERNAME);
  _determinePosition();
  if(CUR_USERID != null && CUR_USERNAME != null){
  FirebaseDatabase database = FirebaseDatabase.instance;
  print("Location/$CUR_USERID");
  DatabaseReference ref = FirebaseDatabase.instance.ref("Location/$CUR_USERID");

  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Vizzve App",
    notificationText:
        "Background notification for keeping the Vizzve App running in the background",
    notificationImportance: AndroidNotificationImportance.High,
    notificationIcon: AndroidResource(
        name: 'Vizzve Driver',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  bool success =
      await FlutterBackground.initialize(androidConfig: androidConfig);
  if (success) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await ref.set({
        "id": "$CUR_USERID",
        "name": "$CUR_USERNAME",
        "address": {
          "lat": "${position.latitude}",
          "long":"${position.longitude}"
        }
      });
    }
  }else {
    print("Driver Not available");
  }


  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        primarySwatch: primary_app,
        fontFamily: 'opensans',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => Splash(),
        '/home': (context) => Dashboard(),
      },
    );
  }
}

