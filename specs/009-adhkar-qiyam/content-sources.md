# Content sources review — Adhkar catalog v1 and Qiyam supplications (009)

**Status: pending owner review.** Every entry below carries `Status: pending owner
review`. The product owner reviews and approves each entry before it ships
(T073, FR-002). Items that fail review are removed, never rewritten. This file
is the input for `assets/religious/adhkar_catalog_v1.json` (T006).

Prepared by the implementing agent on 2026-11-09. The agent prepares the
comparison and the source checks; it does not approve anything.

## Method and sources

- **Comparison text (Arabic).** حصن المسلم للشيخ سعيد بن علي بن وهف القحطاني —
  the official book text as distributed on hisnmuslim.com. The machine-readable
  copy used for byte-level comparison is
  [Seen-Arabic/Morning-And-Evening-Adhkar-DB](https://github.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB)
  (MIT license, Arabic + English), whose Arabic wording and takhreej matched the
  official Hisn al-Muslim text for every relevant item.
- **Grading and takhreej checks.** dorar.net (الموسوعة الحديثية) entries fetched
  directly; the grading words are quoted verbatim from each entry, with the
  dorar URL. sunnah.com pages were fetched to confirm the collection and number;
  the first English words are quoted as identity proof.
- **Verification date:** 2026-11-09. Every linked URL was actually loaded during
  verification; nothing is attributed without an observed page.
- **Text identity rule.** The catalog must carry exactly the text approved here.
  The prototype's Arabic wording follows Hisn al-Muslim (full tashkeel, minor
  punctuation differences only, noted per item).

## Decisions required from the product owner (blocking T006)

