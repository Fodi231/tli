# Assets for TechLife 0.5.0

`assets/repair/workshop.jpg` was created with the built-in image generation tool, using the user's workshop image as an atmosphere reference. It contains only the environment. All phone components, screws, circuit boards, highlights and interaction zones are rendered by Flutter code; the backdrop is not used as a click-map. The original generation was encoded to JPEG for this project's asset bundle.

Final background prompt:

> Use case: photorealistic-natural. Asset type: background art for a cross-platform 2D electronics repair game. Input image 1 is a reference for style and atmosphere only. Create a NEW wide 1536x1024 workshop background inspired by that image: beautiful premium but believable electronics repair desk in a small workshop, black perforated tool wall, precision screwdrivers on the back wall, subtle electric blue LED task light, shelves with spare parts, daylight city window on right, plant at left, wood desktop, dark silicone repair mat. Composition: camera is looking down at the large work surface at a steep 55 degree angle; the bottom 65 percent must be clear uncluttered EMPTY black silicone repair mat (large enough to draw an interactive phone onto it), with desk wood at its rim. Background occupies upper third. Put stationery, tiny drawers, tools and folded blue microfiber cloth only along far edges. Photorealistic physically plausible materials, soft daylight mixed with cool task light, sharp but restrained, high-end indie game art. Critical: absolutely NO phones, screens, laptops, device components or loose screws on the central mat; no people, hands, text, lettering, logos, watermarks, HUD, buttons, overlays or UI anywhere. No baked-in game interface. The playable device will be rendered by game code. Match reference's blue/warm wood/charcoal palette.

`assets/fonts/` contains Roboto Regular and Bold from the Flutter SDK's material fonts bundle, with its license. Existing icon and geo assets are retained from the uploaded project.

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

## Original internal components

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
