// Reproduce prototype/src/utils/prayerTimes.ts with its pinned adhan JS 4.4.4.
// Install only into .dart_tool/prayer_reference_js before running this script.
import { readFileSync, writeFileSync } from 'node:fs';
import { CalculationMethod, Coordinates, PrayerTimes } from '../.dart_tool/prayer_reference_js/node_modules/adhan/lib/bundles/adhan.esm.js';

const methods = {
  egyptian: CalculationMethod.Egyptian,
  muslimWorldLeague: CalculationMethod.MuslimWorldLeague,
  ummAlQura: CalculationMethod.UmmAlQura,
  dubai: CalculationMethod.Dubai,
  northAmerica: CalculationMethod.NorthAmerica,
  kuwait: CalculationMethod.Kuwait,
  qatar: CalculationMethod.Qatar,
};
const source = JSON.parse(readFileSync('test/fixtures/prayer/calculation/aladhan_reference.json', 'utf8'));
const rows = source.map(row => {
  const [day, month, year] = row.date.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  const times = new PrayerTimes(new Coordinates(row.latitude, row.longitude), date, methods[row.method]());
  return {
    city: row.city,
    date: `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`,
    method: row.method,
    source: 'prototype/src/utils/prayerTimes.ts / adhan 4.4.4',
    utc: Object.fromEntries(['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'].map(name => [name, times[name].toISOString()])),
  };
});
writeFileSync('test/fixtures/prayer/calculation/prototype_parity.json', JSON.stringify(rows, null, 2) + '\n');
console.log(`Captured ${rows.length} prototype rows`);
