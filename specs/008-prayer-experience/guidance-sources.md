# Prayer guidance source map (T008)

Source/content review date: **2026-10-29**. References were opened and the relevant passages read. This file maps planned text roles, not shipped strings, a scholarly certification or implementation acceptance. T077 maps final AR/EN keys to these roles; T127 compares the final rendered wording with the sources and records the outcome.

## Boundaries

- The rak'ah badge describes ordinary **resident obligatory** prayer. Optional guidance is separate; it never changes the badge, report count or XP.
- Arabic intents below are short editorial paraphrases, not copied fatwas. English expresses the same meaning; it is not an official source translation.
- Keep the prototype's four groups and guidance roles. Do not copy universal-looking optional-prayer labels without qualification.
- No travel/combining/exemption mode, missed-prayer ruling, Witr report/award or school selector is added in 008. Asr's calculation setting is not a jurisprudential content selector.
- No Quran text is needed for these roles and none is generated or rewritten.

## Primary references

| ID | Source and passage checked | Editorial use/limit |
| --- | --- | --- |
| R1 | [Ibn Baz: كيفية جمع الصلوات في السفر](https://binbaz.org.sa/fatwas/6628/كيفية-جمع-الصلوات-في-السفر), opening answer distinguishes the three four-rak'ah prayers from Fajr and Maghrib. | Supports resident counts by this distinction; travel instructions are not added. |
| R2 | [Ibn Baz: كتاب الأذان، باب الجهر في المغرب](https://binbaz.org.sa/audios/3884/كتاب-الاذان-باب-الجهر-في-المغرب), opening commentary; later-rak'ah and quiet Dhuhr/Asr sections. | Recitation metadata, not an invalidity judgment. |
| R3 | [Dar al-Ifta, fatwa 8665: كيفية قضاء الصلاة من حيث الجهر بالقراءة والإسرار بها](https://www.dar-alifta.org/ar/Fatwa/Details/21959/كيفية-قضاء-الصلاة-من-حيث-الجهر-بالقراءة-والإسرار-بها), definition of Jahr/Sirr. | Definitions only; make-up rules/school differences do not become app report rules. |
| R4 | [Dar al-Ifta, fatwa 7054: حكم قضاء السنن الرواتب التابعة للصلوات المفروضة ووقت قضائها](https://dar-alifta.org/ar/fatwa/details/17725/حكم-قضاء-السنن-الرواتب-التابعة-للصلوات-المفروضة-ووقت-قضائها), regular voluntary prayer enumerations. | Fajr/Maghrib/Isha suggestions, with explicit recognition that enumerations vary. |
| R5 | [Ibn Baz: بيان الراتبة القبلية والبعدية للظهر ونافلة العصر](https://binbaz.org.sa/fatwas/12576/بيان-الراتبة-القبلية-والبعدية-للظهر-ونافلة-العصر), Dhuhr regular Sunnah versus Asr voluntary prayer. | Preserve this distinction in optional guidance. |

## Resident obligatory metadata and recitation roles

Shared role `residentFardRakahs`: source R1; values Fajr 2, Dhuhr 4, Asr 4, Maghrib 3, Isha 4. Use localized count plurals, not concatenated numbers.

| Planned role | Arabic meaning | English meaning | Reference |
| --- | --- | --- | --- |
| `fajrRecitation` | القراءة جهرية في الركعتين. | Aloud recitation in both rak'ahs. | R2 |
| `dhuhrRecitation`, `asrRecitation` | القراءة سرية. | Quiet recitation. | R2 |
| `maghribRecitation` | الجهر في الأوليين، والإسرار في الثالثة. | First two aloud; third quiet. | R2 |
| `ishaRecitation` | الجهر في الأوليين، والإسرار في الأخيرتين. | First two aloud; last two quiet. | R2 |

## Optional guidance roles

| Planned role | Arabic paraphrase intent | English paraphrase intent | Reference/review constraint |
| --- | --- | --- | --- |
| `fajrOptionalGuidance` | من السنن الراتبة ركعتان قبل الفجر. | Two regular Sunnah rak'ahs before Fajr. | R4; separate from obligatory rak'ahs. |
| `dhuhrOptionalGuidance` | من السنن المروية أربع قبل الظهر وركعتان بعدها. | A reported regular Sunnah pattern is four before Dhuhr and two after. | R5; not the only enumeration. |
| `asrOptionalGuidance` | ورد استحباب أربع قبل العصر بعد دخول وقته، وهي نافلة غير راتبة. | Four before Asr after its time begins are recommended voluntary prayer, not regular Sunnah. | R5; not obligatory or a regular Sunnah. |
| `maghribOptionalGuidance` | ركعتان راتبة بعد المغرب. | Two regular Sunnah rak'ahs after Maghrib. | R4 |
| `ishaOptionalGuidance` | ركعتان راتبة بعد العشاء. | Two regular Sunnah rak'ahs after Isha. | R4; the prototype's appended Witr prescription is not established by this mapping. No Witr controls in 008. |
| `optionalGuidanceContext` | إرشادات مختصرة للنوافل؛ تختلف بعض التفاصيل باختلاف المذاهب. | Brief voluntary-prayer guidance; some details differ between schools. | R4/R5; separate from report state. |

## Jahr/Sirr panels

| Planned role | Arabic paraphrase intent | English paraphrase intent | Source |
| --- | --- | --- | --- |
| `jahrPanelDefinition` | الجهر قراءة بصوت يسمعه من حول المصلي. | Aloud recitation can be heard by those nearby. | R3 definition section |
| `sirrPanelDefinition` | الإسرار قراءة بصوت خافت، وليس قراءة صامتة بالقلب وحده. | Quiet means a lowered voice, not only reading mentally. | R3 definition section |
| `guidanceScope` | توضيح عام لصفة القراءة المعتادة، لا حكم على صحة صلاة المستخدم. | General guidance on ordinary recitation, not a judgment on a user's prayer. | Editorial boundary informed by R2/R3. |

## Handoff to final content acceptance

1. Link every final ARB guidance key to one role above and its reference ID; validate AR/EN meaning together.
2. Keep resident/optional/recitation distinctions in visible copy and semantics. A link list alone is not a final string review.
3. T077 implements reviewed strings; T127 records final copy/theme/layout comparison. Both remain **pending** after this setup phase.
4. Review and record an exact source before adding a new prescription. Do not silently copy extra prototype claims.
