# Assets for TechLife 0.4.0

`assets/repair/workshop.jpg` was created with the built-in image generation tool, using the user's workshop image as an atmosphere reference. It contains only the environment. All phone components, screws, circuit boards, highlights and interaction zones are rendered by Flutter code; the backdrop is not used as a click-map. The original generation was encoded to JPEG for this project's asset bundle.

Final background prompt:

> Use case: photorealistic-natural. Asset type: background art for a cross-platform 2D electronics repair game. Input image 1 is a reference for style and atmosphere only. Create a NEW wide 1536x1024 workshop background inspired by that image: beautiful premium but believable electronics repair desk in a small workshop, black perforated tool wall, precision screwdrivers on the back wall, subtle electric blue LED task light, shelves with spare parts, daylight city window on right, plant at left, wood desktop, dark silicone repair mat. Composition: camera is looking down at the large work surface at a steep 55 degree angle; the bottom 65 percent must be clear uncluttered EMPTY black silicone repair mat (large enough to draw an interactive phone onto it), with desk wood at its rim. Background occupies upper third. Put stationery, tiny drawers, tools and folded blue microfiber cloth only along far edges. Photorealistic physically plausible materials, soft daylight mixed with cool task light, sharp but restrained, high-end indie game art. Critical: absolutely NO phones, screens, laptops, device components or loose screws on the central mat; no people, hands, text, lettering, logos, watermarks, HUD, buttons, overlays or UI anywhere. No baked-in game interface. The playable device will be rendered by game code. Match reference's blue/warm wood/charcoal palette.

`assets/fonts/` contains Roboto Regular and Bold from the Flutter SDK's material fonts bundle, with its license. Existing icon and geo assets are retained from the uploaded project.

`preview/repair_desktop.png` and `preview/repair_mobile.png` are screenshots rendered from the actual Flutter workbench widget at the battery-disconnection stage of practice mode.
