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
      id: json['id'],
      authid: json['authid'],
      startupName: json['startupName'],
      description: json['description'],
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
