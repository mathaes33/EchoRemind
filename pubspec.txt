name: echo_remind
description: A context-aware reminder app that triggers notifications when a user arrives at or leaves a specified location.
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path_provider: ^2.1.2
  flutter_local_notifications: ^17.0.0
  Maps_flutter: ^2.5.3
  geofence_service: ^7.0.0
  purchases_flutter: ^7.5.1
  location: ^5.0.3
  provider: ^7.0.0
  intl: ^0.19.0
  permission_handler: ^11.3.0
  rxdart: ^0.27.7 # Added for BehaviorSubject in NotificationService and PurchaseService

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  sqflite_common_ffi: ^2.3.0 # For database unit testing

flutter:
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  # assets:
  #   - images/a_dot_burr.jpeg
  #   - images/a_little_bit_of_history.jpeg

  # For information on how to add assets in a package, see
  # https://flutter.dev/docs/cookbook/packaging/assets

  # An image asset can be specified name and a density independent path.
  # Assets are specified in "flutter" section under "assets" key.
  #
  # Example:
  # assets:
  #   - assets/my_icon.png
  #   - assets/my_text.txt

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font.
  #
  # Example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro_Regular.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/custom-fonts/#from-packages
