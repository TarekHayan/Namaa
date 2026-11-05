// Reproduce source-attributed edge observations from the pinned PrayTimes.js.
// The source itself is downloaded into the ignored .dart_tool directory.
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const path = '.dart_tool/prayer_reference_js/PrayTimes.js';
const context = {};
vm.runInNewContext(readFileSync(path, 'utf8'), context, { filename: path });
const calculator = context.prayTimes;
calculator.setMethod('Egypt');
calculator.adjust({ asr: 'Standard', highLats: 'None' });

for (const item of [
  { name: 'zero_coordinates', date: [2026, 3, 20], coordinates: [0, 0], offset: 0 },
  { name: 'tromso_polar_day', date: [2026, 6, 21], coordinates: [69.6492, 18.9553], offset: 2 },
]) {
  const times = calculator.getTimes(item.date, item.coordinates, item.offset, 0, '24h');
  process.stdout.write(`${JSON.stringify({ ...item, times })}\n`);
}
