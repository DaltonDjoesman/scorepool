import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/utils/team_display.dart';

void main() {
  group('TeamDisplay', () {
    test('isPlaceholder detects TBD ids', () {
      expect(TeamDisplay.isPlaceholder('TBD_537390_H'), isTrue);
      expect(TeamDisplay.isPlaceholder('tbd_foo'), isTrue);
      expect(TeamDisplay.isPlaceholder(''), isTrue);
      expect(TeamDisplay.isPlaceholder('BRA'), isFalse);
    });

    test('label returns A definir for placeholders', () {
      expect(TeamDisplay.label('TBD_537390_H'), 'A definir');
      expect(TeamDisplay.label('BRA'), 'Brasil');
      expect(TeamDisplay.label('MEX'), 'México');
    });
  });
}
