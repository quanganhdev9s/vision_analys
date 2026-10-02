enum VisionValidationIssue {
  noHand,
  multipleHands,
  handTooSmall,
  handOutsideFrame,
  noFace,
  multipleFaces,
  faceTooSmall,
  faceOutsideFrame,
  faceNotForward,
  imageTooDark,
  imageTooBright,
  imageBlurry,
  unknown;

  static VisionValidationIssue fromNative(String value) => switch (value) {
    'NO_HAND' => noHand,
    'MULTIPLE_HANDS' => multipleHands,
    'HAND_TOO_FAR' => handTooSmall,
    'HAND_TOO_CLOSE_TO_EDGE' => handOutsideFrame,
    'NO_FACE' => noFace,
    'MULTIPLE_FACES' => multipleFaces,
    'FACE_TOO_FAR' => faceTooSmall,
    'FACE_TOO_CLOSE_TO_EDGE' => faceOutsideFrame,
    'FACE_NOT_FORWARD' => faceNotForward,
    'IMAGE_TOO_DARK' => imageTooDark,
    'IMAGE_TOO_BRIGHT' => imageTooBright,
    'IMAGE_BLURRY' => imageBlurry,
    _ => unknown,
  };

  String get message => switch (this) {
    noHand => 'No hand was detected. Keep one hand clearly visible.',
    multipleHands => 'Show only one hand in the frame.',
    handTooSmall => 'Move your hand closer to the camera.',
    handOutsideFrame => 'Keep the entire hand inside the frame.',
    noFace => 'No face was detected. Center your face in the frame.',
    multipleFaces => 'Keep only one face in the frame.',
    faceTooSmall => 'Move your face closer to the camera.',
    faceOutsideFrame => 'Keep your entire face inside the frame.',
    faceNotForward => 'Face the camera directly.',
    imageTooDark => 'Use brighter, even lighting.',
    imageTooBright => 'Reduce harsh or overexposed lighting.',
    imageBlurry => 'Hold the camera steady and retake the photo.',
    unknown => 'The image could not be validated.',
  };
}
