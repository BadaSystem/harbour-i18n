/*
BadaSystem
Program       : main
Module        : main.prg
Compiler      : MINIGUI - Harbour Win32 GUI
Compiler-C    : BCC 32 bit
Author        : Marcos Jarrín
Email         : marvijarrin@gmail.com
Website       : badasystem.com
Date          : 03/09/2026
Update        : 15/09/2026
Rev           : 1.0
SPDX-License-Identifier: MIT
*/

// Includes MiniGUI Extended constants and definitions
#include "minigui.ch"

/*
Procedure: Main
Purpose:
    Main entry point of the application.
    Initializes the i18n library and launches the main window.
Notes:
    - HB_SetCodePage("UTF8") must be the FIRST line to support UTF-8 characters
    - Enables full century for dates (SET CENTURY ON)
    - Uses InitI18n() to load the translation dictionary
*/
PROCEDURE Main()
    LOCAL cPath := GetStartUpFolder()

    // Sets the codepage to UTF-8 to support international characters
    HB_SetCodePage( "UTF8" )
    
    // Enables full century in dates (YYYY instead of YY)
    SET CENTURY ON

    // Initializes the i18n library in English ("EN") using the startup folder
    // If it fails, displays an error message and terminates
    IF ! InitI18n( "EN", cPath )
        MsgBox( "Failed to initialize i18n library.", "Error" )
        RETURN
    ENDIF

    // Launches the main application window
    ModuleMainWindow()
RETURN

/*
Procedure: ModuleMainWindow
Purpose:
    Defines and activates the main window with all its controls.
Controls:
    - Labels for title, subtitle, and captions
    - RadioGroup for language selection (English/Spanish/Portuguese)
    - Labels to display sample text and parameter tests
    - Buttons to change language and close
    - StatusBar with version information
*/
STATIC PROCEDURE ModuleMainWindow()
    // Defines the main window
    DEFINE WINDOW WinMain ;
        AT 0, 0 WIDTH 560 HEIGHT 420 ;           // Position and size
        TITLE T( "app.title" ) ;                  // Translated title
        MAIN ;                                     // Main window flag
        FONT 'ARIAL' SIZE 10 ;                    // Default font
        ON INIT InitWindow() ;                    // Procedure called on initialization
        NOSIZE                                     // Not resizable

    // Label for the main title (blue, bold, size 14)
    @ 20, 20 LABEL lblTitle OF WinMain ;
        VALUE T( "app.title" ) ;
        WIDTH 520 HEIGHT 24 ;
        FONT 'ARIAL' SIZE 14 BOLD FONTCOLOR BLUE

    // Label for the subtitle (gray, size 10)
    @ 50, 20 LABEL lblSubtitle OF WinMain ;
        VALUE T( "app.subtitle" ) ;
        WIDTH 520 HEIGHT 20 ;
        FONT 'ARIAL' SIZE 10 FONTCOLOR GRAY

    // Label for the "Language:" caption
    @ 100, 20 LABEL lblLanguage OF WinMain ;
        VALUE T( "lbl.language" ) ;
        WIDTH 100 HEIGHT 24

    // RadioGroup for language selection (3 options: English, Spanish, Portuguese)
    // Displayed horizontally with initial value 1 (English)
    // ON CHANGE event triggers OnLangChange() when user changes selection
    @ 100, 130 RADIOGROUP radioLang OF WinMain ;
        OPTIONS { "English", "Español", "Portugues" } ;
        VALUE 1 ;
        WIDTH 100 ;
        HORIZONTAL ;
        ON CHANGE OnLangChange()

    // Label to display the current language (NAVY color)
    @ 130, 20 LABEL lblCurrent OF WinMain ;
        VALUE T( "lbl.current" ) + " " + GetCurrentLanguage() ;
        WIDTH 200 HEIGHT 24 ;
        FONTCOLOR NAVY

    // Label for the "Sample text:" caption
    @ 170, 20 LABEL lblSampleCaption OF WinMain ;
        VALUE T( "lbl.sample" ) ;
        WIDTH 120 HEIGHT 24

    // Label to display the translated welcome text
    @ 170, 160 LABEL lblSample OF WinMain ;
        VALUE T( "msg.welcome" ) ;
        WIDTH 380 HEIGHT 24

    // Label for the "Parameter test:" caption
    @ 210, 20 LABEL lblParamCaption OF WinMain ;
        VALUE T( "lbl.param.test" ) ;
        WIDTH 150 HEIGHT 24

    // Label to display parameter substitution test {1}, {2}
    // T() replaces {1} with "User" and {2} with "5"
    @ 210, 160 LABEL lblParam OF WinMain ;
        VALUE T( "msg.param.test", "User", "5" ) ;
        WIDTH 380 HEIGHT 24 ;
        FONTCOLOR MAROON

    // "Change Language" button - executes DoChangeLanguage() on click
    @ 280, 120 BUTTON btnChange OF WinMain ;
        CAPTION T( "btn.change" ) ;
        WIDTH 140 HEIGHT 32 ;
        ACTION DoChangeLanguage()

    // "Close" button - releases the main window
    @ 280, 280 BUTTON btnClose OF WinMain ;
        CAPTION T( "btn.close" ) ;
        WIDTH 100 HEIGHT 32 ;
        ACTION WinMain.Release

    // Defines the status bar with version information
    DEFINE STATUSBAR OF WinMain
        STATUSITEM "i18n Library v5.0" WIDTH 200
    END STATUSBAR

    // Ends window definition
    END WINDOW

    // Defines hotkey: ESC to close the window
    _DefineHotKey( "WinMain", 0, VK_ESCAPE, {|| WinMain.Release } )
    
    // Centers the window on screen
    CENTER WINDOW WinMain
    
    // Activates (shows) the window
    ACTIVATE WINDOW WinMain
