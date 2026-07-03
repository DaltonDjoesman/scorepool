import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const {
  flagCdnCrestUrl,
  resolveCrestUrl,
  iso2ForTeamId,
  displayCrestUrl,
  isSvgCrestUrl,
} = require("../lib/teamCrestEnrichment.js");

function assertEqual(actual, expected, label) {
  if (actual !== expected) {
    throw new Error(
      `${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

assertEqual(iso2ForTeamId("bra"), "BR", "iso2ForTeamId BRA");
assertEqual(
  flagCdnCrestUrl("br"),
  "https://flagcdn.com/w80/br.png",
  "flagCdnCrestUrl br",
);
assertEqual(
  resolveCrestUrl("MEX"),
  "https://flagcdn.com/w80/mx.png",
  "resolveCrestUrl MEX",
);
assertEqual(
  resolveCrestUrl("ENG"),
  "https://flagcdn.com/w80/gb-eng.png",
  "resolveCrestUrl ENG",
);
assertEqual(resolveCrestUrl("CPV"), "https://flagcdn.com/w80/cv.png", "resolveCrestUrl CPV");
assertEqual(
  displayCrestUrl("BRA", "https://crests.football-data.org/764.svg"),
  "https://flagcdn.com/w80/br.png",
  "displayCrestUrl replaces SVG",
);
assertEqual(
  displayCrestUrl("ARG", "https://crests.football-data.org/762.png"),
  "https://crests.football-data.org/762.png",
  "displayCrestUrl keeps PNG",
);
assertEqual(isSvgCrestUrl("https://x.org/a.svg"), true, "isSvgCrestUrl");
assertEqual(resolveCrestUrl("ZZZ"), null, "resolveCrestUrl unknown");

console.log("team crest enrichment smoke test passed");
