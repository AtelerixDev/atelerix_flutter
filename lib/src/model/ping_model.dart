import 'dart:convert';

PingModel pingModelFromJson(String str) => PingModel.fromJson(json.decode(str));

String pingModelToJson(PingModel data) => json.encode(data.toJson());

class PingModel {
  final String? id;
  final String? appId;
  final String? projectSlug;
  final String? platform;
  final String? status;
  final int? date;

  PingModel({
    this.id,
    this.appId,
    this.platform,
    this.projectSlug,
    this.status,
    this.date,
  });

  PingModel copyWith({
    String? id,
    String? appId,
    String? platform,
    String? projectSlug,
    String? status,
    int? date,
  }) =>
      PingModel(
        id: id ?? this.id,
        appId: appId ?? this.appId,
        platform: platform ?? this.platform,
        projectSlug: projectSlug ?? this.projectSlug,
        status: status ?? this.status,
        date: date ?? this.date,
      );

  factory PingModel.fromJson(Map<String, dynamic> json) => PingModel(
        id: json["id"],
        appId: json["appID"],
        platform: json["platform"],
        projectSlug: json["projectSlug"],
        status: json["status"],
        date: json["date"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "appID": appId,
        "platform": platform,
        "projectSlug":projectSlug,
        "status": status,
        "date": date,
      };
}
