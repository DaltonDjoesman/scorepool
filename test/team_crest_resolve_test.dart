import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/utils/team_crest_resolve.dart';

void main() {
  test('displayCrestUrl replaces SVG API crest with flagcdn PNG', () {
    expect(
      displayCrestUrl(
        teamId: 'CPV',
        apiCrest: 'https://crests.football-data.org/cape_verde.svg',
      ),
      'https://flagcdn.com/w80/cv.png',
    );
  });

  test('displayCrestUrl prefers flagcdn over football-data PNG', () {
    const png = 'https://crests.football-data.org/762.png';
    expect(
      displayCrestUrl(teamId: 'ARG', apiCrest: png),
      'https://flagcdn.com/w80/ar.png',
    );
  });

  test('displayCrestUrl keeps raster API crest when no flagcdn mapping', () {
    const png = 'https://crests.football-data.org/99999.png';
    expect(displayCrestUrl(teamId: 'XXX', apiCrest: png), png);
  });

  test('resolveCrestUrl maps WC2026 extras', () {
    expect(resolveCrestUrl('JOR'), 'https://flagcdn.com/w80/jo.png');
    expect(resolveCrestUrl('COD'), 'https://flagcdn.com/w80/cd.png');
  });
}
