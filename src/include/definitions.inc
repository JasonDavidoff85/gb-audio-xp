; Number of bytes in the tileset for the game.
DEF len_Tileset EQU 64

; Number of bytes in the level's tilemap.
DEF len_LevelTilemap EQU 1024

; ------------------------------------------------------------------------------
; `macro WaitForVblank()`
;
; Loops until the LCD enters the vertical blanking period.
; ------------------------------------------------------------------------------
MACRO WaitForVblank
: ld a, [rLY]
  cp a, 144
  jr c, :-
ENDM

; ------------------------------------------------------------------------------
; `macro WaitForVblankEnd()`
;
; Loops until the LCD exits the vertical blanking period.
; ------------------------------------------------------------------------------
MACRO WaitForVblankEnd
: ld a, [rLY]
  cp 144
  jr nc, :-
ENDM

; Bitfield that stores current buttons being pressed on the Game Boy's joypad.
;
; - Bit 0 (`BUTTON_RIGHT`) - Right D-PAD
; - Bit 1 (`BUTTON_LEFT`) - Left D-PAD
; - Bit 2 (`BUTTON_UP`) - Up D-PAD
; - Bit 3 (`BUTTON_DOWN`) - Down D-PAD
; - Bit 4 (`BUTTON_A`) - A
; - Bit 5 (`BUTTON_B`) - B
; - Bit 6 (`BUTTON_SELECT`) - Select
; - Bit 7 (`BUTTON_START`) - Start
DEF bJoypadDown EQU $C020

; Bitfield that stores the buttons that were pressed as of the last joypad read.
;
; - Bit 0 (`BUTTON_RIGHT`) - Right D-PAD
; - Bit 1 (`BUTTON_LEFT`) - Left D-PAD
; - Bit 2 (`BUTTON_UP`) - Up D-PAD
; - Bit 3 (`BUTTON_DOWN`) - Down D-PAD
; - Bit 4 (`BUTTON_A`) - A
; - Bit 5 (`BUTTON_B`) - B
; - Bit 6 (`BUTTON_SELECT`) - Select
; - Bit 7 (`BUTTON_START`) - Start
DEF bJoypadPressed EQU $C021

; ------------------------------------------------------------------------------
; Constants
; ------------------------------------------------------------------------------

; Button mask for the right D-PAD button.
DEF BUTTON_RIGHT  EQU 1 << 0

; Button mask for the left D-PAD button.
DEF BUTTON_LEFT   EQU 1 << 1

; Button mask for the up D-PAD button.
DEF BUTTON_UP     EQU 1 << 2

; Button mask for the down D-PAD button.
DEF BUTTON_DOWN   EQU 1 << 3

; Button mask for the A button.
DEF BUTTON_A      EQU 1 << 4

; Button mask for the B button.
DEF BUTTON_B      EQU 1 << 5

; Button mask for the select button.
DEF BUTTON_SELECT EQU 1 << 6

; Button mask for the start button.
DEF BUTTON_START  EQU 1 << 7