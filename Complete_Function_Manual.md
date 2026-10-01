# i18n_lib.prg — Manual Completo de Funciones (Bilingüe)

---

# TABLE OF CONTENTS / TABLA DE CONTENIDO

## ENGLISH
1. [Introduction](#english-introduction)
2. [Function Index](#english-function-index)
3. [Public API Functions](#english-public-api)
   - [InitI18n()](#en-init-i18n)
   - [SetLanguage()](#en-set-language)
   - [T()](#en-t)
   - [GetCurrentLanguage()](#en-get-current-language)
   - [GetAvailableLanguages()](#en-get-available-languages)
   - [GetTranslationHash()](#en-get-translation-hash)
   - [IsInitialized()](#en-is-initialized)
   - [GetCacheStats()](#en-get-cache-stats)
   - [ParseJsonDictionary()](#en-parse-json-dictionary)
4. [Private Helper Functions](#english-private-helpers)
   - [_DecodeUnicodeEscapes()](#en-decode-unicode)
   - [_IsValidHex()](#en-is-valid-hex)
   - [_HexToDecimal()](#en-hex-to-decimal)
   - [_UnicodeToChar()](#en-unicode-to-char)
   - [_SubstituteParams()](#en-substitute-params)
   - [_ToString()](#en-to-string)
   - [_ScanAvailableLanguages()](#en-scan-available-languages)
   - [_DefaultEnDictionary()](#en-default-en-dictionary)
5. [Appendix A: The Embedded English Dictionary — Complete Detail](#english-appendix-a)
6. [Appendix B: Advanced Topics — Detailed Explanations](#english-appendix-b)

## ESPAÑOL
1. [Introducción](#spanish-introduction)
2. [Índice de Funciones](#spanish-function-index)
3. [Funciones Públicas (API)](#spanish-public-api)
   - [InitI18n()](#es-init-i18n)
   - [SetLanguage()](#es-set-language)
   - [T()](#es-t)
   - [GetCurrentLanguage()](#es-get-current-language)
   - [GetAvailableLanguages()](#es-get-available-languages)
   - [GetTranslationHash()](#es-get-translation-hash)
   - [IsInitialized()](#es-is-initialized)
   - [GetCacheStats()](#es-get-cache-stats)
   - [ParseJsonDictionary()](#es-parse-json-dictionary)
4. [Funciones Auxiliares Privadas](#spanish-private-helpers)
   - [_DecodeUnicodeEscapes()](#es-decode-unicode)
   - [_IsValidHex()](#es-is-valid-hex)
   - [_HexToDecimal()](#es-hex-to-decimal)
   - [_UnicodeToChar()](#es-unicode-to-char)
   - [_SubstituteParams()](#es-substitute-params)
   - [_ToString()](#es-to-string)
   - [_ScanAvailableLanguages()](#es-scan-available-languages)
   - [_DefaultEnDictionary()](#es-default-en-dictionary)
5. [Apéndice A: El Diccionario Inglés Embebido — Detalle Completo](#spanish-appendix-a)
6. [Apéndice B: Temas Avanzados — Explicaciones Detalladas](#spanish-appendix-b)

---

<a name="english-introduction"></a>
# ENGLISH — Introduction

`i18n_lib.prg` is a production-ready internationalization (i18n) library for Harbour/MiniGUI Extended. It provides zero-dependency translation support using flat JSON dictionaries, with an embedded English fallback that guarantees the application never fails due to missing translation files.

**Key design principles:**
- **Zero dependencies** — uses only core Harbour string functions.
- **Zero DBF** — no database files required.
- **Robust JSON parser** — self-contained, always compiles and links.
- **Unicode support** — optional `\uXXXX` decoding with surrogate pair handling.
- **Performance cache** — translated keys without parameters are cached.
- **Embedded fallback** — a built-in English dictionary ensures operation even without external files.

---

<a name="english-function-index"></a>
# ENGLISH — Function Index

## Public API

| Function | Purpose |
|----------|---------|
| `InitI18n( cLang [, cPath] )` | Initialize with language |
| `SetLanguage( cLang )` | Switch language at runtime |
| `T( cKey [, xP1..xP9] )` | Translate key with params |
| `GetCurrentLanguage()` | Returns current language code |
| `GetAvailableLanguages()` | Returns array of available langs |
| `GetTranslationHash()` | Returns current hLang hash (clone) |
| `IsInitialized()` | Returns whether InitI18n() was called |
| `GetCacheStats()` | Returns cache performance statistics |
| `ParseJsonDictionary( cJson [, lDecodeUnicode] )` | Parse JSON dict |

## Private Helpers (internal use only)

| Function | Purpose |
|----------|---------|
| `_DecodeUnicodeEscapes( cText )` | Decode `\uXXXX` sequences to UTF-8 |
| `_IsValidHex( cHex )` | Validate 4-char hex string |
| `_HexToDecimal( cHex )` | Convert hex to decimal |
| `_UnicodeToChar( nCode )` | Convert code point to UTF-8 |
| `_SubstituteParams( cStr, xP1..xP9 )` | Replace `{n}` placeholders |
| `_ToString( xVal )` | Safe value-to-string conversion |
| `_ScanAvailableLanguages()` | Scan `/i18n/` folder for JSON files |
| `_DefaultEnDictionary()` | Return embedded English dictionary |

---

<a name="english-public-api"></a>
# ENGLISH — Public API Functions

---

<a name="en-init-i18n"></a>
## InitI18n()

Initializes the i18n library. Must be called once at application startup.

### Syntax
```
InitI18n( <cLang> [, <cPath>] ) --> lSuccess
```

### Arguments
- **`<cLang>`** — Language code (`"EN"`, `"ES"`, `"PT"`). Defaults to `"EN"` if `NIL`.
- **`<cPath>`** — Optional base path for `/i18n/` folder. Defaults to `GetStartUpFolder()`.

### Return
`.T.` on success, `.F.` on failure.

### Description
Entry point. Normalizes the language code, resolves the base path (strips trailing slashes), scans the `/i18n/` folder, loads the requested language via `SetLanguage()`, and sets `lInitialized` to `.T.` on success.

**If the requested language file is missing or invalid, the function falls back to the embedded English dictionary** (see [Appendix A](#english-appendix-a)) so the application never crashes at startup.

### Info
- **See also:** `SetLanguage()`, `IsInitialized()`
- **Category:** i18n functions, Initialization
- **Source:** `i18n_lib.prg`

### Example
```harbour
InitI18n( "EN" )                       // English, default path
InitI18n( "ES", "C:\MyApp" )          // Spanish, custom path
InitI18n()                             // English (implicit)
```

---

<a name="en-set-language"></a>
## SetLanguage()

Switches the active language at runtime.

### Syntax
```
SetLanguage( <cLang> ) --> lSuccess
```

### Arguments
- **`<cLang>`** — Language code. Must be one of `"EN"`, `"ES"`, `"PT"`; otherwise defaults to `"EN"`.

### Return
`.T.` on success (almost always — see description), `.F.` on failure.

### Description
1. Validates and normalizes the language code.
2. Constructs the path: `<cBasePath>\i18n\<lang>.json` (lowercase).
3. Reads the JSON via `MemoRead()`.
4. Parses with `ParseJsonDictionary()`.
5. Replaces `hLang` with the parsed data.
6. Clears the cache (`hKeyCache`), resets stats.
7. Sets date format: `ES`/`PT` → `DD/MM/YYYY`; else `MM/DD/YYYY`.

**Fallback behavior — WHEN `_DefaultEnDictionary()` IS CALLED:**

There are exactly **two call sites** in this function:

**Call Site 1 — Load failure (assigns to `hLang`):**
```harbour
IF ! lOk
   hLang        := _DefaultEnDictionary()
   cCurrentLang := "EN"
   lOk          := .T.
ENDIF
```
Triggered when `lOk` is still `.F.` after the `TRY...CATCH`, i.e.:
- JSON file does not exist, or
- File is empty / unreadable, or
- `ParseJsonDictionary()` returns an empty hash, or
- An exception occurred during read/parse.

**Call Site 2 — First-time fallback initialization (assigns to `hFallback`):**
```harbour
IF Len( hFallback ) == 0
   hFallback := _DefaultEnDictionary()
ENDIF
```
Triggered **only the first time** `SetLanguage()` is called (because `hFallback` starts as `{ => }`). Subsequent calls skip this because `hFallback` is already populated.

**⚠️ Silent language switch warning:** If the user requests `"ES"` and `es.json` is corrupt, the library **silently switches to English** and returns `.T.`. The caller cannot distinguish "Spanish loaded" from "English fallback active" from the return value alone. To detect this:
```harbour
SetLanguage( "ES" )
IF GetCurrentLanguage() != "ES"
   // Fallback was activated — notify or log
ENDIF
```

### Info
- **See also:** `InitI18n()`, `T()`, `GetCurrentLanguage()`, [Appendix A](#english-appendix-a)
- **Category:** i18n functions, Language management
- **Source:** `i18n_lib.prg`

### Example
```harbour
SetLanguage( "ES" )   // OK
SetLanguage( "PT" )   // OK
SetLanguage( "XX" )   // Invalid → normalizes to "EN"
```

---

<a name="en-t"></a>
## T()

Translates a key using the current language dictionary, with optional parameter substitution.

### Syntax
```
T( <cKey> [, <xP1>, <xP2>, ..., <xP9>] ) --> cTranslation
```

### Arguments
- **`<cKey>`** — Translation key (e.g., `"app.title"`). Returns `""` if `NIL`/empty.
- **`<xP1..xP9>`** — Optional parameters substituted for `{1}`..`{9}`.

### Return
Translated string. If key missing in current language, tries `hFallback` (English). If still missing, returns the raw key.

### Description
1. Empty key check.
2. **Cache lookup** — if no parameters, checks `hKeyCache` using key `"<lang>:<key>"`. Hit → return immediately (`nCacheHits++`).
3. **Dictionary lookup** — `hLang` first, then `hFallback`.
4. **Not found** — in `__DEBUG__` mode, logs a warning and returns the raw key.
5. **Parameter substitution** — via `_SubstituteParams()` and `_ToString()`.
6. **Cache store** — only when no parameters were passed.

Cache clears automatically on `SetLanguage()`.

### Info
- **See also:** `SetLanguage()`, `GetCacheStats()`
- **Category:** i18n functions, Translation
- **Source:** `i18n_lib.prg`

### Example
```harbour
? T( "app.title" )                    // "i18n Library Test"
? T( "msg.welcome" )                  // "Welcome to the i18n library!"
? T( "msg.param.test", "John", 5 )    // "Hello John, you have 5 messages"
? T( "nonexistent.key" )              // "nonexistent.key"
```

---

<a name="en-get-current-language"></a>
## GetCurrentLanguage()

Returns the currently active language code.

### Syntax
```
GetCurrentLanguage() --> cLangCode
```

### Return
Current language code (`"EN"`, `"ES"`, `"PT"`). Returns `"EN"` if `InitI18n()` was never called.

### Description
Returns the internal `cCurrentLang` static variable. Useful for UI display, logging, or conditional logic.

### Info
- **See also:** `SetLanguage()`
- **Category:** i18n functions, Language management

---

<a name="en-get-available-languages"></a>
## GetAvailableLanguages()

Returns an array of all available language codes found in `/i18n/`.

### Syntax
```
GetAvailableLanguages() --> aLanguages
```

### Return
Array of language codes (e.g., `{ "EN", "ES", "PT" }`). Clone — safe to modify. Returns `{ "EN" }` if no valid files exist.

### Description
Populated during `InitI18n()` by `_ScanAvailableLanguages()`. Each `.json` file is validated (readable, non-empty, parses into a valid hash) before inclusion. Useful for language selection menus.

### Info
- **See also:** `InitI18n()`, `SetLanguage()`
- **Category:** i18n functions, Language management

---

<a name="en-get-translation-hash"></a>
## GetTranslationHash()

Returns a clone of the current translation hash.

### Syntax
```
GetTranslationHash() --> hTranslations
```

### Return
Hash (`{ => }`) with all key-value pairs for the current language. Clone — safe to modify.

### Description
Read-only access to the internal dictionary. Useful for debugging or export. Contains data loaded from the current language's JSON (or the embedded English fallback).

### Info
- **See also:** `T()`, `ParseJsonDictionary()`
- **Category:** i18n functions, Debugging

---

<a name="en-is-initialized"></a>
## IsInitialized()

Returns whether `InitI18n()` has been called successfully.

### Syntax
```
IsInitialized() --> lInitialized
```

### Return
`.T.` if initialized, `.F.` otherwise.

### Info
- **See also:** `InitI18n()`
- **Category:** i18n functions, Initialization

### Example
```harbour
IF ! IsInitialized()
   InitI18n( "EN" )
ENDIF
```

---

<a name="en-get-cache-stats"></a>
## GetCacheStats()

Returns cache performance statistics.

### Syntax
```
GetCacheStats() --> hStats
```

### Return
Hash with keys:

| Key | Type | Description |
|-----|------|-------------|
| `hits` | N | Cache hits |
| `misses` | N | Cache misses |
| `hit_rate` | N | Hit rate percentage |
| `cache_size` | N | Entries in cache |

### Description
The cache only stores results for keys translated **without parameters**. Cleared on language change. Intended for debugging/perf tuning.

### Info
- **See also:** `T()`, `SetLanguage()`
- **Category:** i18n functions, Debugging

---

<a name="en-parse-json-dictionary"></a>
## ParseJsonDictionary()

Robust, zero-dependency JSON parser for flat `{"key":"value"}` dictionaries.

### Syntax
```
ParseJsonDictionary( <cJson> [, <lDecodeUnicode>] ) --> hDictionary
```

### Arguments
- **`<cJson>`** — Raw JSON string. Must be a flat object.
- **`<lDecodeUnicode>`** — Optional. `.T.` decodes `\uXXXX` sequences. Default `.F.` for performance.

### Return
Hash (`{ => }`) with parsed pairs. Empty hash on failure.

### Description
Uses only core Harbour string functions (`At()`, `SubStr()`, `StrTran()`, `hb_ATokens()`). Always compiles and links.

**Supported:** Flat objects with string values.
**Not supported:** Nested objects, arrays, numbers, booleans, `null`, multi-line values.

**Processing:**
1. Normalize line breaks.
2. Tokenize by lines.
3. Extract key (first quoted string) and value (second quoted string).
4. Handle escaped quotes.
5. Unescape `\"`, `\\`, `\n`, `\t`, `\r`.
6. Optionally decode `\uXXXX`.

### Info
- **See also:** `T()`, `SetLanguage()`, `_DecodeUnicodeEscapes()`
- **Category:** i18n functions, JSON, Parsing

### Example
```harbour
LOCAL cJson := '{"app.title": "My App", "msg.hello": "Hello!"}'
LOCAL hDict := ParseJsonDictionary( cJson )
? hDict[ "app.title" ]        // "My App"

LOCAL cJsonU := '{"msg.accents": "Caf\u00e9"}'
LOCAL hDictU := ParseJsonDictionary( cJsonU, .T. )
? hDictU[ "msg.accents" ]     // "Café"
```

---

<a name="english-private-helpers"></a>
# ENGLISH — Private Helper Functions

These are `STATIC` functions — accessible only within `i18n_lib.prg`. The user never calls them directly.

---

<a name="en-decode-unicode"></a>
## _DecodeUnicodeEscapes()

Decodes JSON `\uXXXX` escapes to UTF-8, with surrogate pair support.

### Syntax
```
_DecodeUnicodeEscapes( <cText> ) --> cDecoded
```

### Description
Handles full BMP (U+0000–U+FFFF) plus surrogate pairs (U+10000–U+10FFFF).

**Surrogate pair logic:**
- High: `U+D800`–`U+DBFF`
- Low: `U+DC00`–`U+DFFF`
- Combined: `65536 + (high - 55296) * 1024 + (low - 56320)`

Safety limit: 1000 iterations.

### Info
- **See also:** `ParseJsonDictionary()`, `_UnicodeToChar()`

---

<a name="en-is-valid-hex"></a>
## _IsValidHex()

Validates a 4-character hexadecimal sequence.

### Syntax
```
_IsValidHex( <cHex> ) --> lValid
```

### Return
`.T.` if exactly 4 chars `0-9`, `A-F` (case-insensitive).

---

<a name="en-hex-to-decimal"></a>
## _HexToDecimal()

Converts a hexadecimal string to decimal.

### Syntax
```
_HexToDecimal( <cHex> ) --> nDecimal
```

### Return
Decimal value. Returns `0` for empty/invalid input.

---

<a name="en-unicode-to-char"></a>
## _UnicodeToChar()

Converts a Unicode code point to UTF-8 bytes.

### Syntax
```
_UnicodeToChar( <nCode> ) --> cUtf8
```

| Range | Bytes | Pattern |
|-------|-------|---------|
| 0–127 | 1 | `0xxxxxxx` |
| 128–2047 | 2 | `110xxxxx 10xxxxxx` |
| 2048–65535 | 3 | `1110xxxx 10xxxxxx 10xxxxxx` |
| 65536–1114111 | 4 | `11110xxx 10xxxxxx 10xxxxxx 10xxxxxx` |

---

<a name="en-substitute-params"></a>
## _SubstituteParams()

Replaces `{1}`..`{9}` placeholders.

### Syntax
```
_SubstituteParams( <cStr>, <xP1>, ..., <xP9> ) --> cResult
```

Stops at the first `NIL` parameter.

---

<a name="en-to-string"></a>
## _ToString()

Safely converts any value to string.

### Syntax
```
_ToString( <xVal> ) --> cString
```

| Type | Conversion |
|------|------------|
| `NIL` | `""` |
| `C` | As-is |
| `N` | `LTrim( Str( xVal ) )` |
| `L` | `"true"` / `"false"` |
| `D` | `DToC( xVal )` |
| Other | `hb_ValToStr( xVal )` |

---

<a name="en-scan-available-languages"></a>
## _ScanAvailableLanguages()

Scans `/i18n/` for valid JSON files and returns language codes.

### Syntax
```
_ScanAvailableLanguages() --> aLanguages
```

Uses `Directory()` to list `.json` files. Each is parsed; only valid, non-empty dictionaries are accepted. Returns `{ "EN" }` if none found.

---

<a name="en-default-en-dictionary"></a>
## _DefaultEnDictionary()

Returns the embedded English fallback dictionary.

### Syntax
```
_DefaultEnDictionary() --> hDictionary
```

### Description
A `STATIC FUNCTION` that returns a fresh hash literal with 14 hardcoded English keys. It is **never called by the user** — it is invoked internally by `SetLanguage()` in two scenarios (see [Appendix A](#english-appendix-a)).

**Embedded keys:**

| Key | Value |
|-----|-------|
| `app.title` | `"i18n Library Test"` |
| `app.subtitle` | `"Standalone Internationalization Demo"` |
| `lbl.language` | `"Language:"` |
| `lbl.current` | `"Current:"` |
| `lbl.sample` | `"Sample text:"` |
| `lbl.param.test` | `"Parameter test:"` |
| `btn.change` | `"Change Language"` |
| `btn.close` | `"Close"` |
| `msg.welcome` | `"Welcome to the i18n library!"` |
| `msg.changed` | `"Language changed to {1}"` |
| `msg.goodbye` | `"Goodbye!"` |
| `msg.param.test` | `"Hello {1}, you have {2} messages"` |
| `err.unknown` | `"Unknown error"` |
| `err.missing.key` | `"Missing translation key: {1}"` |

**Full detail:** See [Appendix A](#english-appendix-a).

---

<a name="english-appendix-a"></a>
# ENGLISH — Appendix A: The Embedded English Dictionary (Complete Detail)

## A.1 What is it?

The embedded English dictionary is a **private static function** inside `i18n_lib.prg` named `_DefaultEnDictionary()`. It is **not** an external file, **not** a JSON resource, **not** a system resource. It is **hardcoded in the Harbour source** as a hash literal.

```harbour
STATIC FUNCTION _DefaultEnDictionary()
   LOCAL h := { => }
   
   h[ "app.title" ]       := "i18n Library Test"
   h[ "app.subtitle" ]    := "Standalone Internationalization Demo"
   h[ "lbl.language" ]    := "Language:"
   h[ "lbl.current" ]     := "Current:"
   h[ "lbl.sample" ]      := "Sample text:"
   h[ "lbl.param.test" ]  := "Parameter test:"
   h[ "btn.change" ]      := "Change Language"
   h[ "btn.close" ]       := "Close"
   h[ "msg.welcome" ]     := "Welcome to the i18n library!"
   h[ "msg.changed" ]     := "Language changed to {1}"
   h[ "msg.goodbye" ]     := "Goodbye!"
   h[ "msg.param.test" ]  := "Hello {1}, you have {2} messages"
   h[ "err.unknown" ]     := "Unknown error"
   h[ "err.missing.key" ] := "Missing translation key: {1}"
   
RETURN h
```

### Characteristics

| Property | Value |
|----------|-------|
| **Type** | `STATIC FUNCTION` (module-private) |
| **Visibility** | Only inside `i18n_lib.prg` |
| **Returns** | Freshly-built hash on each call |
| **Dependencies** | None — only string literals |
| **Persistence** | Non-persistent — rebuilt each invocation |
| **Modifiable externally** | No — "baked" into the binary |

## A.2 Where is `_DefaultEnDictionary()` called?

There are **exactly two call sites** in `i18n_lib.prg`:

### Call Site 1 — Inside `SetLanguage()` (load failure → `hLang`)
```harbour
IF ! lOk
   hLang        := _DefaultEnDictionary()
   cCurrentLang := "EN"
   lOk          := .T.
ENDIF
```
**Triggered when** `lOk` remains `.F.` after the `TRY...CATCH`, i.e.:
- JSON file does not exist, OR
- File exists but `MemoRead()` returns non-string, OR
- File is empty, OR
- `ParseJsonDictionary()` returns empty hash, OR
- Exception during read/parse.

### Call Site 2 — Inside `SetLanguage()` (first-time `hFallback` init)
```harbour
IF Len( hFallback ) == 0
   hFallback := _DefaultEnDictionary()
ENDIF
```
**Triggered only the first time** `SetLanguage()` is called (since `hFallback` starts as `{ => }`). Subsequent calls skip this.

## A.3 How is it invoked automatically? — Full flow

The user **never** calls `_DefaultEnDictionary()` directly. It runs transparently.

### Scenario A — Normal init with valid JSON
```
User → InitI18n( "ES" )
         ↓
      SetLanguage( "ES" )
         ↓
      Read \i18n\es.json → parse OK → lOk := .T.
         ↓
      IF ! lOk → FALSE → skip for hLang
         ↓
      IF Len( hFallback ) == 0 → TRUE (first time)
         ↓
      hFallback := _DefaultEnDictionary()   ← CALL #1
         ↓
      Return .T.
```

### Scenario B — Init with missing JSON
```
User → InitI18n( "FR" )
         ↓
      SetLanguage( "FR" ) → not in "EN,ES,PT" → normalized to "EN"
         ↓
      Read \i18n\en.json
         ↓
      Exists? NO → lOk stays .F.
         ↓
      IF ! lOk → TRUE
         ↓
      hLang := _DefaultEnDictionary()   ← CALL #1
      cCurrentLang := "EN"
      lOk := .T.
         ↓
      IF Len( hFallback ) == 0 → TRUE
         ↓
      hFallback := _DefaultEnDictionary()   ← CALL #2
         ↓
      Return .T.
```

### Scenario C — Runtime language switch (already initialized)
```
User → SetLanguage( "PT" )
         ↓
      Read \i18n\pt.json → parse OK → lOk := .T.
         ↓
      IF ! lOk → FALSE → skip for hLang
         ↓
      IF Len( hFallback ) == 0 → FALSE (already filled)
         ↓
      Return .T.
```

### Scenario D — Switch to a language with a corrupt file
```
User → SetLanguage( "ES" )
         ↓
      Read \i18n\es.json → empty → hDict = { => }
         ↓
      Len( hDict ) > 0 → FALSE → lOk stays .F.
         ↓
      IF ! lOk → TRUE
         ↓
      hLang := _DefaultEnDictionary()   ← CALL
      cCurrentLang := "EN"              ← SILENT SWITCH TO ENGLISH!
      lOk := .T.
         ↓
      Return .T.
```

## A.4 Activation summary table

| Situation | `_DefaultEnDictionary()` called? | For which variable? |
|-----------|----------------------------------|---------------------|
| First `SetLanguage()` with valid JSON | Yes (1×) | `hFallback` |
| First `SetLanguage()` with missing JSON | Yes (2×) | `hLang` and `hFallback` |
| Later calls with valid JSON | No | — |
| Later calls with missing JSON | Yes (1×) | `hLang` |
| Later calls with corrupt JSON | Yes (1×) | `hLang` |
| `SetLanguage()` with unsupported code (`"XX"`) | Depends on EN's JSON | — |

## A.5 How does the user "activate" it?

The user does **nothing special**:

1. **Does not place** `\i18n\xx.json` on disk → automatic fallback.
2. **Places a corrupt or empty file** → automatic fallback.
3. **Uses an unsupported language code** (`"FR"`, `"DE"`) → normalized to `"EN"`; if `en.json` missing, fallback.

### Minimal practical example
```harbour
PROCEDURE Main()
   // No \i18n\ folder, no JSON files at all
   InitI18n( "ES" )
   
   ? GetCurrentLanguage()             // "EN"  (not "ES")
   ? T( "app.title" )                 // "i18n Library Test"
   ? T( "msg.welcome" )               // "Welcome to the i18n library!"
   ? T( "msg.param.test", "Ana", 3 )  // "Hello Ana, you have 3 messages"
   
RETURN
```
Even though the user asked for Spanish, the library **operates in English** thanks to the embedded dictionary. No error, no exception, no message (unless `__DEBUG__`).

## A.6 Limitations

| Limitation | Impact |
|------------|--------|
| Only 14 keys | `T()` returns raw key for anything not covered |
| English only | No embedded ES/PT equivalent |
| Baked into binary | Editing requires recompiling `i18n_lib.prg` |
| Not configurable | No public API to substitute it |
| No state persistence | A new hash is built on each call |

### Keys covered
```
app.title          app.subtitle       lbl.language
lbl.current        lbl.sample         lbl.param.test
btn.change         btn.close          msg.welcome
msg.changed        msg.goodbye        msg.param.test
err.unknown        err.missing.key
```
Any other key (e.g., `"invoice.total"`) returns the literal key.

## A.7 How to extend or replace it

### Option A — Modify `_DefaultEnDictionary()` directly
```harbour
STATIC FUNCTION _DefaultEnDictionary()
   LOCAL h := { => }
   h[ "app.title" ]       := "i18n Library Test"
   // ... existing keys ...
   h[ "invoice.total" ]   := "Total:"
   h[ "customer.name" ]   := "Customer Name:"
   h[ "err.db.connect" ]  := "Cannot connect to database"
RETURN h
```
**Pro:** Works without external files. **Con:** Requires recompile.

### Option B — Always provide a valid `en.json`
Place `\i18n\en.json` with all your keys. Since `SetLanguage()` loads JSON first, the embedded one is only used if the JSON fails.
```json
{
   "invoice.total": "Total:",
   "customer.name": "Customer Name:",
   "err.db.connect": "Cannot connect to database"
}
```
**Pro:** No recompile. **Con:** Must ensure the file exists and is valid.

### Option C — Runtime injection (requires library modification)
**No public API exists in the current version** for injecting a fallback dictionary. Adding one would look like:
```harbour
FUNCTION SetFallbackDictionary( hDict )
   IF ValType( hDict ) == "H"
      hFallback := hb_HClone( hDict )
      RETURN .T.
   ENDIF
RETURN .F.
```
This is **not** in the current `i18n_lib.prg`.

## A.8 Silent language switch warning

> If a user calls `SetLanguage( "ES" )` and `es.json` is corrupt, the library **silently switches to English** and returns `.T.`. The caller **cannot distinguish** "Spanish loaded" from "English fallback active" from the return value alone.

To detect this:
```harbour
SetLanguage( "ES" )
IF GetCurrentLanguage() != "ES"
   // Fallback activated — notify the user or log
   MsgAlert( "Could not load Spanish. Using English." )
ENDIF
```

This is a design limitation that should be documented or fixed in a future version.

## A.9 Executive summary

| Question | Answer |
|----------|--------|
| What is it? | A `STATIC FUNCTION` returning a 14-key English hash literal |
| Where is it defined? | Inside `i18n_lib.prg`, at the end of the file |
| Who calls it? | `SetLanguage()`, in two places: for `hLang` (on load failure) and for `hFallback` (if empty) |
| Does the user call it? | **Never** — transparent |
| When does it activate? | Missing/empty/corrupt JSON, or unsupported language code |
| How does it activate? | Automatically inside `InitI18n()` → `SetLanguage()` |
| Can it be disabled? | No, without modifying source |
| Can it be extended? | Yes, by editing `_DefaultEnDictionary()` or providing a valid `en.json` |
| Public API to inject custom? | No in the current version |
| Silent language change? | Yes — `GetCurrentLanguage()` returns `"EN"` even when another was requested |

---

<a name="english-appendix-b"></a>
# ENGLISH — Appendix B: Advanced Topics

## B.1 The Translation Cache — Why It Matters

The cache (`hKeyCache`) only stores translations for keys fetched **without parameters**. This is because:

- Keys with parameters produce different outputs for the same key → caching them would be wrong.
- UI rendering often calls the same keys (e.g., `T("btn.close")`) hundreds of times per frame.

**Cache key format:** `"<lang>:<key>"`, e.g., `"EN:btn.close"`.

**Cleared when:** `SetLanguage()` is called.

**Statistics:** `GetCacheStats()` returns `hits`, `misses`, `hit_rate`, `cache_size`.

**Typical use:** In a loop rendering 100 buttons, the first `T("btn.close")` is a miss, the next 99 are hits.

## B.2 The `__DEBUG__` Compile Flag

When `__DEBUG__` is defined at compile time, the library emits diagnostic messages:

- **Missing key in current language:** `"i18n Warning: Key 'X' not found in ES, using fallback"`
- **Missing key everywhere:** `"i18n Error: Key 'X' not found in any language"`
- **JSON load error:** `"i18n Error loading <file>: <description>"`

These are suppressed in release builds.

**To enable:**
```
hbmk2 myapp.prg i18n_lib.prg -D__DEBUG__
```

## B.3 Unicode / Surrogate Pair Handling

Full Unicode support is available but **disabled by default** for performance. Enable per-file or globally:

```harbour
// Per file (default — fast)
hDict := ParseJsonDictionary( cJson )

// Explicit decode (slower — for \uXXXX sequences)
hDict := ParseJsonDictionary( cJson, .T. )
```

Surrogate pairs (e.g., emoji `😀` = `\uD83D\uDE00`) are correctly combined.

## B.4 JSON Parser Limitations — Full Detail

`ParseJsonDictionary()` is a **flat-object only** parser. It will:

- ✅ Parse: `{"key": "value", "key2": "value2"}`
- ✅ Handle escaped quotes: `{"key": "say \"hi\""}`
- ✅ Unescape `\n`, `\t`, `\r`, `\\`
- ✅ Decode `\uXXXX` when enabled
- ❌ Ignore: nested objects `{"a": {"b": "c"}}`
- ❌ Ignore: arrays `{"a": ["x","y"]}`
- ❌ Treat as string: numbers, `true`, `false`, `null`
- ❌ Fail on: unescaped `"` inside values

**Best practice:** Keep JSON flat and string-only.

## B.5 Date Format Side Effects

`SetLanguage()` **globally** changes the Harbour date format via `SET DATE FORMAT TO`. This affects the entire application:

- `ES`, `PT` → `DD/MM/YYYY`
- `EN` → `MM/DD/YYYY`

If your app needs fixed date formatting regardless of language, save and restore it around `SetLanguage()` calls.

## B.6 File Naming Convention

Language files must be:
- Placed in `<cBasePath>\i18n\`
- Named `<lang>.json` (lowercase), e.g., `en.json`, `es.json`, `pt.json`
- Valid flat JSON with string values
- UTF-8 encoded (recommended; ANSI works for ASCII-only)

Language codes are extracted from the filename, uppercased, and stored in `aAvailableLangs` if the file parses.

---

<a name="spanish-introduction"></a>
# ESPAÑOL — Introducción

`i18n_lib.prg` es una librería de internacionalización (i18n) lista para producción para Harbour/MiniGUI Extended. Proporciona soporte de traducción sin dependencias usando diccionarios JSON planos, con un respaldo inglés embebido que garantiza que la aplicación nunca falle por archivos de traducción faltantes.

**Principios de diseño clave:**
- **Cero dependencias** — solo funciones de cadena del núcleo de Harbour.
- **Cero DBF** — sin archivos de base de datos.
- **Parser JSON robusto** — autocontenido, siempre compila y enlaza.
- **Soporte Unicode** — decodificación opcional de `\uXXXX` con manejo de pares sustitutos.
- **Caché de rendimiento** — las claves traducidas sin parámetros se cachean.
- **Respaldo embebido** — un diccionario inglés incorporado asegura operación incluso sin archivos externos.

---

<a name="spanish-function-index"></a>
# ESPAÑOL — Índice de Funciones

## API Pública

| Función | Propósito |
|---------|-----------|
| `InitI18n( cLang [, cPath] )` | Inicializar con idioma |
| `SetLanguage( cLang )` | Cambiar idioma en runtime |
| `T( cKey [, xP1..xP9] )` | Traducir clave con parámetros |
| `GetCurrentLanguage()` | Devuelve el código de idioma actual |
| `GetAvailableLanguages()` | Devuelve array de idiomas disponibles |
| `GetTranslationHash()` | Devuelve el hash hLang actual (clon) |
| `IsInitialized()` | Devuelve si InitI18n() fue llamado |
| `GetCacheStats()` | Devuelve estadísticas de la caché |
| `ParseJsonDictionary( cJson [, lDecodeUnicode] )` | Parsear diccionario JSON |

## Auxiliares Privados (uso interno)

| Función | Propósito |
|---------|-----------|
| `_DecodeUnicodeEscapes( cText )` | Decodifica secuencias `\uXXXX` a UTF-8 |
| `_IsValidHex( cHex )` | Valida cadena hex de 4 caracteres |
| `_HexToDecimal( cHex )` | Convierte hex a decimal |
| `_UnicodeToChar( nCode )` | Convierte code point a UTF-8 |
| `_SubstituteParams( cStr, xP1..xP9 )` | Reemplaza marcadores `{n}` |
| `_ToString( xVal )` | Conversión segura valor-a-cadena |
| `_ScanAvailableLanguages()` | Escanea `/i18n/` por archivos JSON |
| `_DefaultEnDictionary()` | Devuelve el diccionario inglés embebido |

---

<a name="spanish-public-api"></a>
# ESPAÑOL — Funciones Públicas (API)

---

<a name="es-init-i18n"></a>
## InitI18n()

Inicializa la librería i18n. Debe llamarse una vez al inicio de la aplicación.

### Sintaxis
```
InitI18n( <cLang> [, <cPath>] ) --> lExito
```

### Argumentos
- **`<cLang>`** — Código de idioma (`"EN"`, `"ES"`, `"PT"`). Por defecto `"EN"` si es `NIL`.
- **`<cPath>`** — Ruta base opcional para la carpeta `/i18n/`. Por defecto `GetStartUpFolder()`.

### Retorno
`.T.` en éxito, `.F.` en fallo.

### Descripción
Punto de entrada. Normaliza el código de idioma, resuelve la ruta base (elimina barras finales), escanea la carpeta `/i18n/`, carga el idioma solicitado vía `SetLanguage()`, y establece `lInitialized` a `.T.` en éxito.

**Si el archivo del idioma solicitado falta o es inválido, la función recurre al diccionario inglés embebido** (ver [Apéndice A](#spanish-appendix-a)) para que la aplicación nunca falle al arrancar.

### Info
- **Ver también:** `SetLanguage()`, `IsInitialized()`
- **Categoría:** Funciones i18n, Inicialización
- **Fuente:** `i18n_lib.prg`

### Ejemplo
```harbour
InitI18n( "EN" )                       // Inglés, ruta por defecto
InitI18n( "ES", "C:\MiApp" )          // Español, ruta personalizada
InitI18n()                             // Inglés (implícito)
```

---

<a name="es-set-language"></a>
## SetLanguage()

Cambia el idioma activo en tiempo de ejecución.

### Sintaxis
```
SetLanguage( <cLang> ) --> lExito
```

### Argumentos
- **`<cLang>`** — Código de idioma. Debe ser uno de `"EN"`, `"ES"`, `"PT"`; si no, usa `"EN"`.

### Retorno
`.T.` en éxito (casi siempre — ver descripción), `.F.` en fallo.

### Descripción
1. Valida y normaliza el código.
2. Construye la ruta: `<cBasePath>\i18n\<lang>.json` (minúsculas).
3. Lee el JSON con `MemoRead()`.
4. Parsea con `ParseJsonDictionary()`.
5. Reemplaza `hLang` con los datos parseados.
6. Limpia la caché (`hKeyCache`), reinicia estadísticas.
7. Establece formato de fecha: `ES`/`PT` → `DD/MM/YYYY`; resto `MM/DD/YYYY`.

**Comportamiento de respaldo — CUÁNDO SE LLAMA A `_DefaultEnDictionary():`**

Hay exactamente **dos puntos de llamada** en esta función:

**Punto 1 — Fallo de carga (asigna a `hLang`):**
```harbour
IF ! lOk
   hLang        := _DefaultEnDictionary()
   cCurrentLang := "EN"
   lOk          := .T.
ENDIF
```
Se activa cuando `lOk` sigue siendo `.F.` después del `TRY...CATCH`, es decir:
- El archivo JSON no existe, o
- El archivo está vacío / ilegible, o
- `ParseJsonDictionary()` devuelve un hash vacío, o
- Ocurrió una excepción durante lectura/parseo.

**Punto 2 — Inicialización del respaldo por primera vez (asigna a `hFallback`):**
```harbour
IF Len( hFallback ) == 0
   hFallback := _DefaultEnDictionary()
ENDIF
```
Se activa **solo la primera vez** que se llama a `SetLanguage()` (porque `hFallback` comienza como `{ => }`). Llamadas posteriores lo omiten porque `hFallback` ya está poblado.

**⚠️ Advertencia de cambio silencioso de idioma:** Si el usuario pide `"ES"` y `es.json` está corrupto, la librería **cambia silenciosamente a inglés** y devuelve `.T.`. El llamador no puede distinguir "español cargado" de "respaldo inglés activo" solo por el valor de retorno. Para detectarlo:
```harbour
SetLanguage( "ES" )
IF GetCurrentLanguage() != "ES"
   // Se activó el respaldo — notificar o registrar
ENDIF
```

### Info
- **Ver también:** `InitI18n()`, `T()`, `GetCurrentLanguage()`, [Apéndice A](#spanish-appendix-a)
- **Categoría:** Funciones i18n, Gestión de idiomas
- **Fuente:** `i18n_lib.prg`

### Ejemplo
```harbour
SetLanguage( "ES" )   // OK
SetLanguage( "PT" )   // OK
SetLanguage( "XX" )   // Inválido → normaliza a "EN"
```

---

<a name="es-t"></a>
## T()

Traduce una clave usando el diccionario del idioma actual, con sustitución opcional de parámetros.

### Sintaxis
```
T( <cKey> [, <xP1>, <xP2>, ..., <xP9>] ) --> cTraduccion
```

### Argumentos
- **`<cKey>`** — Clave de traducción (ej. `"app.title"`). Devuelve `""` si `NIL`/vacía.
- **`<xP1..xP9>`** — Parámetros opcionales sustituidos por `{1}`..`{9}`.

### Retorno
Cadena traducida. Si la clave falta en el idioma actual, prueba `hFallback` (inglés). Si aún falta, devuelve la clave cruda.

### Descripción
1. Verificación de clave vacía.
2. **Búsqueda en caché** — si no hay parámetros, verifica `hKeyCache` con clave `"<lang>:<key>"`. Acierto → retorno inmediato (`nCacheHits++`).
3. **Búsqueda en diccionario** — `hLang` primero, luego `hFallback`.
4. **No encontrada** — en modo `__DEBUG__`, registra advertencia y devuelve la clave cruda.
5. **Sustitución de parámetros** — vía `_SubstituteParams()` y `_ToString()`.
6. **Almacenamiento en caché** — solo cuando no se pasaron parámetros.

La caché se limpia automáticamente en `SetLanguage()`.

### Info
- **Ver también:** `SetLanguage()`, `GetCacheStats()`
- **Categoría:** Funciones i18n, Traducción
- **Fuente:** `i18n_lib.prg`

### Ejemplo
```harbour
? T( "app.title" )                    // "i18n Library Test"
? T( "msg.welcome" )                  // "Welcome to the i18n library!"
? T( "msg.param.test", "Juan", 5 )    // "Hello Juan, you have 5 messages"
? T( "clave.inexistente" )            // "clave.inexistente"
```

---

<a name="es-get-current-language"></a>
## GetCurrentLanguage()

Devuelve el código del idioma actualmente activo.

### Sintaxis
```
GetCurrentLanguage() --> cCodigoIdioma
```

### Retorno
Código actual (`"EN"`, `"ES"`, `"PT"`). Devuelve `"EN"` si `InitI18n()` nunca fue llamado.

### Descripción
Devuelve la variable estática interna `cCurrentLang`. Útil para mostrar en UI, logging o lógica condicional.

### Info
- **Ver también:** `SetLanguage()`
- **Categoría:** Funciones i18n, Gestión de idiomas

---

<a name="es-get-available-languages"></a>
## GetAvailableLanguages()

Devuelve un arreglo con todos los códigos de idioma disponibles en `/i18n/`.

### Sintaxis
```
GetAvailableLanguages() --> aIdiomas
```

### Retorno
Arreglo de códigos (ej. `{ "EN", "ES", "PT" }`). Es un clon — seguro de modificar. Devuelve `{ "EN" }` si no hay archivos válidos.

### Descripción
Se llena durante `InitI18n()` por `_ScanAvailableLanguages()`. Cada archivo `.json` se valida (legible, no vacío, parsea a hash válido) antes de incluirse. Útil para menús de selección de idioma.

### Info
- **Ver también:** `InitI18n()`, `SetLanguage()`
- **Categoría:** Funciones i18n, Gestión de idiomas

---

<a name="es-get-translation-hash"></a>
## GetTranslationHash()

Devuelve un clon del hash de traducciones actual.

### Sintaxis
```
GetTranslationHash() --> hTraducciones
```

### Retorno
Hash (`{ => }`) con todos los pares clave-valor del idioma actual. Es un clon — seguro de modificar.

### Descripción
Acceso de solo lectura al diccionario interno. Útil para depuración o exportación. Contiene los datos cargados desde el JSON del idioma actual (o el respaldo inglés embebido).

### Info
- **Ver también:** `T()`, `ParseJsonDictionary()`
- **Categoría:** Funciones i18n, Depuración

---

<a name="es-is-initialized"></a>
## IsInitialized()

Devuelve si `InitI18n()` fue llamado exitosamente.

### Sintaxis
```
IsInitialized() --> lInicializado
```

### Retorno
`.T.` si está inicializado, `.F.` en caso contrario.

### Info
- **Ver también:** `InitI18n()`
- **Categoría:** Funciones i18n, Inicialización

### Ejemplo
```harbour
IF ! IsInitialized()
   InitI18n( "EN" )
ENDIF
```

---

<a name="es-get-cache-stats"></a>
## GetCacheStats()

Devuelve estadísticas de rendimiento de la caché.

### Sintaxis
```
GetCacheStats() --> hEstadisticas
```

### Retorno
Hash con claves:

| Clave | Tipo | Descripción |
|-------|------|-------------|
| `hits` | N | Aciertos de caché |
| `misses` | N | Fallos de caché |
| `hit_rate` | N | Porcentaje de aciertos |
| `cache_size` | N | Entradas en la caché |

### Descripción
La caché solo almacena resultados de claves traducidas **sin parámetros**. Se limpia al cambiar idioma. Diseñada para depuración/ajuste de rendimiento.

### Info
- **Ver también:** `T()`, `SetLanguage()`
- **Categoría:** Funciones i18n, Depuración

---

<a name="es-parse-json-dictionary"></a>
## ParseJsonDictionary()

Parser JSON robusto sin dependencias para diccionarios planos `{"clave":"valor"}`.

### Sintaxis
```
ParseJsonDictionary( <cJson> [, <lDecodeUnicode>] ) --> hDiccionario
```

### Argumentos
- **`<cJson>`** — Cadena JSON cruda. Debe ser un objeto plano.
- **`<lDecodeUnicode>`** — Opcional. `.T.` decodifica secuencias `\uXXXX`. Por defecto `.F.` por rendimiento.

### Retorno
Hash (`{ => }`) con los pares parseados. Hash vacío si falla.

### Descripción
Usa solo funciones de cadena del núcleo de Harbour (`At()`, `SubStr()`, `StrTran()`, `hb_ATokens()`). Siempre compila y enlaza.

**Soportado:** Objetos planos con valores de cadena.
**No soportado:** Objetos anidados, arreglos, números, booleanos, `null`, valores multilínea.

**Procesamiento:**
1. Normaliza saltos de línea.
2. Tokeniza por líneas.
3. Extrae clave (primera cadena entre comillas) y valor (segunda cadena entre comillas).
4. Maneja comillas escapadas.
5. Desescapa `\"`, `\\`, `\n`, `\t`, `\r`.
6. Opcionalmente decodifica `\uXXXX`.

### Info
- **Ver también:** `T()`, `SetLanguage()`, `_DecodeUnicodeEscapes()`
- **Categoría:** Funciones i18n, JSON, Parseo

### Ejemplo
```harbour
LOCAL cJson := '{"app.title": "Mi App", "msg.hello": "¡Hola!"}'
LOCAL hDict := ParseJsonDictionary( cJson )
? hDict[ "app.title" ]        // "Mi App"

LOCAL cJsonU := '{"msg.acentos": "Caf\u00e9"}'
LOCAL hDictU := ParseJsonDictionary( cJsonU, .T. )
? hDictU[ "msg.acentos" ]     // "Café"
```

---

<a name="spanish-private-helpers"></a>
# ESPAÑOL — Funciones Auxiliares Privadas

Son funciones `STATIC` — accesibles solo dentro de `i18n_lib.prg`. El usuario nunca las llama directamente.

---

<a name="es-decode-unicode"></a>
## _DecodeUnicodeEscapes()

Decodifica escapes JSON `\uXXXX` a UTF-8, con soporte de pares sustitutos.

### Sintaxis
```
_DecodeUnicodeEscapes( <cText> ) --> cDecodificado
```

### Descripción
Maneja BMP completo (U+0000–U+FFFF) más pares sustitutos (U+10000–U+10FFFF).

**Lógica de pares sustitutos:**
- Alto: `U+D800`–`U+DBFF`
- Bajo: `U+DC00`–`U+DFFF`
- Combinado: `65536 + (alto - 55296) * 1024 + (bajo - 56320)`

Límite de seguridad: 1000 iteraciones.

### Info
- **Ver también:** `ParseJsonDictionary()`, `_UnicodeToChar()`

---

<a name="es-is-valid-hex"></a>
## _IsValidHex()

Valida una secuencia hexadecimal de 4 caracteres.

### Sintaxis
```
_IsValidHex( <cHex> ) --> lValido
```

### Retorno
`.T.` si son exactamente 4 caracteres `0-9`, `A-F` (sin distinguir mayúsculas).

---

<a name="es-hex-to-decimal"></a>
## _HexToDecimal()

Convierte una cadena hexadecimal a decimal.

### Sintaxis
```
_HexToDecimal( <cHex> ) --> nDecimal
```

### Retorno
Valor decimal. Devuelve `0` para entrada vacía/inválida.

---

<a name="es-unicode-to-char"></a>
## _UnicodeToChar()

Convierte un code point Unicode a bytes UTF-8.

### Sintaxis
```
_UnicodeToChar( <nCode> ) --> cUtf8
```

| Rango | Bytes | Patrón |
|-------|-------|--------|
| 0–127 | 1 | `0xxxxxxx` |
| 128–2047 | 2 | `110xxxxx 10xxxxxx` |
| 2048–65535 | 3 | `1110xxxx 10xxxxxx 10xxxxxx` |
| 65536–1114111 | 4 | `11110xxx 10xxxxxx 10xxxxxx 10xxxxxx` |

---

<a name="es-substitute-params"></a>
## _SubstituteParams()

Reemplaza marcadores `{1}`..`{9}`.

### Sintaxis
```
_SubstituteParams( <cStr>, <xP1>, ..., <xP9> ) --> cResultado
```

Se detiene en el primer parámetro `NIL`.

---

<a name="es-to-string"></a>
## _ToString()

Convierte cualquier valor a cadena de forma segura.

### Sintaxis
```
_ToString( <xVal> ) --> cCadena
```

| Tipo | Conversión |
|------|------------|
| `NIL` | `""` |
| `C` | Tal cual |
| `N` | `LTrim( Str( xVal ) )` |
| `L` | `"true"` / `"false"` |
| `D` | `DToC( xVal )` |
| Otro | `hb_ValToStr( xVal )` |

---

<a name="es-scan-available-languages"></a>
## _ScanAvailableLanguages()

Escanea `/i18n/` por archivos JSON válidos y devuelve códigos de idioma.

### Sintaxis
```
_ScanAvailableLanguages() --> aIdiomas
```

Usa `Directory()` para listar archivos `.json`. Cada uno se parsea; solo diccionarios válidos y no vacíos se aceptan. Devuelve `{ "EN" }` si no se encuentra ninguno.

---

<a name="es-default-en-dictionary"></a>
## _DefaultEnDictionary()

Devuelve el diccionario inglés embebido de respaldo.

### Sintaxis
```
_DefaultEnDictionary() --> hDiccionario
```

### Descripción
Una `STATIC FUNCTION` que devuelve un hash literal nuevo con 14 claves inglesas hardcodeadas. **Nunca es llamada por el usuario** — es invocada internamente por `SetLanguage()` en dos escenarios (ver [Apéndice A](#spanish-appendix-a)).

**Claves embebidas:**

| Clave | Valor |
|-------|-------|
| `app.title` | `"i18n Library Test"` |
| `app.subtitle` | `"Standalone Internationalization Demo"` |
| `lbl.language` | `"Language:"` |
| `lbl.current` | `"Current:"` |
| `lbl.sample` | `"Sample text:"` |
| `lbl.param.test` | `"Parameter test:"` |
| `btn.change` | `"Change Language"` |
| `btn.close` | `"Close"` |
| `msg.welcome` | `"Welcome to the i18n library!"` |
| `msg.changed` | `"Language changed to {1}"` |
| `msg.goodbye` | `"Goodbye!"` |
| `msg.param.test` | `"Hello {1}, you have {2} messages"` |
| `err.unknown` | `"Unknown error"` |
| `err.missing.key` | `"Missing translation key: {1}"` |

**Detalle completo:** Ver [Apéndice A](#spanish-appendix-a).

---

<a name="spanish-appendix-a"></a>
# ESPAÑOL — Apéndice A: El Diccionario Inglés Embebido (Detalle Completo)

## A.1 ¿Qué es?

El diccionario inglés embebido es una **función estática privada** dentro de `i18n_lib.prg` llamada `_DefaultEnDictionary()`. **No** es un archivo externo, **no** es un recurso JSON, **no** es un recurso del sistema. Está **codificada directamente en el código fuente Harbour** como un hash literal.

```harbour
STATIC FUNCTION _DefaultEnDictionary()
   LOCAL h := { => }
   
   h[ "app.title" ]       := "i18n Library Test"
   h[ "app.subtitle" ]    := "Standalone Internationalization Demo"
   h[ "lbl.language" ]    := "Language:"
   h[ "lbl.current" ]     := "Current:"
   h[ "lbl.sample" ]      := "Sample text:"
   h[ "lbl.param.test" ]  := "Parameter test:"
   h[ "btn.change" ]      := "Change Language"
   h[ "btn.close" ]       := "Close"
   h[ "msg.welcome" ]     := "Welcome to the i18n library!"
   h[ "msg.changed" ]     := "Language changed to {1}"
   h[ "msg.goodbye" ]     := "Goodbye!"
   h[ "msg.param.test" ]  := "Hello {1}, you have {2} messages"
   h[ "err.unknown" ]     := "Unknown error"
   h[ "err.missing.key" ] := "Missing translation key: {1}"
   
RETURN h
```

### Características

| Propiedad | Valor |
|-----------|-------|
| **Tipo** | `STATIC FUNCTION` (privada del módulo) |
| **Visibilidad** | Solo dentro de `i18n_lib.prg` |
| **Retorno** | Hash recién construido en cada llamada |
| **Dependencias** | Ninguna — solo literales de cadena |
| **Persistencia** | No persistente — se recrea cada invocación |
| **Modificable externamente** | No — "horneado" en el binario |

## A.2 ¿Dónde se llama `_DefaultEnDictionary()`?

Hay **exactamente dos puntos de llamada** en `i18n_lib.prg`:

### Punto 1 — Dentro de `SetLanguage()` (fallo de carga → `hLang`)
```harbour
IF ! lOk
   hLang        := _DefaultEnDictionary()
   cCurrentLang := "EN"
   lOk          := .T.
ENDIF
```
**Se activa cuando** `lOk` permanece `.F.` después del `TRY...CATCH`, es decir:
- El archivo JSON no existe, O
- El archivo existe pero `MemoRead()` devuelve algo que no es cadena, O
- El archivo está vacío, O
- `ParseJsonDictionary()` devuelve hash vacío, O
- Excepción durante lectura/parseo.

### Punto 2 — Dentro de `SetLanguage()` (primera inicialización de `hFallback`)
```harbour
IF Len( hFallback ) == 0
   hFallback := _DefaultEnDictionary()
ENDIF
```
**Se activa solo la primera vez** que se llama a `SetLanguage()` (porque `hFallback` comienza como `{ => }`). Llamadas posteriores lo omiten.

## A.3 ¿Cómo se invoca automáticamente? — Flujo completo

El usuario **nunca** llama a `_DefaultEnDictionary()` directamente. Se ejecuta de forma transparente.

### Escenario A — Inicialización normal con JSON válido
```
Usuario → InitI18n( "ES" )
            ↓
         SetLanguage( "ES" )
            ↓
         Lee \i18n\es.json → parsea OK → lOk := .T.
            ↓
         IF ! lOk → FALSO → omite para hLang
            ↓
         IF Len( hFallback ) == 0 → VERDADERO (primera vez)
            ↓
         hFallback := _DefaultEnDictionary()   ← LLAMADA #1
            ↓
         Retorna .T.
```

### Escenario B — Inicialización con JSON faltante
```
Usuario → InitI18n( "FR" )
            ↓
         SetLanguage( "FR" ) → no está en "EN,ES,PT" → normaliza a "EN"
            ↓
         Lee \i18n\en.json
            ↓
         ¿Existe? NO → lOk permanece .F.
            ↓
         IF ! lOk → VERDADERO
            ↓
         hLang := _DefaultEnDictionary()   ← LLAMADA #1
         cCurrentLang := "EN"
         lOk := .T.
            ↓
         IF Len( hFallback ) == 0 → VERDADERO
            ↓
         hFallback := _DefaultEnDictionary()   ← LLAMADA #2
            ↓
         Retorna .T.
```

### Escenario C — Cambio de idioma en runtime (ya inicializado)
```
Usuario → SetLanguage( "PT" )
            ↓
         Lee \i18n\pt.json → parsea OK → lOk := .T.
            ↓
         IF ! lOk → FALSO → omite para hLang
            ↓
         IF Len( hFallback ) == 0 → FALSO (ya lleno)
            ↓
         Retorna .T.
```

### Escenario D — Cambio a idioma con archivo corrupto
```
Usuario → SetLanguage( "ES" )
            ↓
         Lee \i18n\es.json → vacío → hDict = { => }
            ↓
         Len( hDict ) > 0 → FALSO → lOk permanece .F.
            ↓
         IF ! lOk → VERDADERO
            ↓
         hLang := _DefaultEnDictionary()   ← LLAMADA
         cCurrentLang := "EN"              ← ¡CAMBIO SILENCIOSO A INGLÉS!
         lOk := .T.
            ↓
         Retorna .T.
```

## A.4 Tabla resumen de activación

| Situación | ¿Se llama `_DefaultEnDictionary()`? | ¿Para qué variable? |
|-----------|--------------------------------------|---------------------|
| Primera `SetLanguage()` con JSON válido | Sí (1×) | `hFallback` |
| Primera `SetLanguage()` con JSON faltante | Sí (2×) | `hLang` y `hFallback` |
| Llamadas posteriores con JSON válido | No | — |
| Llamadas posteriores con JSON faltante | Sí (1×) | `hLang` |
| Llamadas posteriores con JSON corrupto | Sí (1×) | `hLang` |
| `SetLanguage()` con código no soportado (`"XX"`) | Depende del JSON de `EN` | — |

## A.5 ¿Cómo lo "activa" el usuario?

El usuario **no hace nada especial**:

1. **No coloca** `\i18n\xx.json` en disco → respaldo automático.
2. **Coloca un archivo corrupto o vacío** → respaldo automático.
3. **Usa un código no soportado** (`"FR"`, `"DE"`) → normaliza a `"EN"`; si falta `en.json`, respaldo.

### Ejemplo práctico mínimo
```harbour
PROCEDURE Main()
   // Sin carpeta \i18n\, sin archivos JSON
   InitI18n( "ES" )
   
   ? GetCurrentLanguage()             // "EN"  (no "ES")
   ? T( "app.title" )                 // "i18n Library Test"
   ? T( "msg.welcome" )               // "Welcome to the i18n library!"
   ? T( "msg.param.test", "Ana", 3 )  // "Hello Ana, you have 3 messages"
   
RETURN
```
Aunque el usuario pidió español, la librería **opera en inglés** gracias al diccionario embebido. Sin error, sin excepción, sin mensaje (salvo `__DEBUG__`).

## A.6 Limitaciones

| Limitación | Impacto |
|------------|---------|
| Solo 14 claves | `T()` devuelve la clave cruda para cualquier otra |
| Solo inglés | No hay equivalente embebido ES/PT |
| Horneado en el binario | Editarlo requiere recompilar `i18n_lib.prg` |
| No configurable | Sin API pública para sustituirlo |
| Sin persistencia de estado | Un hash nuevo se construye en cada llamada |

### Claves cubiertas
```
app.title          app.subtitle       lbl.language
lbl.current        lbl.sample         lbl.param.test
btn.change         btn.close          msg.welcome
msg.changed        msg.goodbye        msg.param.test
err.unknown        err.missing.key
```
Cualquier otra clave (ej. `"invoice.total"`) devuelve la clave literal.

## A.7 Cómo extenderlo o reemplazarlo

### Opción A — Modificar `_DefaultEnDictionary()` directamente
```harbour
STATIC FUNCTION _DefaultEnDictionary()
   LOCAL h := { => }
   h[ "app.title" ]       := "i18n Library Test"
   // ... claves existentes ...
   h[ "invoice.total" ]   := "Total:"
   h[ "customer.name" ]   := "Customer Name:"
   h[ "err.db.connect" ]  := "Cannot connect to database"
RETURN h
```
**Pro:** Funciona sin archivos externos. **Contra:** Requiere recompilar.

### Opción B — Proveer siempre un `en.json` válido
Coloca `\i18n\en.json` con todas tus claves. Como `SetLanguage()` carga JSON primero, el embebido solo se usa si el JSON falla.
```json
{
   "invoice.total": "Total:",
   "customer.name": "Customer Name:",
   "err.db.connect": "Cannot connect to database"
}
```
**Pro:** Sin recompilar. **Contra:** Debes asegurar que el archivo exista y sea válido.

### Opción C — Inyección en runtime (requiere modificar la librería)
**No existe API pública en la versión actual** para inyectar un diccionario de respaldo. Agregarla se vería así:
```harbour
FUNCTION SetFallbackDictionary( hDict )
   IF ValType( hDict ) == "H"
      hFallback := hb_HClone( hDict )
      RETURN .T.
   ENDIF
RETURN .F.
```
Esto **no** está en el `i18n_lib.prg` actual.

## A.8 Advertencia de cambio silencioso de idioma

> Si un usuario llama `SetLanguage( "ES" )` y `es.json` está corrupto, la librería **cambia silenciosamente a inglés** y devuelve `.T.`. El llamador **no puede distinguir** "español cargado" de "respaldo inglés activo" solo por el valor de retorno.

Para detectarlo:
```harbour
SetLanguage( "ES" )
IF GetCurrentLanguage() != "ES"
   // Se activó el respaldo — notificar al usuario o registrar
   MsgAlert( "No se pudo cargar español. Usando inglés." )
ENDIF
```

Es una limitación de diseño que debería documentarse o corregirse en una versión futura.

## A.9 Resumen ejecutivo

| Pregunta | Respuesta |
|----------|-----------|
| ¿Qué es? | Una `STATIC FUNCTION` que devuelve un hash literal de 14 claves en inglés |
| ¿Dónde se define? | Dentro de `i18n_lib.prg`, al final del archivo |
| ¿Quién la llama? | `SetLanguage()`, en dos lugares: para `hLang` (fallo de carga) y para `hFallback` (si está vacío) |
| ¿El usuario la llama? | **Nunca** — transparente |
| ¿Cuándo se activa? | JSON faltante/vacío/corrupto, o código de idioma no soportado |
| ¿Cómo se activa? | Automáticamente dentro de `InitI18n()` → `SetLanguage()` |
| ¿Se puede desactivar? | No, sin modificar el código fuente |
| ¿Se puede extender? | Sí, editando `_DefaultEnDictionary()` o proveyendo un `en.json` válido |
| ¿API pública para inyectar uno propio? | No en la versión actual |
| ¿Cambia el idioma silenciosamente? | Sí — `GetCurrentLanguage()` devuelve `"EN"` aunque se haya pedido otro |

---

<a name="spanish-appendix-b"></a>
# ESPAÑOL — Apéndice B: Temas Avanzados

## B.1 La Caché de Traducciones — Por Qué Importa

La caché (`hKeyCache`) solo almacena traducciones para claves obtenidas **sin parámetros**. Esto es porque:

- Claves con parámetros producen salidas distintas para la misma clave → cachearlas sería incorrecto.
- El renderizado de UI a menudo llama las mismas claves (ej. `T("btn.close")`) cientos de veces por frame.

**Formato de clave de caché:** `"<lang>:<key>"`, ej. `"EN:btn.close"`.

**Se limpia cuando:** se llama a `SetLanguage()`.

**Estadísticas:** `GetCacheStats()` devuelve `hits`, `misses`, `hit_rate`, `cache_size`.

**Uso típico:** En un bucle que renderiza 100 botones, el primer `T("btn.close")` es un fallo, los siguientes 99 son aciertos.

## B.2 El Flag de Compilación `__DEBUG__`

Cuando `__DEBUG__` está definido en tiempo de compilación, la librería emite mensajes de diagnóstico:

- **Clave faltante en idioma actual:** `"i18n Warning: Key 'X' not found in ES, using fallback"`
- **Clave faltante en todos lados:** `"i18n Error: Key 'X' not found in any language"`
- **Error de carga JSON:** `"i18n Error loading <file>: <description>"`

Se suprimen en compilaciones de producción.

**Para habilitarlo:**
```
hbmk2 myapp.prg i18n_lib.prg -D__DEBUG__
```

## B.3 Manejo Unicode / Pares Sustitutos

El soporte Unicode completo está disponible pero **deshabilitado por defecto** por rendimiento. Habilítalo por archivo o globalmente:

```harbour
// Por archivo (por defecto — rápido)
hDict := ParseJsonDictionary( cJson )

// Decodificación explícita (más lento — para secuencias \uXXXX)
hDict := ParseJsonDictionary( cJson, .T. )
```

Los pares sustitutos (ej. emoji `😀` = `\uD83D\uDE00`) se combinan correctamente.

## B.4 Limitaciones del Parser JSON — Detalle Completo

`ParseJsonDictionary()` es un parser **solo para objetos planos**. Hará:

- ✅ Parsear: `{"clave": "valor", "clave2": "valor2"}`
- ✅ Manejar comillas escapadas: `{"clave": "di \"hola\""}`
- ✅ Desescapar `\n`, `\t`, `\r`, `\\`
- ✅ Decodificar `\uXXXX` cuando está habilitado
- ❌ Ignorar: objetos anidados `{"a": {"b": "c"}}`
- ❌ Ignorar: arreglos `{"a": ["x","y"]}`
- ❌ Tratar como cadena: números, `true`, `false`, `null`
- ❌ Fallar con: `"` sin escapar dentro de valores

**Mejor práctica:** Mantén el JSON plano y solo con cadenas.

## B.5 Efectos Secundarios del Formato de Fecha

`SetLanguage()` **cambia globalmente** el formato de fecha de Harbour vía `SET DATE FORMAT TO`. Esto afecta a toda la aplicación:

- `ES`, `PT` → `DD/MM/YYYY`
- `EN` → `MM/DD/YYYY`

Si tu app necesita formato de fecha fijo sin importar el idioma, guárdalo y restáuralo alrededor de las llamadas a `SetLanguage()`.

## B.6 Convención de Nombres de Archivo

Los archivos de idioma deben:

- Estar en `<cBasePath>\i18n\`
- Llamarse `<lang>.json` (minúsculas), ej. `en.json`, `es.json`, `pt.json`
- Ser JSON plano válido con valores de cadena
- Estar codificados en UTF-8 (recomendado; ANSI funciona para solo-ASCII)

Los códigos de idioma se extraen del nombre de archivo, se convierten a mayúsculas, y se almacenan en `aAvailableLangs` si el archivo parsea.

---

**Fin del manual / End of manual.**