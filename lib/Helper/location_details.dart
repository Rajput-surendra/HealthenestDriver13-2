
import 'package:deliveryboy_multivendor/Helper/string.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

import 'package:location/location.dart';

class GetLocation{
  LocationData? _currentPosition;

  late String _address = "";
  Location location1 = Location();
  String firstLocation = "",lat = "",lng = "";
//  ValueChanged onResult;

  GetLocation();
  Future<void> getLoc() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location1.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location1.requestService();
      if (!_serviceEnabled) {
        print('ek');
        return;
      }
    }

    _permissionGranted = await location1.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location1.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        print('no');
        return;
      }
    }

    location1.onLocationChanged.listen((LocationData currentLocation) async{
      print("${currentLocation.latitude} : ${currentLocation.longitude}");
      _currentPosition = currentLocation;print(currentLocation.latitude);
      FirebaseDatabase database = FirebaseDatabase.instance;
      print("Location/$CUR_USERID");
      DatabaseReference ref = FirebaseDatabase.instance.ref("Location/$CUR_USERID");
      await ref.set({
        "id": "$CUR_USERID",
        "name": "$CUR_USERNAME",
        "address": {
          "lat": "${_currentPosition!.latitude}",
          "long":"${_currentPosition!.longitude}"
        }
      });
    });
  }




}