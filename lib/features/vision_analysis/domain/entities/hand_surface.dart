enum HandSurface {
  palm,
  back,
  unknown;

  static HandSurface fromNative(String? value) =>
      switch (value?.toLowerCase()) {
        'palm' => palm,
        'back' => back,
        _ => unknown,
      };

  String get label => switch (this) {
    palm => 'Palm side',
    back => 'Back side',
    unknown => 'Unknown',
  };
}
