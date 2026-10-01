/*
BadaSystem
Program       : i18n_lib
Module        : i18n_lib.prg
Compiler      : MINIGUI - Harbour Win32 GUI
Author        : Marcos Jarrín
Email         : marvijarrin@gmail.com
Website       : badasystem.com
Date          : 01/09/2026
Update        : 15/09/2026
Rev           : 2.1
SPDX-License-Identifier: MIT
Description:
Production-ready i18n library for Harbour/MiniGUI Extended.
Zero dependencies, zero DBF, Robust JSON parser.
Unicode escape decoder (\uXXXX) with surrogate pair support.
Public API:
InitI18n( cLang [, cPath] )         -> Initialize with language
SetLanguage( cLang )                -> Switch language at runtime
T( cKey [, xP1, xP2...] )           -> Translate key with params
GetCurrentLanguage()                -> Returns current language code
GetAvailableLanguages()             -> Returns array of available langs
GetTranslationHash()                -> Returns current hLang hash (clone)
ParseJsonDictionary( cJson [, lDecodeUnicode] ) -> Parse JSON dict
*/
#include "minigui.ch"

// ─────────────────────────────────────────────────────────────
// Module state (STATIC — zero globals)
// ─────────────────────────────────────────────────────────────
STATIC hLang           := { => }
STATIC hFallback       := { => }
STATIC cCurrentLang    := "EN"
STATIC cBasePath       := ""
STATIC aAvailableLangs := {}
STATIC lInitialized    := .F.
STATIC hKeyCache       := { => }  // Performance cache
STATIC nCacheHits      := 0
STATIC nCacheMisses    := 0

// ─────────────────────────────────────────────────────────────
// PUBLIC API
// ─────────────────────────────────────────────────────────────
/*
Function: InitI18n
Purpose:
Initialize the i18n library. Must be called once at startup.
Parameters:
cLang  (C) -> Initial language code ("EN", "ES", "PT", etc.)
cPath  (C) -> Optional: base path where /i18n/ folder lives.
If empty, uses GetStartUpFolder()
Returns:
L -> .T. on success, .F. on failure
Example:
InitI18n( "EN" )
InitI18n( "ES", "C:\MyApp" )
*/
FUNCTION InitI18n( cLang, cPath )
   LOCAL lOk       := .F.
   LOCAL cLangNorm := ""
   LOCAL cPathNorm := ""
   
   IF cLang == NIL
      cLang := "EN"
   ENDIF
   IF cPath == NIL
      cPath := ""
   ENDIF
   
   cLangNorm := Upper( AllTrim( cLang ) )
   
   IF Empty( cPath )
      cPathNorm := GetStartUpFolder()
   ELSE
      cPathNorm := cPath
   ENDIF
   
   // Remove trailing slash if present
   IF Right( cPathNorm, 1 ) == "\" .OR. Right( cPathNorm, 1 ) == "/"
      cPathNorm := SubStr( cPathNorm, 1, Len( cPathNorm ) - 1 )
   ENDIF
   
   cBasePath := cPathNorm
   
   // Scan available languages
   aAvailableLangs := _ScanAvailableLanguages()
   
   // Load requested language
   lOk := SetLanguage( cLangNorm )
   
   IF lOk
      lInitialized := .T.
   ENDIF
   
RETURN lOk

/*
Function: SetLanguage
Purpose:
Switch language at runtime. Loads JSON and updates internal hash.
Parameters:
cLang  (C) -> Language code ("EN", "ES", "PT", etc.)
Returns:
L -> .T. on success, .F. on failure (falls back to embedded EN)
Example:
SetLanguage( "ES" )
*/
FUNCTION SetLanguage( cLang )
   LOCAL cFile     := ""
   LOCAL cJson     := ""
   LOCAL hDict     := { => }
   LOCAL lOk       := .F.
   LOCAL cLangNorm := ""
   LOCAL oErr
   
   IF cLang == NIL
      cLang := "EN"
   ENDIF
   
   cLangNorm := Upper( AllTrim( cLang ) )
   
   // Validate supported languages
   IF !( cLangNorm $ "EN,ES,PT" )
      cLangNorm := "EN"
   ENDIF
   
   cFile := cBasePath + "\i18n\" + Lower( cLangNorm ) + ".json"
   
   TRY
      IF File( cFile )
         cJson := MemoRead( cFile )
         
         IF ValType( cJson ) == "C" .AND. ! Empty( cJson )
            // Parse WITHOUT Unicode decoder (default) for performance
            hDict := ParseJsonDictionary( cJson )
            
            IF ValType( hDict ) == "H" .AND. Len( hDict ) > 0
               hLang        := hDict
               cCurrentLang := cLangNorm
               lOk          := .T.
               
               // Clear cache on language change
               hKeyCache   := { => }
               nCacheHits  := 0
               nCacheMisses := 0
               
               // Set date format per locale
               DO CASE
                  CASE cCurrentLang == "ES"
                     SET DATE FORMAT TO "DD/MM/YYYY"
                  CASE cCurrentLang == "PT"
                     SET DATE FORMAT TO "DD/MM/YYYY"
                  OTHERWISE
                     SET DATE FORMAT TO "MM/DD/YYYY"
               ENDCASE
            ENDIF
         ENDIF
      ENDIF
   CATCH oErr
      // Log error but continue with fallback
      #ifdef __DEBUG__
         QOut( "i18n Error loading " + cFile + ": " + oErr:Description )
      #endif
   END
   
   // Fallback: embedded English dictionary
   IF ! lOk
      hLang        := _DefaultEnDictionary()
      cCurrentLang := "EN"
      lOk          := .T.
   ENDIF
   
   // Always keep a fallback hash (English)
   IF Len( hFallback ) == 0
      hFallback := _DefaultEnDictionary()
   ENDIF
   
