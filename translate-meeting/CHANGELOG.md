# Changelog

## v3 — DOM extraction (current)

**Extraction method:** single `javascript_tool` call reads `.joynote-slate-editor-container` directly, parses turns, merges consecutive same-speaker utterances, and returns a clean `speaker|HH:MM:SS|text` stream.

### Measured against v1 (scroll-and-scrape) on a 29-minute meeting:

| Dimension | v1 — scroll + screenshot | v3 — DOM extraction |
|---|---|---|
| **Tool round-trips** | 20–40 (scroll, screenshot, re-read) | **2** (tab switch + one JS call) |
| **Total input tokens** | ~60k–150k (vision frames or repeated page text) | **~14k** |
| **Wall-clock extraction time** | 1–3 minutes | **~10 seconds** |
| **Completeness** | Virtual-list recycling and scroll boundaries could silently drop content | Full transcript in one pass; never partial |
| **Speaker attribution** | Inferred from OCR / regex over jammed text | Read directly from the DOM structure |
| **Failure mode** | Silent data loss on long meetings | Hard error if selectors change — no silent corruption |
| **Translation quality** | Turn-boundary hallucinations, degradation in the back half of long meetings | Stable across length |

### Measured against v2 (`get_page_text`) on the same meeting:

| Dimension | v2 — `get_page_text` | v3 — DOM extraction |
|---|---|---|
| **Raw character count** | 14,975 (`body.innerText`) up to 701,878 (`html.textContent`) | **14,100** |
| **Structure** | Flat text, turns concatenated with no separators, timestamps glued to speech | `speaker\|HH:MM:SS\|text` pipe-delimited |
| **Noise included** | AI summary, chapter breakdowns, to-dos, footer marketing copy, `<script>` bodies, JAQ analytics | **Zero noise** |
| **Input token savings** | baseline | **~17 %**, roughly 1.5–2k fewer input tokens per run |
| **Worst-case cost blow-up** | 50× if `html.textContent` is used by mistake | Not possible — scoped to the transcript container |

### Why v3 wins (beyond the numbers)

The real gain is **structural, not financial**. v1 and v2 both hand the model unstructured text and ask it to infer turn boundaries and speaker attribution. That inference fails silently on long meetings — turns get merged, speakers get swapped, and the translator produces confident-sounding output from corrupted input. v3 extracts the structure the page already has, so the model never has to guess.

- v1's bottleneck was **interaction count** — every scroll was a round-trip and the virtual list could drop rows before they were read.
- v2's bottleneck was **signal-to-noise** — half the input was chrome, AI summary, and script content.
- v3 reduces extraction to a single DOM read over the authoritative source.

---

## v2 — API interception (never shipped)

**Attempted method:** intercept the three `api.m.jd.com/api?functionId=minutes.*` responses (`meetingrecord.query`, `speakers.timelines`, `detail`) via `read_network_requests`.

**Why abandoned:** `read_network_requests` only exposes URL, method and status — not response bodies. There is no way to recover the transcript JSON from the network layer. Kept as a cautionary note in `SKILL.md` so future maintainers don't re-try this path.

---

## v1 — scroll-and-scrape (original)

**Method:** drive the `computer` tool to scroll the transcript panel incrementally, reading page text or screenshots between scrolls and stitching the fragments together.

**Known problems:**
- 20–40 tool round-trips per meeting; wall-clock 1–3 minutes before translation could even begin.
- Virtual-list recycling dropped rows silently on long meetings.
- Screenshot OCR and `get_page_text` both lost turn boundaries, forcing the model to regex-split jammed timestamp-plus-text strings.
- Translation quality visibly degraded in the second half of long meetings because turn attribution drifted.
