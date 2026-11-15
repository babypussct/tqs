# Conservative art reconstruction — Hoàng Nguyệt Anh (84fe1819)

## Files

- `source-original.png` — untouched user-supplied source card, 744 × 1039 px, RGBA.
- `imagegen-candidate.png` — ImageGen's full reconstructed painting, 1061 × 1482 px, RGB. A generative interpretation, not a recovered original painting.
- `restoration-master-744.png` — native-resolution composite: original source pixels retained in verified unobstructed zones, with ImageGen filling obscured and transition areas.
- `restoration-mask.png` — opacity of retained source pixels in the master (white = source retained, black = ImageGen). Gray = feathered blending.
- **`huang-yueying-artwork-restored.png`** — chosen final full-bleed painting, 1488 × 2078 px, RGB PNG.
- `before-after.png` — source card and native-resolution restoration side by side.
- `hybrid-preview.png`, `preservation-mask-preview.png` — early test of the source-preserving composite; superseded by the chosen final mask.
- `qc-crops/` — four actual-pixel inspections from the final resolution: upper UI removal, face/hair, waist transition, and lower reconstructed fabric.

## Observed and reconstructed areas

The unobstructed center of the source is authoritative for the woman's face, silver hair, eyes, veil, headdress, upper robe and floral embellishments, extended hand, the bird at left, and the warm autumn forest. The final native-resolution master retains source pixels exactly in the mask's fully white areas, including inspected sample pixels on the **face**, **bird**, and **robe**. The final 2× PNG is resampled from that native master, so it cannot preserve those literal byte values after scaling.

Replaced material covers the **top number/title banner and Chinese characters**, the **left number/suit rail**, the **upper-right symbol**, **card borders**, the **translucent lower skills/text/statistics field**, and **bottom marks, numbers and copyright/UI logos**. The top foliage/branches and obscured portions of the tree are extrapolations. The bottom clothing, lap/skirt folds, right hand and scenery are inferred from portions faintly visible under the transparent overlay and from ImageGen; their details are **not proven original**. The output includes no intentional card graphics, printed text or watermark.

## Method and fidelity limits

1. Edited the attached source with the built-in ImageGen tool, requiring continuation of precisely the same female figure, bird, tree, style and lighting, while eliminating card UI.
2. Downsampled the generated candidate to 744 × 1039 px for compositing. Applied a spatial preservation mask to keep actual source pixels in undisturbed visible areas and fade into generated repairs around boundaries. Title, suit rail and lower text block were excluded from the source layer.
3. Saved the native master and 2× Lanczos-resampled final PNG, retaining the source portrait aspect ratio exactly. Upscaling adds **pixels**, not recovered original detail.

The mask's opacity-weighted contribution is approximately **30.66% original source and 69.34% ImageGen**, including transition blending. These percentages are an image-area metric, **not** an estimate of historical accuracy.

## Verification and outstanding uncertainty

- Source native size: **744 × 1039 px**; candidate **1061 × 1482 px**; final **1488 × 2078 px** (long edge exceeds 2048 px).
- Tested sample pixels: title, suit rail and text field have source opacity **0**; center face, bird and robe have source opacity **255** and are byte-for-byte equal to the source in `restoration-master-744.png`.
- Visual review of the full composition **and four full-resolution crop regions**: framing, readable Chinese text, card numbers/icons, watermark and translucent stats panel are absent; the woman, hair, bird and tree appear coherent. No obvious disjoint or unfilled masked rectangles were observed in the regions inspected. The final PNG decoded, had no blank alpha regions, and passed dimension/mode checks.
- Native high-resolution artwork was not independently located or verified. Exact details behind fully opaque UI are intrinsically unknowable from this source alone. The result should be treated as a **conservative reconstruction / fan edit**, not an authenticated extraction of the artist's unmodified original.