RETURN lOk

/*
Function: T
Purpose:
Translate a key. Supports parameter substitution {1}, {2}, ...
Parameters:
cKey   (C) -> Translation key
xP1..9 (X) -> Optional substitution parameters
Returns:
C -> Translated string, or raw key if not found
Example:
T( "app.title" )
T( "msg.welcome", "John" )       -> "Welcome, John!"
T( "err.field", "NAME", "10" )   -> "Field 'NAME' max 10"
*/
FUNCTION T( cKey, xP1, xP2, xP3, xP4, xP5, xP6, xP7, xP8, xP9 )
   LOCAL cResult  := ""
   LOCAL cRaw     := ""
   LOCAL cCacheKey := ""
   
   IF cKey == NIL .OR. Empty( cKey )
      RETURN ""
   ENDIF
   
   // Build cache key (only if no parameters)
   IF xP1 == NIL .AND. xP2 == NIL .AND. xP3 == NIL .AND. ;
      xP4 == NIL .AND. xP5 == NIL .AND. xP6 == NIL .AND. ;
      xP7 == NIL .AND. xP8 == NIL .AND. xP9 == NIL
      cCacheKey := cCurrentLang + ":" + cKey
      
      // Check cache
      IF hb_HHasKey( hKeyCache, cCacheKey )
         nCacheHits++
         RETURN hKeyCache[ cCacheKey ]
      ENDIF
      nCacheMisses++
   ENDIF
   
   // Lookup in current language
   IF hb_HHasKey( hLang, cKey )
      cRaw := hLang[ cKey ]
   ELSEIF hb_HHasKey( hFallback, cKey )
      cRaw := hFallback[ cKey ]
      #ifdef __DEBUG__
         QOut( "i18n Warning: Key '" + cKey + "' not found in " + cCurrentLang + ", using fallback" )
      #endif
   ELSE
      #ifdef __DEBUG__
         QOut( "i18n Error: Key '" + cKey + "' not found in any language" )
      #endif
      RETURN cKey
   ENDIF
   
   cResult := _SubstituteParams( cRaw, xP1, xP2, xP3, xP4, xP5, ;
                                  xP6, xP7, xP8, xP9 )
   
   // Cache result if no parameters
   IF ! Empty( cCacheKey )
      hKeyCache[ cCacheKey ] := cResult
   ENDIF
   
RETURN cResult

/*
Function: GetCurrentLanguage
Purpose:
Returns the current active language code.
Returns:
C -> "EN", "ES", "PT", etc.
*/
FUNCTION GetCurrentLanguage()
RETURN cCurrentLang

/*
Function: GetAvailableLanguages
Purpose:
Returns array of available language codes found in /i18n/ folder.
Returns:
A -> { "EN", "ES", "PT", ... }
*/
FUNCTION GetAvailableLanguages()
RETURN AClone( aAvailableLangs )

/*
Function: GetTranslationHash
Purpose:
Returns a CLONE of the current translation hash (read-only safe).
Returns:
H -> Hash clone
*/
FUNCTION GetTranslationHash()
RETURN hb_HClone( hLang )

/*
Function: IsInitialized
Purpose:
Returns whether InitI18n() has been called successfully.
Returns:
L -> .T. if initialized
*/
FUNCTION IsInitialized()
RETURN lInitialized

