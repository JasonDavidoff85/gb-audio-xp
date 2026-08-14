; ------------------------------------------------------------------------------
; Constants
; ------------------------------------------------------------------------------
; Number of bytes in the tileset for the game.
DEF len_Tileset EQU 864

; WRAM location for Object (Sprite) OAM data that is transferred to VRAM via DMA
; at the end of each frame during the VBLANK period.
DEF pSpriteOAM EQU $C100

; Number of IncCh1Squares calls to skip between actual sprite movements.
DEF CH1_SQUARE_THRESHOLD EQU 2


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

; ------------------------------------------------------------------------------
; CH2 A-hold box tile indexes (3 rows x 6 columns). Row 1 columns 3-4 and row 3
; columns 3-4 share a single tile. Fill in the actual tile indexes below.
; ------------------------------------------------------------------------------
DEF CH2_R1C1_TILE   EQU 26
DEF CH2_R1C2_TILE   EQU 38
DEF CH2_R1C3C4_TILE EQU 44
DEF CH2_R1C5_TILE   EQU 46
DEF CH2_R1C6_TILE   EQU 32
DEF CH2_R2C1_TILE   EQU 28
DEF CH2_R2C2_TILE   EQU 40
DEF CH2_R2C3_TILE   EQU 54
DEF CH2_R2C4_TILE   EQU 54
DEF CH2_R2C5_TILE   EQU 48
DEF CH2_R2C6_TILE   EQU 34
DEF CH2_R3C1_TILE   EQU 30
DEF CH2_R3C2_TILE   EQU 42
DEF CH2_R3C3C4_TILE EQU 52
DEF CH2_R3C5_TILE   EQU 50
DEF CH2_R3C6_TILE   EQU 36

; ------------------------------------------------------------------------------
; CH2 A-hold box: panning override. When CH2 is panned left, columns 1-3 all
; switch to this tile (columns 4-6 stay on the default tiles above). When
; panned right, columns 4-6 switch to it instead (columns 1-3 stay default).
; ------------------------------------------------------------------------------
DEF CH2_BOX_PAN_TILE EQU 24