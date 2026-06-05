class Startup {
  int id;
  String? authid;
  String startupName;
  String description;
  String? validationReport;

  Startup({
    required this.id,
    this.authid,
    required this.startupName,
    required this.description,
    this.validationReport,
  });

  factory Startup.fromJson(Map<String, dynamic> json) {
    return Startup(
      id: json['id'] ?? 0,
      authid: json['authid'],
      startupName: json['startupName'] ?? json['startup_name'] ?? '',
      description: json['description'] ?? json['startup_description'] ?? '',
      validationReport: json['validationReport'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authid': authid,
      'startupName': startupName,
      'description': description,
      'validationReport': validationReport,
    };
  }
}