### D1 — m9: the virtue/references belong to the 100-times form, the text is the 10-times form
The prototype's m9 text is the 10-times form (Hisn al-Muslim, "عشر مرات أو مرة
واحدة عند الكسل"), but its virtue ("عدل عشر رقاب، وكُتبت له مائة حسنة، ومُحيت عنه
مائة سيئة، وكانت له حرزاً من الشيطان") and its references (البخاري 3293، مسلم
2691) are the **100-times** virtue and references (Hisn al-Muslim lists exactly
that virtue under the 100-times entry, citing البخاري 3293 ومسلم 2691). Hisn
al-Muslim's own 10-times virtue is "كان كمَن أعتق أربعة أنفس من ولد إسماعيل"
(البخاري 6404، مسلم 2693، النسائي في عمل اليوم والليلة 24).
Options:
  1. Keep the 10-times text and align its virtue to the 10-times wording
     ("كأنه من أعتق أربعة أنفس من ولد إسماعيل") with references البخاري 6404،
     مسلم 2693 (this is Hisn al-Muslim's own pairing; مسلم 2693 graded صحيح,
     https://dorar.net/hadith/sharh/15928) — recommended.
  2. Switch the item to the 100-times form (target 100), keeping the
     prototype's virtue and references (البخاري 3293، مسلم 2691) — both are
     correct for that form.
  3. Keep the prototype as-is (10× text with the 100× virtue/references) — no
     single source carries this pairing.
  4. Remove m9.
  The morning-specific narration is a once-only form (أبو داود 5077، النسائي
  الكبرى 9855، ابن ماجه 3867، أحمد 16583؛ صحيح —
  https://dorar.net/h/xx5x7H5r/osoul); it does not support a ×10 target.

### D2 — m7/e7 "حسبي الله ×7" (أبو داود 5081): disputed attribution — the ×7 claim is graded weak/fabricated
Hisn al-Muslim's takhreej for the ×7 wording: "أخرجه ابن السني برقم 71 مرفوعاً،
وأبو داود موقوفاً 4/321 برقم 5081، وصحّح إسناده شعيب وعبدالقادر الأرناؤوط.
انظر: زاد المعاد 2/376" — i.e. Hisn carries it as a **mawqūf** (Abu al-Darda's
own statement) with a corrected isnad. The verification found on dorar:
1. الألباني، ضعيف أبي داود (5081): **«موضوع»** — "أخرجه أبو داود (5081) واللفظ
   له، وابن عساكر في تاريخ دمشق (36/149)"
   (https://dorar.net/h/yr4xL1jV?osoul=1).
2. ابن كثير: **«هذه زيادة غريبة… وهذا منكر»**
   (https://dorar.net/h/ORy9wcFN?osoul=1).
3. شعيب الأرناؤوط: **«رجاله ثقات، وفي متنه زيادة منكرة»**
   (https://dorar.net/h/OlXbDdU5/osoul).
No strengthening of أبو داود 5081 was found on dorar. sunnah.com shows the page
grade: Mawdu' (Fabricated) (Al-Albani) (https://sunnah.com/abudawud:5081).
Options:
  1. Remove m7/e7 (the "×7 suffices" claim has no sahih source) — recommended
     by the verification.
  2. Keep the text ×7 but reword the reference/virtue to describe it as a
     mawqūf of Abu al-Darda with the Arna'ut note (the Hisn al-Muslim choice),
     explicitly dropping the fabricated marfūʿ framing.
  3. Keep as-is in the prototype (not recommended by the verification).

### D3 — English translations: license source unresolved
The prototype's English strings match the widely circulated English translation
of Hisn al-Muslim ("Fortress of the Muslim") family — e.g., the official
[hisnmuslim.com](https://hisnmuslim.com) English text ("We have reached the
morning and at this very time unto Allah belongs all sovereignty…") with small
paraphrase differences ("at this very morning"). This family is not traceable to
a formally licensed dataset in the prototype. The open-source
[Seen-Arabic/Morning-And-Evening-Adhkar-DB](https://github.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB)
English set is **MIT-licensed** but is a different translation (for example it
renders السميع as "All-Seeing" in m4/e5, which is an error) and would need
corrections (permitted by MIT).
Options:
  1. Adopt the MIT Seen-Arabic translations and correct its errors ourselves
     (clean license, corrections allowed).
  2. Keep the prototype's wording and clear permission for the Hisn al-Muslim
     official English translation before shipping.
  3. Produce our own reviewed translation.
Copyrighted editions (for example Dar-us-Salam's printed edition) must not be
copied either way.

### D4 — Ayat al-Kursi and the Mu'awwidhat are absent from the prototype
Adding them would bring Quran text into the catalog (Constitution V), so it
needs an explicit owner decision. They are **not** in this draft; nothing was
added.

### D5 — e9 "اللهم صل وسلم على نبيينا محمد ×10": disputed grading
The prototype cites صحيح الترغيب والترهيب (656). The full picture:
- Hisn al-Muslim takhreej: "أخرجه الطبراني بإسنادين أحدهما جيد، انظر: مجمع
  الزوائد (10/120)، وصحيح الترغيب والترهيب (1/273) [برقم (656)]، وضعيف الترغيب
  والترهيب برقم: 396. وفي السلسلة الضعيفة برقم: 5788."
- Dorar (https://dorar.net/h/Zx6Sk8ey — opened): the entry is for the
  **Abu al-Darda narration** ("من صلَّى عليَّ حينَ يصبحُ عشرًا وحينَ يمسي عشرًا
  أدرَكتْهُ شفاعتي يومَ القيامةِ"), i.e. the al-Tabarani chain Hisn cites —
  المحدث: الألباني، المصدر: **السلسلة الضعيفة 5788**، خلاصة حكم المحدث:
  **ضعيف**. It is not a Tirmidhi-chain entry.
- The grading discussion (العِراقي حسنه/صححه مقابل ضعف الآخرين):
  https://islamqa.info/ar/answers/130213
- Note: sunnah.com's Jami` at-Tirmidhi 3601 is a different hadith ("لا حول ولا
  قوة إلا بالله"), so no sunnah.com Tirmidhi URL is cited for e9.
Options: keep with the prototype citation plus a "grading disputed" note;
replace the reference with Hisn's takhreej wording; or remove e9.

### D6 — s2 (Qunut): the prototype truncates the supplication
The prototype shows "…وَقِنِي شَرَّ مَا قَضَيْتَ…" with an ellipsis. The
canonical Hisn al-Muslim wording continues ("فَإِنَّكَ تَقْضِي وَلَا يُقْضَى
عَلَيْكَ…"). Decide whether the catalog ships the full canonical text or the
prototype's truncated display text. The truncated string is what the prototype
renders today.

### D7 — m5/e6 reference correction (verified defect)
The prototype cites أبو داود (5072). Verification shows Abu Dawud 5072 is a
**different wording** ("رَضِينَا بِاللَّهِ رَبًّا… رَسُولاً") graded **ضعيف** by
Al-Albani (https://sunnah.com/abudawud:5072). The app's wording matches
الترمذي 3389 (ثوبان), which Tirmidhi grades "حسن غريب من هذا الوجه"
(https://dorar.net/h/LZPsIFZb?osoul=1, https://sunnah.com/tirmidhi:3389).
Recommended reference: سنن الترمذي (3389). Same fix for e6.

### D8 — m3/e3 reference correction (verified defect) and the e3 evening wording question
Verified on the pages actually opened:
- https://sunnah.com/tirmidhi:3391 — its **morning** form ends «وَإِلَيْكَ
  الْمَصِيرُ» and its **evening** form ends «وَإِلَيْكَ النُّشُورُ» (Grade on
  page: Sahih; dorar entry for الترمذي 3391: «حسن»). So the prototype's
  reference "الترمذي (3391)" fits the **m3 morning wording ending النشور**
  only under Hisn al-Muslim's own pairing — Hisn's edition pairing differs
  from sunnah.com's displayed forms.
- https://sunnah.com/abudawud:5068 — morning ends «وَإِلَيْكَ النُّشُورُ» and
  its evening ends «وَإِلَيْكَ النُّشُورُ» as well (Grade: Sahih — Al-Albani).
  The prototype's claimed أبو داود (5071) is a different dhikr entirely (the
  m1 narration, https://sunnah.com/abudawud:5071).
- The app's **e3 evening wording ending «الْمَصِيرُ»** (the Hisn al-Muslim
  evening form) has verified sources found via the dorar search (opened via
  https://dorar.net/dorar_api.json?skey=«اللهم بك أمسينا وبك أصبحنا
  وإليك المصير»): البغوي، شرح السنة 3/120 («حسن»، both forms ending المصير)؛
  شعيب الأرناؤوط، تخريج شرح السنة 1325 («إسناده قوي»، both forms ending
  المصير)؛ ابن الملقن، ما تمس إليه الحاجة 122 («صحيح»، morning النشور /
  evening المصير)؛ ابن حجر، نتائج الأفكار 2/350 («صحيح غريب»، evening
  المصير)؛ الألباني، الكلم الطيب 20 («حسن صحيح») و صحيح ابن ماجه 3133
  («صحيح»، evening المصير). The exact sunnah.com primary-collection number
  for that wording variant was **not** verified by opening a page and is
  stated as unverified here.
Options:
  1. Keep the Hisn wording (e3 ends «الْمَصِيرُ») and correct the reference
     line to one of the verified takhreej sources above (for example
     "شرح السنة للبغوي (3/120)، وشعيب الأرناؤوط: إسناده قوي").
  2. Change the e3 text to sunnah.com's Tirmidhi 3391 evening wording
     (ending «النُّشُورُ») and keep the reference الترمذي (3391).
  3. Remove e3.
The text itself is not changed before the owner decides. m3's own fix (cite
أبو داود (5068) والترمذي (3391) for the morning wording, or keep Hisn's
pairing) is unchanged from the earlier verification.

### D9 — m10 reference refinement (verified)
The exact formula "أستغفر الله وأتوب إليه" at ×100 verbatim is **ابن ماجه
(3815)** (شعيب الأرناؤوط: صحيح — https://dorar.net/h/PurFNLto/osoul).
البخاري 6307 carries the exact phrase at "أكثر من سبعين مرة", and مسلم 2702
carries ×100 without "وأتوب إليه". Recommended reference line: "ابن ماجه (3815)
والبخاري (6307) ومسلم (2702)".

### D10 — e4: the ×3 count is in Tirmidhi, not in Muslim (verified)
Sahih Muslim's pages (https://sunnah.com/muslim:2708a,
https://sunnah.com/muslim:2708b — both opened; 2708b is numbered 2709a) carry
the narration and the scorpion-sting story **without the "three times" count**.
The ×3 evening count is in **Jami` at-Tirmidhi 3604b**
(https://sunnah.com/tirmidhi:3604b — opened): "من قال حين يمسي ثلاث مرات أعوذ
بكلمات الله التامات من شر ما خلق لم يضره حمة تلك الليلة", Grade on page:
**Sahih (Darussalam)** (Tirmidhi's comment on the chapter narration: hasan).
Proposed reference line: **"صحيح مسلم (2709) وسنن الترمذي (3604)"**. The owner
decides: accept the proposed reference, keep the prototype's "مسلم (2709)"
only, or cite the Hisn al-Muslim takhreej (أحمد 7898 والنسائي، عمل اليوم
والليلة 590) instead.

## Evening-only verifications (e4 and e9 — verified directly)

### e4 — أعوذ بكلمات الله التامات ×3
- Prototype reference: صحيح مسلم (2709). Verified on sunnah.com: the
  scorpion-sting hadith sits at Muslim 2708b/2709a
  (https://sunnah.com/muslim:2708a, https://sunnah.com/muslim:2708b); the
  "settles in a place" version is 2708a. Hisn al-Muslim's own takhreej is
  أحمد 7898 والنسائي في عمل اليوم والليلة 590 (انظر صحيح الترمذي 3/187 وصحيح ابن
  ماجه 2/266 وتحفة الأخيار ص45). Text matches Hisn al-Muslim exactly.
- Status: pending owner review (reference wording: recommend "صحيح مسلم
  (2709، وانظر صحيح الترمذي 3/187)" or the Hisn takhreej line).

### e9 — اللهم صل وسلم على نبيينا محمد ×10
- See D5 above. Text matches Hisn al-Muslim exactly; virtue matches Hisn's fadl.

## Morning list

### m1 — أصبحنا وأصبح الملك لله
- ID: m1 | List: morning | Position: 1 | Target: 1
- Arabic text (prototype, fully vocalized): «أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.»
- English (prototype): "We have reached the morning and at this very morning unto Allah belongs all sovereignty, and all praise is for Allah. None has the right to be worshipped except Allah, alone, without partner..." (truncated in the prototype — D3 applies to the full string)
- Virtue AR (prototype): استفتاح اليوم بتوحيد الله والاستعاذة من الكسل وعذاب القبر والنار.
- Virtue EN (prototype): Opening the day with affirmation of Tawheed and seeking refuge from laziness and punishment.
- Reference (prototype): صحيح مسلم (2723)
- Hisn al-Muslim comparison: matches Hisn (order 7) word for word except one
  comma after وَالْحَمْدُ لِلَّهِ (punctuation only). Hisn source: مسلم، 4/2088،
  برقم 2723.
- Grading check: dorar takhreej "أخرجه مسلم (2723)، والترمذي (3391)، وابن أبي
  شيبة (29276)، باختلاف يسير، وأحمد (4192) مختصراً"
  (https://dorar.net/h/jVMl1c0x/osoul). Adjacent chains: الهيثمي "إسناده جيد"
  (https://dorar.net/h/13QVLQ7P?osoul=1)، ابن حجر "إسناده حسن"
  (https://dorar.net/h/qh8rHNFb/osoul). No explicit dorar خلاصة حكم for the
  Muslim chain itself; being in Sahih Muslim it is inherently authentic, but no
  separate grading is attributed here.
  **Numbering note:** dorar's "الترمذي (3391)" reflects that edition's
  numbering. On sunnah.com's numbering the Ibn Mas'ud narration is
  **Jami` at-Tirmidhi 3390** (Grade: Sahih (Darussalam),
  https://sunnah.com/tirmidhi:3390 — opened), while sunnah.com's Tirmidhi
  3391 is the different "اللهم بك أصبحنا" hadith
  (https://sunnah.com/tirmidhi:3391 — opened).
- sunnah.com identity: https://sunnah.com/muslim:2723 (2723a is the evening
  wording "أمسينا وأمسى الملك لله…"; the morning wording is inside 2723b,
  https://sunnah.com/muslim:2723b). English: "Abdullah b. Mas'ud reported that
  when it was evening Allah's Messenger (ﷺ) used to supplicate: 'We entered
  upon evening and the whole Kingdom of Allah also entered upon evening…'"
- Discrepancies: none beyond the punctuation comma. The prototype's virtue is
  an editorial description (not a hadith quote) — acceptable as UI copy.
- Status: pending owner review.

### m2 — سيد الاستغفار
- ID: m2 | List: morning | Position: 2 | Target: 1
- Arabic text (prototype): «اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ.»
- English (prototype): "O Allah, You are my Lord, none has the right to be worshipped except You, You created me and I am Your servant... (Sayyid al-Istighfar)" (truncated in the prototype — D3)
- Virtue AR: سيد الاستغفار: من قالها موقناً بها حين يمسي فمات من ليلته دخل الجنة، وكذلك إذا أصبح.
- Virtue EN: The master invocation for forgiveness: whoever says it with firm faith and dies that day enters Paradise.
- Reference (prototype): صحيح البخاري (6306)
- Hisn comparison: matches Hisn (order 11) word for word. Hisn source: البخاري
  7/150 برقم 6306; Hisn's fadl includes both the day and night parts, matching
  the prototype's virtue (which covers the evening and adds "وكذلك إذا أصبح").
- Grading check: dorar — الحاكم، المستدرك 2/496 (3707): "هذا حديث صحيح
  الإسناد ولم يخرجاه"; التخريج "أخرجه البخاري (6306)، والترمذي (3393) باختلاف
  يسير" (https://dorar.net/h/kRS1w1MH/osoul).
- sunnah.com identity: https://sunnah.com/bukhari:6306 — "The most superior way
  of asking for forgiveness from Allah is: O Allah, You are my Lord, there is
  none worthy of worship except You…" (شداد بن أوس).
- Discrepancies: none.
- Status: pending owner review.

### m3 — اللهم بك أصبحنا
- ID: m3 | List: morning | Position: 3 | Target: 1
- Arabic text (prototype): «اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ.»
- English (prototype): "O Allah, by Your leave we have reached the morning and by Your leave we have reached the evening, by Your leave we live and die, and unto You is our resurrection."
- Virtue AR: تسليم الأمر لله في الحياة والموت والنشور.
- Virtue EN: Surrendering all affairs to Allah during life, death, and resurrection.
- Reference (prototype): سنن الترمذي (3391)
- Hisn comparison: matches Hisn (order 9) word for word (comma before وإليك
  differs — punctuation only). Hisn source: الترمذي 5/466 برقم 3391، وانظر
  صحيح الترمذي 3/142.
- Grading check: dorar — "خلاصة حكم المحدث: إسناده صحيح" (شعيب الأرناؤوط،
  تخريج سنن أبي داود رقم 5068); التخريج "أخرجه الترمذي (3391)، وابن ماجه
  (3868) باختلاف يسير، وأحمد (8649) مختصراً" (https://dorar.net/h/jETvRg4a).
- sunnah.com identity: https://sunnah.com/tirmidhi:3391 — grade Sahih
  (Darussalam); its morning text ends "وَإِلَيْكَ الْمَصِيرُ". The claimed
  "النشور" morning wording matches https://sunnah.com/abudawud:5068 exactly
  (Grade: Sahih — Al-Albani).
- Discrepancies: the prototype's claimed أبو داود (5071) is a different dhikr
  (the m1 narration). See D8 for the reference decision.
- Status: pending owner review (D8).

### m4 — بسم الله الذي لا يضر
- ID: m4 | List: morning | Position: 4 | Target: 3
- Arabic text (prototype): «بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلاَ فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.»
- English (prototype): "In the Name of Allah, with whose Name nothing can cause harm in the earth nor in the heavens, and He is the All-Hearing, the All-Knowing."
- Virtue AR: من قالها ثلاثاً إذا أصبح وثلاثاً إذا أمسى لم يضره شيء.
- Virtue EN: Whoever recites it three times morning and evening, nothing will harm them.
- Reference (prototype): سنن أبي داود (5088) والترمذي (3388)
- Hisn comparison: matches Hisn (order 20) word for word. Hisn takhreej adds
  ابن ماجه 3869 وأحمد 446؛ حسّن إسناده ابن باز في تحفة الأخيار ص39.
- Grading check: dorar — "خلاصة حكم المحدث: إسناده صحيح" (شعيب الأرناؤوط،
  تخريج رياض الصالحين ص1457); التخريج "أخرجه أبو داود (5088)، والترمذي (3388)،
  والنسائي في السنن الكبرى (10178)، وابن ماجه (3869)…"
  (https://dorar.net/h/P97w3pIx?osoul=1). Hadeeth Encyclopedia entry #6093:
  صحيح, same takhreej (https://hadeethenc.com/ar/browse/hadith/6093).
- sunnah.com identity: https://sunnah.com/abudawud:5088 — Grade: Sahih
  (Al-Albani); "If anyone says three times: 'In the name of Allah, when Whose
  name is mentioned nothing on Earth or in Heaven can cause harm…'".
  https://sunnah.com/tirmidhi:3388 — Tirmidhi: "هذا حديث حسن صحيح غريب".
- Discrepancies: none.
- Status: pending owner review.

### m5 — رضيت بالله ربا
- ID: m5 | List: morning | Position: 5 | Target: 3
- Arabic text (prototype): «رَضِيتُ بِاللَّهِ رَبّاً، وَبِالإِسْلاَمِ دِيناً، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيّاً.»
- English (prototype): "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad (peace and blessings be upon him) as my Prophet."
- Virtue AR: من قالها ثلاثاً حين يصبح وحين يمسي كان حقاً على الله أن يرضيه يوم القيامة.
- Virtue EN: Whoever says it 3 times morning and evening, Allah has promised to please them on the Day of Resurrection.
- Reference (prototype): سنن أبي داود (5072) والترمذي (3389)
- Hisn comparison: text matches Hisn (order 21) word for word. Hisn takhreej:
  أحمد 18967، والنسائي في عمل اليوم والليلة 4، وابن السني 68، وأبو داود 1531،
  والترمذي 3389؛ حسّنه ابن باز في تحفة الأخيار ص39.
- Grading check: dorar — الترمذي عن ثوبان: "خلاصة حكم المحدث: حسن غريب من هذا
  الوجه" (https://dorar.net/h/LZPsIFZb?osoul=1); the Abu Salamah chain (the
  Abu Dawud/Ibn Majah one): "وقع في إسناد هذا الحديث اختلاف" (ابن الملقن،
  https://dorar.net/h/ylhzTdTG?osoul=1).
- sunnah.com identity: https://sunnah.com/tirmidhi:3389 — matches the app's
  wording exactly ("Whoever says when he reaches the evening: I am pleased with
  Allah as (my) Lord…"). https://sunnah.com/abudawud:5072 is a different
  wording ("رَضِينَا بِاللَّهِ… رَسُولاً"), Grade: Da'if (Al-Albani).
- Discrepancies: the prototype's أبو داود (5072) points to the weak variant
  with different wording. See D7 for the recommended correction.
- Status: pending owner review (D7).

### m6 — سبحان الله وبحمده عدد خلقه
- ID: m6 | List: morning | Position: 6 | Target: 3
- Arabic text (prototype): «سُبْحَانَ اللَّهِ وَبِحَمْدِهِ: عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ.»
- English (prototype): "Glory is to Allah and praise is to Him, by the multitude of His creation, by His Pleasure, by the weight of His Throne, and by the ink of His Words."
- Virtue AR: تعدل ساعات طويلة من الذكر والتسبيح في الميزان والأجر.
- Virtue EN: Equals in weight hours of continuous remembrance and glorification.
- Reference (prototype): صحيح مسلم (2726)
- Hisn comparison: matches Hisn (order 31) word for word. Hisn source: مسلم
  4/2090 برقم 2726.
- Grading check: dorar — "خلاصة حكم المحدث: صحيح" (الألباني، صحيح الأدب المفرد
  503); التخريج "أخرجه البخاري في الأدب المفرد (647) بلفظه، ومسلم (2726)،
  والترمذي (3555) باختلاف يسير" (https://dorar.net/h/rpbZzibt?osoul=1).
- sunnah.com identity: https://sunnah.com/muslim:2726 (2726a) — "Juwairiya
  reported that Allah's Messenger (ﷺ) came out from (her apartment) in the
  morning…", includes وَزِنَةَ عَرْشِهِ exactly.
- Discrepancies: none. Note the prototype's virtue is an editorial description
  (the hadith's own fadl is longer); acceptable as UI copy.
- Status: pending owner review.

### m7 — حسبي الله ×7
- ID: m7 | List: morning | Position: 7 | Target: 7
- Arabic text (prototype): «حَسْبِيَ اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.»
- English (prototype): "Allah is sufficient for me. There is none worthy of worship but Him. I have placed my trust in Him, and He is the Lord of the Mighty Throne."
- Virtue AR: من قالها سبع مرات كفاه الله ما أهمه من أمر الدنيا والآخرة.
- Virtue EN: Whoever says it 7 times, Allah will suffice them against whatever concerns them in this world and the Hereafter.
- Reference (prototype): سنن أبي داود (5081)
- Hisn comparison: matches Hisn (order 17) word for word. Hisn takhreej: ابن
  السني 71 مرفوعاً، وأبو داود موقوفاً 4/321 برقم 5081؛ صحح إسناده شعيب
  وعبدالقادر الأرناؤوط؛ انظر زاد المعاد 2/376. Hisn fadl matches the prototype
  virtue.
- Grading check: dorar — three entries, all takhreej أبو داود (5081):
  الألباني «موضوع» (https://dorar.net/h/yr4xL1jV?osoul=1); ابن كثير «هذه زيادة
  غريبة… وهذا منكر» (https://dorar.net/h/ORy9wcFN?osoul=1); شعيب الأرناؤوط
  «رجاله ثقات، وفي متنه زيادة منكرة» (https://dorar.net/h/OlXbDdU5/osoul). No
  strengthening found on dorar.
- sunnah.com identity: https://sunnah.com/abudawud:5081 — text matches; page
  grade "Mawdu' (Fabricated) (Al-Albani)". English: "Abu al-Darda' said: if
  anyone says seven times morning and evening; 'Allah sufficeth me…'".
- Discrepancies: critical — the ×7 claim rests on weakly graded additions (see
  D2). The mawqūf itself, per Hisn's citation, has a corrected isnad (الأرناؤوط).
- Status: pending owner review (D2).

### m8 — سبحان الله وبحمده ×100
- ID: m8 | List: morning | Position: 8 | Target: 100
- Arabic text (prototype): «سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.»
- English (prototype): "Glory is to Allah and praise is to Him."
- Virtue AR: حُطت خطاياه وإن كانت مثل زبد البحر، ولم يأتِ أحد يوم القيامة بأفضل مما جاء به إلا أحد قال مثل ما قال أو زاد.
- Virtue EN: Sins are forgiven even if like foam of the sea, and no one brings better on Judgment Day except one who said similarly or more.
- Reference (prototype): صحيح مسلم (2691)
- Hisn comparison: text matches Hisn (order 34). Hisn source: مسلم 4/2071 برقم
  **2692** (the prototype says 2691 — see the pending check below). Hisn fadl
  matches the prototype's virtue wording.
- Grading check: dorar — الألباني «صحيح»; takhreej "أخرجه الترمذي (3466) واللفظ
  له، وأخرجه البخاري (6405)، ومسلم (2691) بلفظ: مائة مرة حطت خطاياه"
  (https://dorar.net/hadith/sharh/40346; the Muslim text at
  https://dorar.net/h/ihf75Mah/osoul).
- sunnah.com identity: https://sunnah.com/muslim:2691 — matches. "Abu Huraira
  reported Allah's Messenger (ﷺ) as saying: He who uttered these words…" and
  the hadith's ending includes the ×100 tasbih ("his sins are obliterated even
  if they are equal to the extent of the foam of the ocean").
- Discrepancies: none. The 2691-vs-2692 question is resolved: sunnah.com's
  Muslim 2691 contains both the ×100 tahlil and the ×100 tasbih endings; Hisn's
  "مسلم 2692" points to the second part of the same narration. The prototype's
  reference (2691) is correct.
- Status: pending owner review.

### m9 — لا إله إلا الله وحده لا شريك له ×10
- ID: m9 | List: morning | Position: 9 | Target: 10
- Arabic text (prototype): «لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.»
- English (prototype): "None has the right to be worshipped except Allah, alone, without partner. His is all sovereignty and praise, and He is over all things omnipotent."
- Virtue AR (prototype): كانت له عدل عشر رقاب، وكُتبت له مائة حسنة، ومُحيت عنه مائة سيئة، وكانت له حرزاً من الشيطان.
- Virtue EN (prototype): Equivalent to freeing slaves, 100 rewards written, 100 sins erased, and protection from Satan.
- Reference (prototype): صحيح البخاري (3293) ومسلم (2691)
- Hisn comparison: text matches Hisn's **10-times** entry (order 28) word for
  word. But the virtue and references above belong to Hisn's **100-times**
  entry (order 32): "من قالها مائة مرة في يوم كانت له عدل عشر رقاب، وكُتب له
  مائة حسنة… حرزاً من الشيطان يومه ذلك حتى يمسي" (البخاري 3293 ومسلم 2691).
  Hisn's own 10-times fadl: "عشر مرات أو مرة واحدة عند الكسل، ومن قالها عشر
  مرار كان كمَن أعتق أربعة أنفس من ولد إسماعيل" (البخاري 6404، مسلم 2693،
  النسائي في عمل اليوم والليلة 24).
- Grading check: what the cited numbers actually contain (sunnah.com):
  https://sunnah.com/bukhari:3293 — "If one says one-hundred times in one day…"
  «في يومٍ مائةَ مرّةٍ» with «عدل عشر رقاب… مائة حسنة… مائة سيئة… حرزًا من
  الشيطان يومه ذلك حتى يمسي» — the **100-times** form. https://sunnah.com/muslim:2691
  — the same 100-times form (plus the ×100 tasbih). The actual **×10** form is
  مسلم 2693 عن أبي أيوب "…عشرَ مرارٍ، كان كَمَن أعتَقَ أربَعةَ أنفُسٍ من ولدِ
  إسماعيل" — dorar «صحيح», takhreej "مسلم 2693… أخرجه البخاري (6404) باختلاف
  يسير" (https://dorar.net/hadith/sharh/15928;
  https://sunnah.com/muslim:2693). The morning-specific form is the **once**
  version: أبو داود (5077)، النسائي الكبرى (9855)، ابن ماجه (3867)، أحمد
  (16583)؛ الألباني «صحيح» (صحيح الجامع 6418)
  (https://dorar.net/h/xx5x7H5r/osoul).
- sunnah.com identity: quoted above.
- Discrepancies: critical (D1) — the prototype pairs the ×10 text with the 100×
  virtue/references; no single source carries that exact pairing. Hisn
  al-Muslim's own ×10 entry cites البخاري 6404، مسلم 2693، النسائي (عمل اليوم
  والليلة 24).
- Status: pending owner review (D1).

### m10 — أستغفر الله وأتوب إليه ×100
- ID: m10 | List: morning | Position: 10 | Target: 100
- Arabic text (prototype): «أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ.»
- English (prototype): "I seek the forgiveness of Allah and turn to Him in repentance."
- Virtue AR: كان النبي ﷺ يستغفر الله ويتوب إليه في اليوم أكثر من سبعين مرة وفي رواية مائة مرة.
- Virtue EN: The Prophet (pbuh) would seek forgiveness and repent to Allah 100 times a day.
- Reference (prototype): صحيح البخاري (6307) ومسلم (2702)
- Hisn comparison: text matches Hisn (order 33). Hisn source: البخاري (الفتح)
  11/101 [برقم 6307]، ومسلم 4/2075 [برقم 2702] — same numbers as the prototype.
- Grading check: dorar — two relevant entries:
  1. "والله إني لأستغفر الله وأتوب إليه في اليوم أكثر من سبعين مرة" — شعيب
     الأرناؤوط «إسناده صحيح» (تخريج صحيح ابن حبان 925); takhreej "البخاري
     (6307) — واللفظ له، الترمذي (3259) بزيادة، ابن ماجه (3815) — وفيه: مائة
     مرة بدل سبعين" (https://dorar.net/h/byxLn9aH/osoul).
  2. "إني لأستغفر الله وأتوب إليه في اليوم مائة مرة" (the exact ×100 wording) —
     شعيب الأرناؤوط «صحيح» (تخريج المسند 9807); takhreej "ابن ماجه رقم (3815)،
     وصحيح البخاري رقم (6307) بلفظ مغاير قليلاً"
     (https://dorar.net/h/PurFNLto/osoul).
- sunnah.com identity: https://sunnah.com/bukhari:6307 — "By Allah! I ask for
  forgiveness from Allah and turn to Him in repentance more than seventy times
  a day" (the exact phrase, but 70+ times). https://sunnah.com/muslim:2702a —
  "…I seek forgiveness from Allah a hundred times a day" («وَإِنِّي لأَسْتَغْفِرُ
  اللَّهَ فِي الْيَوْمِ مِائَةَ مَرَّةٍ» — ×100 but without «وأتوب إليه»).
- Discrepancies: the prototype's pairing overstates slightly — the exact
  formula at ×100 verbatim is ابن ماجه (3815) (صحيح). Recommended reference:
  "ابن ماجه (3815) والبخاري (6307) ومسلم (2702)" with a wording note. Recorded
  as D9.
- Status: pending owner review (D9).

## Evening list

### e1 — أمسينا وأمسى الملك لله
- ID: e1 | List: evening | Position: 1 | Target: 1
- Arabic text (prototype): «أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.»
- English (prototype): "We have reached the evening and at this very evening unto Allah belongs all sovereignty, and all praise is for Allah..." (truncated — D3)
- Virtue AR: استفتاح المساء بتوحيد الله واستعاذة من الشرور وعذاب القبر والنار.
- Virtue EN: Opening the evening with Tawheed and protection from evil and punishments.
- Reference (prototype): صحيح مسلم (2723)
- Hisn comparison: matches Hisn's evening entry (order 8) word for word. Same
  source as m1 (مسلم 2723); the evening wording is the 2723a display form on
  sunnah.com.
- Grading check: as m1.
- sunnah.com identity: as m1 (https://sunnah.com/muslim:2723).
- Discrepancies: none beyond punctuation.
- Status: pending owner review.

### e2 — سيد الاستغفار (evening)
- ID: e2 | List: evening | Position: 2 | Target: 1
- Arabic text (prototype): identical string to m2.
- English (prototype): "O Allah, You are my Lord, none has the right to be worshipped except You, You created me and I am Your servant... (Sayyid al-Istighfar)" (truncated — D3)
- Virtue AR: سيد الاستغفار: من قالها موقناً بها حين يمسي فمات من ليلته دخل الجنة.
- Virtue EN: The master prayer for forgiveness: whoever recites in the evening with certainty and passes away enters Paradise.
- Reference (prototype): صحيح البخاري (6306)
- Hisn comparison: Hisn's سيد الاستغفار entry (order 11) covers both the day
  and night sayings; the fadl explicitly includes the night case, matching the
  prototype's evening virtue. Same source as m2.
- Grading check: as m2.
- sunnah.com identity: as m2.
- Discrepancies: none.
- Status: pending owner review.

### e3 — اللهم بك أمسينا (evening)
- ID: e3 | List: evening | Position: 3 | Target: 1
- Arabic text (prototype): «اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ.»
- English (prototype): "O Allah, by Your leave we have reached the evening and by Your leave we have reached the morning, by Your leave we live and die, and unto You is our return."
- Virtue AR: الاعتراف بنعم الله عند حلول المساء وإرجاع كل أمر إليه.
- Virtue EN: Affirming Allah's blessings at evening and returning all matters to Him.
- Reference (prototype): سنن الترمذي (3391)
- Hisn comparison: matches Hisn's evening entry (order 10) word for word
  ("اللَّهمَّ بِكَ أمسَينا وبِكَ أصبَحنا وبِكَ نَحيا وبِكَ نموتُ، وإليكَ
  المصيرُ"). Hisn source: الترمذي 3391، صحيح الترمذي 3/142.
- Grading check: as m3 (the reference question is D8).
- sunnah.com identity: https://sunnah.com/tirmidhi:3391 — opened; its
  **evening** form ends «وَإِلَيْكَ النُّشُورُ» (its morning form ends
  «الْمَصِيرُ»). The app's evening wording ending «الْمَصِيرُ» is therefore
  **not** the sunnah.com Tirmidhi 3391 evening form.
- Verified sources for the exact evening wording (ending «الْمَصِيرُ»): the
  dorar search results listed under D8 — البغوي شرح السنة 3/120 («حسن»)؛
  شعيب الأرناؤوط، تخريج شرح السنة 1325 («إسناده قوي»)؛ ابن الملقن 122
  («صحيح»)؛ ابن حجر، نتائج الأفكار 2/350 («صحيح غريب»)؛ الألباني، الكلم الطيب
  20 («حسن صحيح») و صحيح ابن ماجه 3133 («صحيح»).
- Discrepancies: D8 — the prototype's reference points at a wording variant
  the app does not use for the evening form; the owner picks an option in D8.
- Status: pending owner review (D8).

### e4 — أعوذ بكلمات الله التامات ×3
- ID: e4 | List: evening | Position: 4 | Target: 3
- Arabic text (prototype): «أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.»
- English (prototype): "I seek refuge in the Perfect Words of Allah from the evil of what He has created."
- Virtue AR: من قالها حين يمسي ثلاث مرات لم تضره حُمَةٌ (لدغة عقرب أو سم أو أذى) تلك الليلة.
- Virtue EN: Whoever says it three times in the evening will not be harmed by any poison or sting that night.
- Reference (prototype): صحيح مسلم (2709)
- Hisn comparison: matches Hisn (order 30) word for word; Hisn fadl = the
  prototype virtue's first clause. Hisn takhreej: أحمد 2/290 برقم 7898،
  والنسائي في عمل اليوم والليلة 590، وابن السني 68؛ وانظر صحيح الترمذي 3/187
  وصحيح ابن ماجه 2/266 وتحفة الأخيار ص45.
- Grading check: Sahih Muslim's pages carry the narration without the ×3 count
  (https://sunnah.com/muslim:2708a — the "lands at a place" version; 
  https://sunnah.com/muslim:2708b — numbered 2709a, with the Abu Huraira
  scorpion-sting story; both opened). The **×3 count** is in Jami` at-Tirmidhi
  3604b (https://sunnah.com/tirmidhi:3604b — opened): "من قال حين يمسي ثلاث
  مرات… لم يضره حمة تلك الليلة", Grade on page: **Sahih (Darussalam)**. Hisn
  al-Muslim's own takhreej: أحمد 7898 والنسائي في عمل اليوم والليلة 590.
- sunnah.com identity: quoted above; see D10 for the reference decision.
- Discrepancies: D10 — the prototype's "مسلم (2709)" alone does not carry the
  ×3 count the app's target uses.
- Status: pending owner review (D10).

### e5 — بسم الله الذي لا يضر (evening)
- ID: e5 | List: evening | Position: 5 | Target: 3
- Arabic text (prototype): identical string to m4.
- English (prototype): identical string to m4.
- Virtue AR: حفظ ووقاية من فجاءة البلاء والأذى.
- Virtue EN: Complete protection and safety from sudden afflictions.
- Reference (prototype): سنن أبي داود (5088) والترمذي (3388)
- Hisn comparison: identical to m4 (Hisn lists it once, countable صباحاً
  ومساءً).
- Grading check: as m4 (إسناده صحيح).
- sunnah.com identity: as m4.
- Discrepancies: none.
- Status: pending owner review.

### e6 — رضيت بالله ربا (evening)
- ID: e6 | List: evening | Position: 6 | Target: 3
- Arabic text (prototype): identical string to m5.
- English (prototype): identical string to m5.
- Virtue AR: كان حقاً على الله أن يرضيه يوم القيامة.
- Virtue EN: Allah will surely please the reciter on the Day of Judgment.
- Reference (prototype): سنن أبي داود (5072)
- Hisn comparison: identical to m5.
- Grading check: as m5.
- sunnah.com identity: as m5.
- Discrepancies: D7 applies (same correction as m5).
- Status: pending owner review (D7).

### e7 — حسبي الله ×7 (evening)
- ID: e7 | List: evening | Position: 7 | Target: 7
- Arabic text (prototype): identical string to m7.
- English (prototype): identical string to m7.
- Virtue AR: كفاه الله ما أهمه من أمر الدنيا والآخرة.
- Virtue EN: Allah will suffice them from worries of this life and the Next.
- Reference (prototype): سنن أبي داود (5081)
- Hisn comparison: identical to m7 (Hisn carries it once for both times).
- Grading check: as m7 (موضوع عند الألباني؛ زيادة منكرة عند ابن كثير والأرناؤوط).
- sunnah.com identity: as m7.
- Discrepancies: D2 applies.
- Status: pending owner review (D2).

### e8 — سبحان الله وبحمده ×100 (evening)
- ID: e8 | List: evening | Position: 8 | Target: 100
- Arabic text (prototype): identical string to m8.
- English (prototype): identical string to m8.
- Virtue AR: حُطت خطاياه ولو كانت مثل زبد البحر.
- Virtue EN: Erases misdeeds and grants immense reward.
- Reference (prototype): صحيح مسلم (2691)
- Hisn comparison: identical to m8 (Hisn source مسلم 2692 — same open check as
  m8).
- Grading check: as m8 (صحيح — الألباني).
- sunnah.com identity: as m8.
- Discrepancies: none (resolved with m8: مسلم 2691 contains the ×100 tasbih).
- Status: pending owner review.

### e9 — اللهم صل وسلم على نبيينا محمد ×10
- ID: e9 | List: evening | Position: 9 | Target: 10
- Arabic text (prototype): «اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ.»
- English (prototype): "O Allah, send prayers and peace upon our Prophet Muhammad."
- Virtue AR: من صلى عليّ حين يصبح عشراً وحين يمسي عشراً أدركته شفاعتي يوم القيامة.
- Virtue EN: Whoever sends prayers upon the Prophet 10 times in morning and evening gains his intercession on Judgment Day.
- Reference (prototype): صحيح الترغيب والترهيب (656)
- Hisn comparison: matches Hisn (order 29) word for word; virtue matches Hisn's
  fadl exactly.
- Grading check: disputed — see D5. Opened pages:
  https://dorar.net/h/Zx6Sk8ey (الألباني، السلسلة الضعيفة 5788، لرواية أبو
  الدرداء: «ضعيف») and https://islamqa.info/ar/answers/130213 (the dedicated
  grading discussion of this exact hadith; the page's title confirms the
  text). The prototype's "صحيح الترغيب والترهيب (656)" is Albani's grading of
  a different chain (per Hisn's takhreej line).
- sunnah.com identity: no sunnah.com primary-collection URL verified (the
  Tirmidhi number cited elsewhere varies by edition; sunnah.com's tirmidhi:3601
  is a different hadith).
- Discrepancies: D5.
- Status: pending owner review (D5).

## Qiyam supplications (from prototype/src/views/QiyamView.tsx)

### s1 — دعاء الوتر
- ID: s1 | Usage: shown on the Qiyam screen's supplications card.
- Arabic text (prototype): «اللَّهُمَّ إِنِّي أَعُوذُ بِرِضَاكَ مِنْ سَخَطِكَ، وَبِمُعَافَاتِكَ مِنْ عُقُوبَتِكَ، وَأَعُوذُ بِكَ مِنْكَ، لاَ أُحْصِي ثَنَاءً عَلَيْكَ أَنْتَ كَمَا أَثْنَيْتَ عَلَى نَفْسِكَ»
- Source shown (prototype): صحيح مسلم (486) • كان النبي ﷺ يقوله في وتره أو سجوده.
- Hisn comparison: matches the standard Hisn al-Muslim دعاء الوتر wording.
- Grading check: dorar — Sahih Muslim hadith (Aisha); takhreej "أخرجه مسلم
  (486)… وأبو داود (879)، والترمذي (3493)، والنسائي، وأحمد (25757)"
  (https://dorar.net/h/v0EqThNt/osoul). No grading dispute found.
- sunnah.com identity: https://sunnah.com/muslim:486 — exact match including
  «لاَ أُحْصِي ثَنَاءً عَلَيْكَ أَنْتَ كَمَا أَثْنَيْتَ عَلَى نَفْسِكَ». English:
  "One night I missed Allah's Messenger (ﷺ) from the bed… they (feet) were
  raised and he was saying…".
- Discrepancies: none. Context is the Prophet's night prayer (the 11-rak'ah
  tahajjud hadith) — appropriate for the Qiyam screen.
- Status: pending owner review.

### s2 — دعاء القنوت (الحسن بن علي)
- ID: s2 | Usage: shown on the Qiyam screen's supplications card.
- Arabic text (prototype): «اللَّهُمَّ اهْدِنِي فِيمَنْ هَدَيْتَ، وَعَافِنِي فِيمَنْ عَافَيْتَ، وَتَوَلَّنِي فِيمَنْ تَوَلَّيْتَ، وَبَارِكْ لِي فِيمَا أَعْطَيْتَ، وَقِنِي شَرَّ مَا قَضَيْتَ...»
- Source shown (prototype): سنن أبي داود (1425) والترمذي (464) • دعاء قنوت الوتر المأثور عن الحسن بن علي رضي الله عنهما.
- Hisn comparison: matches the standard Hisn al-Muslim دعاء القنوت wording for
  the shown portion; the prototype truncates the end with "…" (D6).
- Grading check: dorar —
  1. شعيب الأرناؤوط (تخريج شرح السنة 640): «إسناده صحيح»; takhreej "أخرجه أبو
     داود (1425)، والترمذي (464)، والنسائي (1745)، والبغوي (640) واللفظ لهم"
     (https://dorar.net/h/OAyITxZa?osoul=1). Tirmidhi's comment there: «هذا
     حديث حسن… ولا نعرف عن النبي ﷺ في القنوت في الوتر شيئاً أحسن من هذا».
  2. الحاكم، المستدرك 4864: «صحيح على شرط الشيخين إلا أن محمد بن جعفر… قد خالف
     إسماعيل بن إبراهيم بن عقبة في إسناده»
     (https://dorar.net/h/cJQarbwJ?osoul=1).
  3. شعيب الأرناؤوط (تخريج مشكل الآثار 11/376): «حديث الحسن بن علي في القنوت
     صحيح، ولكن هذا الإسناد ضعيف» (one isnad variant weak; the hadith itself
     sahih via other paths) (https://dorar.net/h/QSWjweoi?osoul=1).
- sunnah.com identity: https://sunnah.com/abudawud:1425 — grade Sahih
  (Al-Albani); "Narrated Al-Hasan ibn Ali: The Messenger of Allah (ﷺ) taught me
  some words that I say during the witr…". https://sunnah.com/tirmidhi:464 —
  grade Sahih (Darussalam), Tirmidhi: «حَدِيثٌ حَسَنٌ».
- Discrepancies: the prototype truncates the end (D6). Wording variant note:
  Abu Dawud's Arabic text includes «وَلاَ يَعِزُّ مَنْ عَادَيْتَ» in the fuller
  version.
- Status: pending owner review (D6).

## Translation license summary

See D3. The prototype's English wording belongs to the circulating Hisn
al-Muslim English translation family with no documented license attached to the
prototype; the MIT-licensed Seen-Arabic set is available as an alternative
needing corrections. No translation is shipped until the owner picks an option.