RETURN

/*
Procedure: InitWindow
Purpose:
    Initializes window state after creation.
    Configures the RadioGroup based on the currently loaded language.
*/
STATIC PROCEDURE InitWindow()
    // Checks current language and sets the corresponding RadioGroup option
    DO CASE
        CASE GetCurrentLanguage() == "ES"
            // If language is Spanish, select option 2
            WinMain.radioLang.Value := 2
        CASE GetCurrentLanguage() == "PT"
            // If language is Portuguese, select option 3
            WinMain.radioLang.Value := 3
        OTHERWISE
            // Default (English), select option 1
            WinMain.radioLang.Value := 1
    ENDCASE
    
    // Updates entire UI with translations
    RefreshUI()
RETURN

/*
Procedure: OnLangChange
Purpose:
    Event triggered when user changes the RadioGroup selection.
    Updates the "Current:" label immediately without changing the language yet.
*/
STATIC PROCEDURE OnLangChange()
    LOCAL nVal  := WinMain.radioLang.Value    // Gets selected value (1, 2, or 3)
    LOCAL cCode := ""                          // Resulting language code

    // Converts RadioGroup index to language code
    DO CASE
        CASE nVal == 1; cCode := "EN"         // English
        CASE nVal == 2; cCode := "ES"         // Spanish
        CASE nVal == 3; cCode := "PT"         // Portuguese
        OTHERWISE;    cCode := "EN"            // Default
    ENDCASE

    // Updates the current language label
    WinMain.lblCurrent.Value := T( "lbl.current" ) + " " + cCode
    
    // Forces window redraw
    WinMain.Redraw()
RETURN

/*
Procedure: RefreshUI
Purpose:
    Updates ALL UI elements with translations from the currently loaded language.
    Must be called after every SetLanguage() execution.
*/
STATIC PROCEDURE RefreshUI()
    // Updates window title
    WinMain.Title              := T( "app.title" )
    
    // Updates all labels
    WinMain.lblTitle.Value     := T( "app.title" )
    WinMain.lblSubtitle.Value  := T( "app.subtitle" )
    WinMain.lblLanguage.Value  := T( "lbl.language" )
    WinMain.lblCurrent.Value   := T( "lbl.current" ) + " " + GetCurrentLanguage()
    WinMain.lblSampleCaption.Value := T( "lbl.sample" )
    WinMain.lblSample.Value    := T( "msg.welcome" )
    WinMain.lblParamCaption.Value  := T( "lbl.param.test" )
    WinMain.lblParam.Value     := T( "msg.param.test", "User", "5" )
    
    // Updates button captions
    WinMain.btnChange.Caption  := T( "btn.change" )
    WinMain.btnClose.Caption   := T( "btn.close" )
    
    // Forces full window redraw
    WinMain.Redraw()
RETURN

/*
Procedure: DoChangeLanguage
Purpose:
    Executes the actual language change when the user clicks the 
    "Change Language" button.
    Validates, loads the new language, and updates the UI.
*/
STATIC PROCEDURE DoChangeLanguage()
    LOCAL cNewLang := ""            // New language code to load
    LOCAL nSel     := WinMain.radioLang.Value  // Current RadioGroup selection
    LOCAL cFile    := ""            // Path to JSON file to verify

    // Determines language code based on RadioGroup selection
    DO CASE
        CASE nSel == 1; cNewLang := "EN"      // English
        CASE nSel == 2; cNewLang := "ES"      // Spanish
        CASE nSel == 3; cNewLang := "PT"      // Portuguese
        OTHERWISE;    cNewLang := "EN"         // Default
    ENDCASE

    // Checks if already in the selected language
    IF cNewLang == GetCurrentLanguage()
        MsgInfo( "Already in: " + cNewLang, "Info" )
        RETURN
    ENDIF

    // Builds full path to the language JSON file
    cFile := GetStartUpFolder() + "\i18n\" + Lower( cNewLang ) + ".json"
    
    // Verifies file exists before attempting to load it
    IF ! File( cFile )
        MsgStop( "File NOT found:" + Chr(13) + cFile, "Error" )
        RETURN
    ENDIF

    // Attempts to change language by loading the new dictionary
    IF SetLanguage( cNewLang )
        // Success: updates entire UI
        RefreshUI()
        
        // Syncs RadioGroup with the loaded language
        DO CASE
            CASE cNewLang == "ES"; WinMain.radioLang.Value := 2
            CASE cNewLang == "PT"; WinMain.radioLang.Value := 3
            OTHERWISE;             WinMain.radioLang.Value := 1
        ENDCASE
        
        // Shows translated confirmation message
        MsgInfo( T( "msg.changed", cNewLang ), T( "app.title" ) )
    ELSE
        // Error loading language
        MsgStop( "Failed to change language", "Error" )
    ENDIF
RETURN