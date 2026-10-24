# Assets for TechLife 0.11.1

## 0.11.1 — original transparent tool icons

The eight tool photographs in the toolbar and repair hints are replaced by original generated stylized PNG icons under assets/repair/tools/*_icon.png. The built-in image generation tool was used; the first screwdriver icon anchors the visual style. The original hand and multimeter painter is unchanged. Prompt text is recorded in TOOL_ICONS_PROMPTS.json.

## 0.11 — corrected layered repair artwork

Fold7 and Mate XT now render clean_fold_chassis.png, original reference-guided game artwork created with the built-in image tool. Batteries are independent code-rendered elements, not pixels left inside a background. Classic photographic chassis exclude movable component regions; the photographed display-back images are no longer rendered because some contained fingers. Sources and constraints remain documented below. Generation prompts and the final workspace asset path are recorded in ASSET_PROMPTS_0_11.md. The new render is not a manufacturer service drawing.

## Current repair artwork, 0.9.0

The repair bench now embeds real, model-specific photographs. The old statement below that iFixit material is excluded describes version 0.7 only and does not apply to 0.9. Complete current credits, authors, guide URLs, licenses and modifications are in `assets/repair/SOURCES.txt`, bundled in the game and accessible from Settings → About → Image sources.

The original JPEG bytes are retained. Flutter draws perspective-corrected crops as body, battery, display-back and component textures, with separate interactive overlays. Seven classic models use iFixit guide photos; the new foldables use the cited iFixit splay, TechInsights image and Kingmi Mobile thumbnail. The Duo thumbnail is not a verified engineering drawing. Physical geometry, fasteners and cables remain simplified; guide callouts remain visible in some source images.

The eight tool photos and seven battery product-kit images are sourced from iFixit. The hand, multimeter, simulated OS screens, folding motion and control widgets are code-drawn game elements. New market images are the official Apple, Samsung and HUAWEI images linked in SOURCES.txt. The existing main launcher icon and four wallpapers are unchanged.

iFixit guide material and visual adaptations are CC BY-NC-SA 3.0. Commercial use requires the appropriate permission or replacement assets. Commercial redistribution rights for the other new photos have not been established. These notices must accompany redistributed material; this project is not endorsed by iFixit or the manufacturers.

`preview/09_*.png` and `preview/09_fold.gif` are exported from actual Flutter widgets. They are not concept renders. The OS is a local gameplay simulation, not manufacturer firmware.

## Historical artwork and UI, 0.7.0

The five marketplace screenshots supplied by the user are visual references for an interactive Flutter implementation. They are not used as full-screen backgrounds or click maps. All controls, text, prices, filters, forms, conversations and counters are native widgets backed by game state.

The current launcher icon is the user-supplied 20A2F7F6-9B8E-417C-890C-0D56F5065624.jpeg, converted to opaque PNG, adaptive Android foreground, maskable Web PNG and a seven-size Windows ICO. The marketplace banner is cropped from the upper device composition of that image. The three avatar JPEGs are small crops from the supplied messages design E516AB1D-46B0-4766-AC6B-CBEE2519DF58.jpeg and depict fictional game characters. Other portraits use original gradient initials. The bag/circuit marketplace mark is an original Flutter vector painter.

Product photos and facts for the seven smartphone models retain their sources below. The redesign does not relabel iPhone 13 as iPhone 13 Pro or Galaxy S23 as S23 Ultra. The techmarket PNGs in preview/ are actual Flutter widget captures from a test save.



## Previous launcher icon update, 0.6.0 history

The user supplied `CADB1EC7-6D5A-443B-89B6-5DF6194A560B.jpeg` as the exact replacement launcher artwork. Its composition and lettering are preserved. Only format conversion, resizing and safe padding were applied. `assets/icon/icon.png` is an opaque 1024×1024 PNG for iOS, legacy Android and the in-game About screen. `icon_fg.png` is a transparent adaptive Android layer with the artwork inset to preserve its lettering under launcher masks. `icon_maskable.png` is an opaque padded Web variant. `app_icon.ico` contains seven Windows icon sizes. Ready Web icons, favicon and bundled About-screen image are updated in `web_release/`.

`assets/repair/workshop.jpg` was created with the built-in image generation tool, using the user's workshop image as an atmosphere reference. It contains only the environment. All phone components, screws, circuit boards, highlights and interaction zones are rendered by Flutter code; the backdrop is not used as a click-map. The original generation was encoded to JPEG for this project's asset bundle.

Final background prompt:

> Use case: photorealistic-natural. Asset type: background art for a cross-platform 2D electronics repair game. Input image 1 is a reference for style and atmosphere only. Create a NEW wide 1536x1024 workshop background inspired by that image: beautiful premium but believable electronics repair desk in a small workshop, black perforated tool wall, precision screwdrivers on the back wall, subtle electric blue LED task light, shelves with spare parts, daylight city window on right, plant at left, wood desktop, dark silicone repair mat. Composition: camera is looking down at the large work surface at a steep 55 degree angle; the bottom 65 percent must be clear uncluttered EMPTY black silicone repair mat (large enough to draw an interactive phone onto it), with desk wood at its rim. Background occupies upper third. Put stationery, tiny drawers, tools and folded blue microfiber cloth only along far edges. Photorealistic physically plausible materials, soft daylight mixed with cool task light, sharp but restrained, high-end indie game art. Critical: absolutely NO phones, screens, laptops, device components or loose screws on the central mat; no people, hands, text, lettering, logos, watermarks, HUD, buttons, overlays or UI anywhere. No baked-in game interface. The playable device will be rendered by game code. Match reference's blue/warm wood/charcoal palette.

`assets/fonts/` contains Roboto Regular and Bold from the Flutter SDK's material fonts bundle, with its license. Geo assets are retained from the uploaded project.

`preview/repair_desktop.png` and `preview/repair_mobile.png` are screenshots rendered from the actual Flutter workbench widget at the battery-disconnection stage of practice mode.


## Marketplace images

Six photographs and one Pixel 7 model illustration were retrieved from Wikimedia Commons. No photograph is represented as evidence of the condition or color of a fictional in-game listing. Pixel 7 is explicitly identified as an illustration in its credit dialog.

Per-file metadata, the source page, author, license URL and modifications are included in `assets/market/sources.json`. The same credit is accessible from each listing detail screen. The modified CC BY-SA images remain CC BY-SA 4.0; the iPhone 13 image remains CC BY 2.0. These notices must travel with redistributed image assets.

| Asset | Creator | License | Source |
| --- | --- | --- | --- |
| `assets/market/iphone11.jpg` | Ahmadkurdi44 | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) | [IPhone_11_all_color.jpg](https://commons.wikimedia.org/wiki/File:IPhone_11_all_color.jpg) |
| `assets/market/iphone12.jpg` | 茅野ふたば | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) | [IPhone_12_Green_128g.jpg](https://commons.wikimedia.org/wiki/File:IPhone_12_Green_128g.jpg) |
| `assets/market/iphone13.jpg` | Tatsuo Yamashita (yto) | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/) | [IPhone_13_for_Tora_(52641558635).jpg](https://commons.wikimedia.org/wiki/File:IPhone_13_for_Tora_%2852641558635%29.jpg) |
| `assets/market/iphone15pro.jpg` | 茅野ふたば | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) | [IPhone_15_Pro_20240225.jpg](https://commons.wikimedia.org/wiki/File:IPhone_15_Pro_20240225.jpg) |
| `assets/market/galaxys22.jpg` | Hajoon0102 | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) | [Back_of_the_Samsung_Galaxy_S22.jpg](https://commons.wikimedia.org/wiki/File:Back_of_the_Samsung_Galaxy_S22.jpg) |
| `assets/market/galaxys23.jpg` | Hajoon0102 | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) | [Back_of_the_Samsung_Galaxy_S23.jpg](https://commons.wikimedia.org/wiki/File:Back_of_the_Samsung_Galaxy_S23.jpg) |
| `assets/market/pixel7.jpg` | Mliu92; Iketsi | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) | [Google_Pixel_7_back_(Snow).svg](https://commons.wikimedia.org/wiki/File:Google_Pixel_7_back_%28Snow%29.svg) |

Changes: all images were resized, oriented and JPEG-encoded. The Galaxy S23 group photo was cropped to the regular S23 on the right; the iPhone 15 Pro photo was cropped around the device. The Pixel SVG was obtained through its Wikimedia raster rendering. Detailed modification statements are in the JSON credits.

## Original internal components — historical 0.7.0

`lib/core/repair/device_profile.dart` defines separate service-side component coordinates for all seven models. `lib/ui/repair/model_artwork.dart` renders original vector art: battery pouches, camera lenses, logic boards, charging daughterboards, metal shields, wireless charging assemblies, connectors and flex cables. No iFixit photograph, diagram, page text or logo is shipped. Geometry and broad physical facts were researched from the following teardown guides; iFixit's CC BY-NC-SA material is excluded because this project is intended for commercial distribution.

| Model | Research reference |
| --- | --- |
| iPhone 11 | https://www.ifixit.com/Guide/iPhone+11+Battery+Replacement/127450 |
| iPhone 12 | https://www.ifixit.com/Guide/iPhone+12+Battery+Replacement/140588 |
| iPhone 13 | https://www.ifixit.com/Guide/iPhone+13+Battery+Replacement/145896 |
| iPhone 15 Pro | https://www.ifixit.com/Guide/iPhone+15+Pro+Battery+Replacement/166394 |
| Galaxy S22 | https://www.ifixit.com/Guide/Samsung+Galaxy+S22+Battery+Replacement/163932 |
| Galaxy S23 | https://www.ifixit.com/Guide/Samsung+Galaxy+S23+Battery+Replacement/174225 |
| Pixel 7 | https://www.ifixit.com/Guide/Google+Pixel+7+Battery+Replacement/154680 |

The internal art is a game interpretation, not a photogrammetric scan or a complete physical repair procedure. Fasteners, shields, chip shapes and assembly operations are grouped and simplified. Samsung S22 is the Snapdragon variant; component revisions and regional hardware differences are not simulated. The public source pages are research references, not imported assets or endorsements.

Device specifications are summarized as short factual values; source links are stored in the device catalog and shown by the listing detail screen. Seller descriptions, names, prices and faults are original fictional game content. TechMarket is an original in-game name; the app uses a familiar classifieds layout and does not copy Avito's logo, source code or private listings.

`preview/phone_*.png`, `preview/market*.png` and `preview/interior_*.png` are captured from real Flutter widgets by the supplied tests. They are not AI mockups.

## 0.8.0 — материалы пользователя

- assets/icon/techmarket.png: присланная иконка-сумка из IMG_0091.jpeg. Убраны поля и обрезок соседнего текста; знак сохранён и размещён на светлом фоне. Это иконка приложения внутри игры; основной launcher TechLife прежний.
- assets/wallpapers/peach.jpg, blue.jpg, teal.jpg, lavender.jpg: четыре присланных JPEG, скопированы без изменения изображения. Работают без сетевой загрузки.
- Источник этих пяти файлов — вложения пользователя от 24.10.2026. Коммерческие права не проверялись; происхождение и разрешения нужно подтвердить перед публичным выпуском.

preview/08_*.png: снимки действующих Flutter-виджетов с тестовым сохранением, не дизайн-макеты и не фотографии чужого устройства.


## Luma — 0.12.0

assets/icon/luma.jpg — изображение логотипа, предоставленное пользователем, скопировано без изменения. Макеты использованы как визуальные ориентиры, не как фон с невидимыми кнопками. Карты, чип, ленты и малая эмблема на карте нарисованы средствами Flutter, без внешних банковских ассетов.
