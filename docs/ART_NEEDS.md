# Art status (Sili Kids)

Source of the current pictures: the sticker sheet `Bunte_Tier-_und_Spiele-Stickerlandschaft.png`
(a real PNG with an alpha channel). `python3 tool/extract_sticker_sheet.py <sheet.png>` cuts it into
`assets/images/art/<name>.png` and writes `docs/art_preview.png` (every file on a checkerboard).
The app loads a picture with `ArtImage('<name>')`; if a file is missing the old drawing or emoji is shown.

## Ready (extracted, transparent PNG) and where it is used
| file | size px | used in |
|---|---|---|
| `sili_wave` | 246x258 | blue mascot everywhere (`SelyMascot`, default pose) |
| `sili_happy`, `sili_think` | 199x240, 186x251 | extracted, available through `SelyMascot(pose: ...)`, not placed on a screen yet |
| `sili_encourage` | 195x232 | result / celebration screen |
| `bunny_happy` | 175x254 | rabbit Arnoub: idle + happy (forest quest, map, home card) |
| `bunny_star` | 154x288 | rabbit cheering (level complete) |
| `bunny_think` | 142x276 | rabbit thinking / sad |
| `bunny_wave` | 151x272 | extracted, not used (see inconsistency below) |
| `cat_happy` | 170x218 | Feed the cat game |
| `bowl`, `strawberry`, `apple` | 251x134, 147x167, 168x179 | Feed the cat game |
| `star` | 163x163 | star counter, ratings, map stars (`StarArt`) |
| `panorama_banner` | 1524x271 | background of the home "adventure" card |
| `dog`, `chick`, `bird_blue`, `butterfly`, `gift_box`, `stars_group`, `strawberry_crate`, `shape_house` | ~150-230 | extracted, not placed on a screen yet |
| `sign_alef` | 191x178 | extracted. The letter is painted into the sign, so it only fits the letter alef |

## Known problems in the sheet
* **Bunny is not identical in all poses:** `bunny_happy` and `bunny_star` have a small flower on the ear,
  `bunny_wave` and `bunny_think` do not. The app uses the flower poses for everyday moods and `bunny_think`
  for thinking, so a flower appears and disappears. Regenerate wave + think with the flower.
* **Resolution:** every sticker is only ~150-290 px. That is fine up to ~80 dp (props, stars) and soft for the big
  characters (130 dp and more). For sharp characters regenerate them at 1024 px with the same style.
* No sleeping Sili: the sleeping mascot (rest screen) is still the drawn one.

## Still missing (needs new generated pictures)
Characters: `sili_sleep`, `bunny_wave` / `bunny_think` with the ear flower, `cat_sad_soft`, `squirrel`, `lamb`.
Props: `fish`, `plate`, `acorn`, `flower_red`, `flower_blue`, `flower_yellow`, `seed`, `treasure_chest`,
`wooden_board` (blank, no letter), `shape_triangle/square/circle` pieces, number-counting objects.
Backgrounds, portrait 1080x1920 and without characters: `bg_meadow`, `bg_forest`, `bg_garden`, and a tall
trail background for the letters map. The panorama is too wide and too small for a full portrait screen.
Animal sounds (audio) for the animal-sound game.

## Wording to use for the image generator (so the new pictures match)
> 3D cartoon character for a children's app, [CHARACTER AND POSE], same design as the reference sheet
> (glossy rounded toy look, soft studio lighting, big shiny eyes), plain solid bright green (#00FF00)
> background, no shadow, no text, full body, centered, 1024 px.

Only use pictures you have the right to use. This app is private; do not publish it with other people's
characters or watermarked pictures.
