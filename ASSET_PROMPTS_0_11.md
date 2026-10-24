# Игровые ассеты 0.11

Режим: встроенный image generation, без CLI. Итоговый ассет: assets/repair/anatomy/clean_fold_chassis.png.

Референсы: прежние Fold7, Duo и Mate XT из assets/repair/anatomy; источники перечислены в SOURCES.txt. Это стилизованная фотореалистичная реконструкция, а не фотографическое доказательство точной компоновки.

Промпт 1: Create ONE high resolution game texture atlas with THREE horizontal rows, each row a complete straight-on orthographic opened phone chassis seen from service side, with ZERO perspective. TOP: Galaxy Z Fold7; MIDDLE: iPhone Duo; BOTTOM: HUAWEI Mate XT. Use the corresponding three reference images. Remove ALL batteries and leave empty silver/graphite wells; retain boards, cameras, shields, screws and ribbons. No humans, fingers, tools, captions, watermarks, annotations, white sheets or exploded components. Neutral lighting, dark charcoal background, photorealistic coherent materials.

Промпт 2: Edit this game texture atlas: retain the 3 chassis, empty battery wells, component arrangement, materials and crisp detail. Fix physical aspect ratios and use a portrait 1024x1536 canvas, three equal-height rows, taller panels and naturally circular cameras. Top about 500x490, middle about 700x490, bottom about 750x490, centered with charcoal margins. Redraw naturally rather than squash a raster. No batteries, loose parts, lettering or fingers; orthographic, no perspective.

Из полученного атласа игра выбирает нормализованные области для Fold7 и Mate XT. Модель Duo сохраняет прежнюю текстуру, но батарейные зоны исключаются из фона. Маски, независимые детали, проекция и контуры рисуются кодом.
