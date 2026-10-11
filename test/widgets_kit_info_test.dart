import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_kit/widgets_kit.dart';

void main() {
  group('WidgetsKitInfo', () {
    test('fromMap constructs WidgetsKitInfo object from map', () {
      final data = {
        'family': 'medium',
        'kind': 'anotherKind',
        'widgetId': 1,
        'androidClassName': 'com.example.AnotherWidget',
        'label': 'Another Widget',
        'configuration': {'config': 'value'},
      };

      final info = WidgetsKitInfo.fromMap(data);

      expect(info.iOSFamily, 'medium');
      expect(info.iOSKind, 'anotherKind');
      expect(info.androidClassName, 'com.example.AnotherWidget');
      expect(info.androidLabel, 'Another Widget');
      expect(info.androidWidgetId, 1);
      expect(info.configuration, {'config': 'value'});
    });

    test('handle configuration', () {
      final data = {
        'family': 'medium',
        'kind': 'anotherKind',
        'widgetId': 1,
        'androidClassName': 'com.example.AnotherWidget',
        'label': 'Another Widget',
        'configuration': {'config': 'value'},
      };

      final info = WidgetsKitInfo.fromMap(data);

      expect(info.configuration, {'config': 'value'});
    });

    test('WidgetsKitInfo toString', () {
      final widgetsKitInfo = WidgetsKitInfo(
        iOSFamily: 'systemSmall',
        iOSKind: 'ParkingWidget',
        androidWidgetId: 1,
        androidClassName: 'com.example.MyWidget',
        androidLabel: 'My Widget',
        configuration: {'config': 'example'},
      );

      expect(
        widgetsKitInfo.toString(),
        'WidgetsKitInfo(iOSFamily: systemSmall, iOSKind: ParkingWidget, androidWidgetId: 1, androidClassName: com.example.MyWidget, androidLabel: My Widget, configuration: {config: example})',
      );
    });

    test('WidgetsKitInfo equality', () {
      final info1 = WidgetsKitInfo(
        iOSFamily: 'medium',
        iOSKind: 'anotherKind',
        androidWidgetId: 1,
        androidClassName: 'com.example.AnotherWidget',
        androidLabel: 'Another Widget',
      );

      final info2 = WidgetsKitInfo(
        iOSFamily: 'medium',
        iOSKind: 'anotherKind',
        androidWidgetId: 1,
        androidClassName: 'com.example.AnotherWidget',
        androidLabel: 'Another Widget',
      );

      final info3 = WidgetsKitInfo(
        iOSFamily: 'systemSmall',
        iOSKind: 'ParkingWidget',
        androidWidgetId: 1,
        androidClassName: 'com.example.MyWidget',
        androidLabel: 'My Widget',
      );

      expect(info1 == info2, true);
      expect(info1.hashCode, equals(info2.hashCode));
      expect(info1 == info3, false);
      expect(info1.hashCode, isNot(equals(info3.hashCode)));
    });
  });
}