/*
Function: GetCacheStats
Purpose:
Returns cache performance statistics (for debugging).
Returns:
H -> Hash with hits, misses, hit_rate
*/
FUNCTION GetCacheStats()
   LOCAL hStats := { => }
   LOCAL nTotal := nCacheHits + nCacheMisses
   
   hStats[ "hits" ]      := nCacheHits
   hStats[ "misses" ]    := nCacheMisses
   hStats[ "hit_rate" ]  := IIf( nTotal > 0, nCacheHits / nTotal * 100, 0 )
   hStats[ "cache_size" ] := Len( hKeyCache )
   
RETURN hStats

// ─────────────────────────────────────────────────────────────
// PRIVATE HELPERS
// ─────────────────────────────────────────────────────────────
/*
Function: ParseJsonDictionary
Purpose:
Robust zero-dependency JSON parser for flat {"key":"value"} dictionaries.
Uses only core string functions. Always compiles and links.
Parameters:
cJson            (C) -> Raw JSON string
lDecodeUnicode   (L) -> OPTIONAL: .T. to decode \uXXXX sequences
                         .F. (default) to skip decoder for performance
Returns:
H -> Hash dictionary (empty if parse fails)
Example:
// Standard usage (no Unicode decoding — fast)
hDict := ParseJsonDictionary( cJson )
// With Unicode escape decoding (slower, for \uXXXX sequences)
hDict := ParseJsonDictionary( cJson, .T. )
Notes:
- Only supports flat {"key": "value"} format
- Does NOT support arrays, nested objects, numbers, booleans, null
- All values are treated as strings
*/
FUNCTION ParseJsonDictionary( cJson, lDecodeUnicode )
   LOCAL hDict    := { => }
   LOCAL aLines   := {}
   LOCAL cLine    := ""
   LOCAL nPos     := 0
   LOCAL cKey     := ""
   LOCAL cVal     := ""
   LOCAL nI       := 0
   LOCAL lDecode  := .F.
   LOCAL nLineNum := 0
   
   // Optional parameter guard (no DEFAULT — no common.ch)
   IF lDecodeUnicode == NIL
      lDecode := .F.
   ELSE
      lDecode := lDecodeUnicode
   ENDIF
   
   IF Empty( cJson )
      RETURN hDict
   ENDIF
   
   // Normalize line breaks
   cJson := StrTran( cJson, Chr(13) + Chr(10), Chr(10) )
   cJson := StrTran( cJson, Chr(13), Chr(10) )
   aLines := hb_ATokens( cJson, Chr(10) )
   
   FOR nI := 1 TO Len( aLines )
      nLineNum := nI
      cLine := AllTrim( aLines[ nI ] )
      
      // Skip empty / braces
      IF Empty( cLine ) .OR. cLine == "{" .OR. cLine == "}"
         LOOP
      ENDIF
      
      // Find opening quote of key
      nPos := At( '"', cLine )
      IF nPos == 0
         LOOP
      ENDIF
      cLine := SubStr( cLine, nPos + 1 )
      
      // Find closing quote of key
      nPos := At( '"', cLine )
      IF nPos == 0
         LOOP
      ENDIF
      cKey := SubStr( cLine, 1, nPos - 1 )
      
      // Validate key is not empty
      IF Empty( cKey )
         LOOP
      ENDIF
      
      // Move past key
      cLine := SubStr( cLine, nPos + 1 )
      
      // Find colon
      nPos := At( ':', cLine )
      IF nPos == 0
         LOOP
      ENDIF
      cLine := SubStr( cLine, nPos + 1 )
      
      // Find opening quote of value
      nPos := At( '"', cLine )
      IF nPos == 0
         LOOP
      ENDIF
      cLine := SubStr( cLine, nPos + 1 )
      
      // Find closing quote of value (handle escaped quotes)
      cVal := ""
      DO WHILE .T.
         nPos := At( '"', cLine )
         IF nPos == 0
            EXIT
         ENDIF
         
         // Check if quote is escaped
         IF nPos > 1 .AND. SubStr( cLine, nPos - 1, 1 ) == '\'
            cVal += SubStr( cLine, 1, nPos )
            cLine := SubStr( cLine, nPos + 1 )
         ELSE
            cVal += SubStr( cLine, 1, nPos - 1 )
            EXIT
         ENDIF
      ENDDO
      
      // Unescape common JSON sequences (always applied)
      cVal := StrTran( cVal, '\"', '"'  )
      cVal := StrTran( cVal, '\\', '\'  )
      cVal := StrTran( cVal, '\n', Chr(10) )
      cVal := StrTran( cVal, '\t', Chr(9)  )
      cVal := StrTran( cVal, '\r', Chr(13) )
      
      // ✅ OPTIONAL: Decode Unicode escape sequences \uXXXX
      IF lDecode
         cVal := _DecodeUnicodeEscapes( cVal )
      ENDIF
      
      hDict[ cKey ] := cVal
   NEXT
   
RETURN hDict

/*
Function: _DecodeUnicodeEscapes
Purpose:
Decode JSON Unicode escape sequences \uXXXX to UTF-8 characters.
Supports surrogate pairs for characters outside BMP.
Parameters:
cText  (C) -> Text containing \uXXXX sequences
Returns:
C -> Text with decoded UTF-8 characters
*/
STATIC FUNCTION _DecodeUnicodeEscapes( cText )
   // ✅ ALL LOCAL VARIABLES DECLARED AT THE TOP (E0004 Prevention)
   LOCAL cResult  := cText
   LOCAL nPos     := 0
   LOCAL cHex     := ""
   LOCAL nCode    := 0
   LOCAL cChar    := ""
   LOCAL nMaxIter := 1000  // Safety limit
   LOCAL nIter    := 0
   LOCAL cHex2    := ""    // Moved from inside IF block
   LOCAL nCode2   := 0     // Moved from inside IF block
   
   DO WHILE .T.
      nIter++
      IF nIter > nMaxIter
         EXIT  // Safety: prevent infinite loop
      ENDIF
      
      nPos := At( '\u', cResult )
      IF nPos == 0
         EXIT
      ENDIF
      
      IF nPos + 5 <= Len( cResult )
         cHex := SubStr( cResult, nPos + 2, 4 )
         
         // Validate hex
         IF _IsValidHex( cHex )
            nCode := _HexToDecimal( cHex )
            
            // Check for surrogate pair
            IF nCode >= 55296 .AND. nCode <= 56319  // High surrogate
               IF nPos + 11 <= Len( cResult ) .AND. ;
                  SubStr( cResult, nPos + 6, 2 ) == '\u'
                  cHex2 := SubStr( cResult, nPos + 8, 4 )
                  IF _IsValidHex( cHex2 )
                     nCode2 := _HexToDecimal( cHex2 )
                     IF nCode2 >= 56320 .AND. nCode2 <= 57343  // Low surrogate
                        // Combine surrogate pair
                        nCode := 65536 + ( nCode - 55296 ) * 1024 + ( nCode2 - 56320 )
                        cChar := _UnicodeToChar( nCode )
                        cResult := SubStr( cResult, 1, nPos - 1 ) + ;
                                   cChar + ;
                                   SubStr( cResult, nPos + 12 )
                        LOOP
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF
            
            cChar := _UnicodeToChar( nCode )
            cResult := SubStr( cResult, 1, nPos - 1 ) + ;
                       cChar + ;
                       SubStr( cResult, nPos + 6 )
         ELSE
            // Not valid hex, skip
            cResult := SubStr( cResult, 1, nPos + 1 ) + ;
                       SubStr( cResult, nPos + 2 )
         ENDIF
      ELSE
         EXIT
      ENDIF
   ENDDO
   
RETURN cResult

STATIC FUNCTION _IsValidHex( cHex )
   LOCAL lValid := .T.
   LOCAL nI     := 0
   LOCAL cChar  := ""
   
   IF Len( cHex ) != 4
      RETURN .F.
   ENDIF
   
   FOR nI := 1 TO 4
      cChar := Upper( SubStr( cHex, nI, 1 ) )
      IF !( cChar $ "0123456789ABCDEF" )
         lValid := .F.
         EXIT
      ENDIF
   NEXT
   
RETURN lValid

STATIC FUNCTION _HexToDecimal( cHex )
   LOCAL nResult := 0
   LOCAL nI      := 0
   LOCAL cChar   := ""
   LOCAL nVal    := 0
   
   cHex := Upper( cHex )
   
   FOR nI := 1 TO Len( cHex )
      cChar := SubStr( cHex, nI, 1 )
      DO CASE
         CASE cChar $ "0123456789"
            nVal := Val( cChar )
         CASE cChar == "A"
            nVal := 10
         CASE cChar == "B"
            nVal := 11
         CASE cChar == "C"
            nVal := 12
         CASE cChar == "D"
            nVal := 13
         CASE cChar == "E"
            nVal := 14
         CASE cChar == "F"
            nVal := 15
      ENDCASE
      nResult := nResult * 16 + nVal
   NEXT
   
RETURN nResult

STATIC FUNCTION _UnicodeToChar( nCode )
   LOCAL cResult := ""
   
   // Convert Unicode code point to UTF-8
   DO CASE
      CASE nCode < 128
         // ASCII
         cResult := Chr( nCode )
      CASE nCode < 2048
         // 2-byte UTF-8
         cResult := Chr( 192 + Int( nCode / 64 ) ) + ;
                    Chr( 128 + ( nCode % 64 ) )
      CASE nCode < 65536
         // 3-byte UTF-8
         cResult := Chr( 224 + Int( nCode / 4096 ) ) + ;
                    Chr( 128 + Int( ( nCode % 4096 ) / 64 ) ) + ;
                    Chr( 128 + ( nCode % 64 ) )
      CASE nCode < 1114112
         // 4-byte UTF-8 (for surrogate pairs)
         cResult := Chr( 240 + Int( nCode / 262144 ) ) + ;
                    Chr( 128 + Int( ( nCode % 262144 ) / 4096 ) ) + ;
                    Chr( 128 + Int( ( nCode % 4096 ) / 64 ) ) + ;
                    Chr( 128 + ( nCode % 64 ) )
   ENDCASE
   
RETURN cResult

/*
Function: _SubstituteParams
Purpose:
Replace {1}, {2}, ... in a string with provided parameters.
*/
STATIC FUNCTION _SubstituteParams( cStr, xP1, xP2, xP3, xP4, xP5, ;
                                   xP6, xP7, xP8, xP9 )
   LOCAL cResult := cStr
   LOCAL aParams := { xP1, xP2, xP3, xP4, xP5, xP6, xP7, xP8, xP9 }
   LOCAL nI      := 0
   LOCAL cVal    := ""
   
   FOR nI := 1 TO 9
      IF aParams[ nI ] == NIL
         EXIT
      ENDIF
      cVal := _ToString( aParams[ nI ] )
      cResult := StrTran( cResult, "{" + LTrim( Str( nI ) ) + "}", cVal )
   NEXT
   
RETURN cResult

/*
Function: _ToString
Purpose:
Convert any value to string safely.
*/
STATIC FUNCTION _ToString( xVal )
   LOCAL cResult := ""
   
   DO CASE
      CASE xVal == NIL
         cResult := ""
      CASE ValType( xVal ) == "C"
         cResult := xVal
      CASE ValType( xVal ) == "N"
         cResult := LTrim( Str( xVal ) )
      CASE ValType( xVal ) == "L"
         cResult := IIf( xVal, "true", "false" )
      CASE ValType( xVal ) == "D"
         cResult := DToC( xVal )
      OTHERWISE
         cResult := hb_ValToStr( xVal )
   ENDCASE
   
RETURN cResult

/*
Function: _ScanAvailableLanguages
Purpose:
Scan /i18n/ folder and return array of language codes.
Validates that files are valid JSON before adding to list.
*/
STATIC FUNCTION _ScanAvailableLanguages()
   LOCAL aResult := {}
   LOCAL aFiles  := {}
   LOCAL nI      := 0
   LOCAL cFile   := ""
   LOCAL cCode   := ""
   LOCAL cDir    := ""
   LOCAL cJson   := ""
   LOCAL hTest   := { => }
   
   cDir := cBasePath + "\i18n"
   
   IF ! IsDir( cDir )
      RETURN { "EN" }
   ENDIF
   
   aFiles := Directory( cDir + "\*.json" )
   
   FOR nI := 1 TO Len( aFiles )
      cFile := aFiles[ nI ][ 1 ]
      
      // Extract language code from filename (e.g., "en.json" -> "EN")
      IF Len( cFile ) >= 7 .AND. Right( cFile, 5 ) == ".json"
         cCode := Upper( Left( cFile, Len( cFile ) - 5 ) )
         
         IF Len( cCode ) >= 2 .AND. Len( cCode ) <= 5
            // Validate JSON file is readable and has content
            TRY
               cJson := MemoRead( cDir + "\" + cFile )
               IF ValType( cJson ) == "C" .AND. ! Empty( cJson )
                  hTest := ParseJsonDictionary( cJson )
                  IF ValType( hTest ) == "H" .AND. Len( hTest ) > 0
                     AAdd( aResult, cCode )
                  ENDIF
               ENDIF
            CATCH
               // Skip invalid files
            END
         ENDIF
      ENDIF
   NEXT
   
   IF Len( aResult ) == 0
      AAdd( aResult, "EN" )
   ENDIF
   
RETURN aResult

/*
Function: _DefaultEnDictionary
Purpose:
Embedded fallback English dictionary (used if JSON file missing).
*/
STATIC FUNCTION _DefaultEnDictionary()
   LOCAL h := { => }
   
   // ✅ No trailing spaces in keys
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