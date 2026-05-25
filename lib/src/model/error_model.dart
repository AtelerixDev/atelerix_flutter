// To parse this JSON data, do
//
//     final error = errorFromJson(jsonString);

import 'dart:convert';

ErrorModel errorFromJson(String str) => ErrorModel.fromJson(json.decode(str));

String errorToJson(ErrorModel data) => json.encode(data.toJson());

class ErrorModel {
  String? issue;
  List<String>? stack;
  Device? device;
  App? app;
  TimeZone? timeZone;
  String? createdAt;
  Map<String,dynamic>? meta;

  ErrorModel({
    this.issue,
    this.stack,
    this.device,
    this.app,
    this.timeZone,
    this.createdAt,
    this.meta,
  });

  ErrorModel copyWith({
    String? issue,
    List<String>? stack,
    Device? device,
    App? app,
    TimeZone? timeZone,
    String? createdAt,
    Map<String,dynamic>? meta,
  }) =>
      ErrorModel(
        issue: issue ?? this.issue,
        stack: stack ?? this.stack,
        device: device ?? this.device,
        app: app ?? this.app,
        timeZone: timeZone ?? this.timeZone,
        createdAt: createdAt ?? this.createdAt,
        meta: meta ?? this.meta,
      );

  factory ErrorModel.fromJson(Map<String, dynamic> json) => ErrorModel(
    issue: json["issue"],
    stack: json["stack"]??[],
    device: json["device"] == null ? null : Device.fromJson(json["device"]),
    app: json["app"] == null ? null : App.fromJson(json["app"]),
    timeZone: json["timeZone"] == null ? null : TimeZone.fromJson(json["timeZone"]),
    createdAt: json["createdAt"],
    meta: json["meta"] ?? {},
  );

  Map<String, dynamic> toJson() => {
    "issue": issue,
    "stack": stack,
    "device": device?.toJson(),
    "app": app?.toJson(),
    "timeZone": timeZone?.toJson(),
    "createdAt": createdAt,
    "meta": meta??{},
  };
}

class App {
  String? name;
  String? package;
  String? version;
  String? buildNo;

  App({
    this.name,
    this.package,
    this.version,
    this.buildNo,
  });

  App copyWith({
    String? name,
    String? package,
    String? version,
    String? buildNo,
  }) =>
      App(
        name: name ?? this.name,
        package: package ?? this.package,
        version: version ?? this.version,
        buildNo: buildNo ?? this.buildNo,
      );

  factory App.fromJson(Map<String, dynamic> json) => App(
    name: json["name"],
    package: json["package"],
    version: json["version"],
    buildNo: json["buildNo"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "package": package,
    "version": version,
    "buildNo": buildNo,
  };
}

class Device {
  String? deviceName;
  String? arc;
  String? osName;
  String? osVersion;
  String? timeZone;
  String? countryCode;

  Device({
    this.deviceName,
    this.arc,
    this.osName,
    this.osVersion,
    this.timeZone,
    this.countryCode,
  });

  Device copyWith({
    String? deviceName,
    String? arc,
    String? osName,
    String? osVersion,
    String? timeZone,
    String? countryCode,
  }) =>
      Device(
        deviceName: deviceName ?? this.deviceName,
        arc: arc ?? this.arc,
        osName: osName ?? this.osName,
        osVersion: osVersion ?? this.osVersion,
        timeZone: timeZone ?? this.timeZone,
        countryCode: countryCode ?? this.countryCode,
      );

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    deviceName: json["deviceName"],
    arc: json["arc"],
    osName: json["osName"],
    osVersion: json["osVersion"],
    timeZone: json["timeZone"],
    countryCode: json["countryCode"],
  );

  Map<String, dynamic> toJson() => {
    "deviceName": deviceName,
    "arc": arc,
    "osName": osName,
    "osVersion": osVersion,
    "timeZone":timeZone,
    "countryCode":countryCode
  };
}



class TimeZone {
String? name;
String? countryCode;

TimeZone({
this.name,
this.countryCode,
});

TimeZone copyWith({
String? name,
String? countryCode,
}) =>
TimeZone(
name: name ?? this.name,
countryCode: countryCode ?? this.countryCode,
);

factory TimeZone.fromJson(Map<String, dynamic> json) => TimeZone(
name: json["name"],
countryCode: json["countryCode"],
);

Map<String, dynamic> toJson() => {
"name": name,
"countryCode": countryCode,
};
}
