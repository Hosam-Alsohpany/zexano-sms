enum Operator {
  yemenMobile,
  sabafon,
  you,
  yTelecom,
  unknown;

  String get displayName {
    return switch (this) {
      Operator.yemenMobile => 'YemenMobile',
      Operator.sabafon => 'Sabafon',
      Operator.you => 'YOU',
      Operator.yTelecom => 'YTelecom',
      Operator.unknown => 'Unknown',
    };
  }

  static Operator fromString(String value) {
    return switch (value.toLowerCase()) {
      'yemenmobile' => Operator.yemenMobile,
      'sabafon' => Operator.sabafon,
      'you' => Operator.you,
      'ytelecom' => Operator.yTelecom,
      _ => Operator.unknown,
    };
  }
}
