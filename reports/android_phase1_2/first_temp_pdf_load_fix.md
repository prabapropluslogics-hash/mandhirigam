# First Temp Book Original PDF load failure — diagnosis & fix

## Confirmed root cause

**pdfrx 1.0.84 `FileAccess` + progressive Range reads.**

1. Production reader used `PdfDocumentRefCustom` with the **default** `maxSizeToCacheOnMemory` (**1 MB**).
2. First Temp PDF is **5 380 261 bytes** → PDFium used **on-demand `FPDF_LoadCustomDocument`** and issued **hundreds of `GetBlock` calls** (matches ~356 DevTools GETs).
3. On any Dart exception inside the custom `read` callback, pdfrx sets the native return value to **`-1`**.
4. PDFium’s `m_GetBlock` contract is **non-zero = success**. `-1` is therefore treated as **success with an unfilled/dirty buffer**.
5. PDFium then fails to open/parse the document; the UI shows a generic “Could not open this PDF.” while DevTools still shows many HTTP **206**s.

HTTP 206 alone was never proof the document opened.

Same checksum/size as the working Thandhrigam book — the failure mode is **loader/adapter**, not a missing SHA-256.

## Chapter metadata (list API, live)

Book `6ae9f5bd360a5bdcd2e7307e` / chapter `6aea182e76bf708b45cc5f45`:

- `readerMode`: `ORIGINAL_PDF`
- `sha256`: `d9d6ebfaea32e221e9a4465980e4cd7feaee8a45dd186d3e8001eb1199d95231`
- `size`: `5380261`, `pageCount`: `33`
- `downloadPath`: `/api/v1/books/.../document`

Working book `6aead7cd76bf708b45cc60ab` shares the **same sha256/size**; `sourceName` still differs by book/chapter id.

Local `original.pdf` matches that SHA-256 and starts with `%PDF-1.7`.

## 356 requests

Expected under the old progressive path: many small PDFium `GetBlock` windows against a 5.1 MB file (including repeated offsets). Not inherently a duplicate-request bug; unsafe when any one call fails via the `-1` bridge bug.

After fix: in-memory open for files ≤ 25 MB, with **chunked** 256 KiB Range assembly (~21 GETs for this file).

## Fix (smallest correct change)

| File | Change |
| ---- | ------ |
| `authenticated_pdf_range_source.dart` | Chunked full-window fills; **return `0` on failure (never throw into FileAccess)**; PDF header check; request counters / `lastError` |
| `api_client.dart` | Reject **short** Content-Range; JSON detect via raw bytes (no UTF-8 decode of PDF) |
| `original_pdf_reader.dart` | `maxSizeToCacheOnMemory: document.size` when ≤ upload ceiling; safer dispose; precise debug logs |

Integrity validation, auth, and Range support preserved. No dependency upgrades.

## Tests

`flutter test test/pdf_range_source_test.dart test/chapter_reader_mode_test.dart` → **passed**  
Includes First Temp book/chapter fixture + incomplete Content-Range rejection.

`dart analyze` on touched files → **No issues found**

## APK

**Yes — a new debug/release build is required** to pick up the reader changes. Agent did not build APK/IPA.
