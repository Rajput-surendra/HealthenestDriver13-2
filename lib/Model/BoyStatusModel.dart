import 'dart:convert';
/// error : false
/// message : "Status Update Successfully"

BoyStatusModel boyStatusModelFromJson(String str) => BoyStatusModel.fromJson(json.decode(str));
String boyStatusModelToJson(BoyStatusModel data) => json.encode(data.toJson());
class BoyStatusModel {
  BoyStatusModel({
      bool? error, 
      String? message,}){
    _error = error;
    _message = message;
}

  BoyStatusModel.fromJson(dynamic json) {
    _error = json['error'];
    _message = json['message'];
  }
  bool? _error;
  String? _message;
BoyStatusModel copyWith({  bool? error,
  String? message,
}) => BoyStatusModel(  error: error ?? _error,
  message: message ?? _message,
);
  bool? get error => _error;
  String? get message => _message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['error'] = _error;
    map['message'] = _message;
    return map;
  }

}