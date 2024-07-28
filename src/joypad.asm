INCLUDE "definitions.inc"
INCLUDE "hardware.inc"

SECTION "Joypad", ROM0

; ------------------------------------------------------------------------------
; `func ReadJoypad`
;
; Reads the joypad buttons and saves their values to `bJoypadDown`. Also
; records which buttons were pressed as of this call to `bJoypadPressed`.
; ------------------------------------------------------------------------------
ReadJoypad::
    ; Read the "down" mask from the last frame
    ld a, [bJoypadDown]
    ld c, a
    ; Read the current controller buttons and store them into the "down" mask
    ld a, $20
    ld [rP1], a
    ld a, [rP1]
    ld a, [rP1]
    and $0F
    ld b, a
    ld a, $10
    ld [rP1], a
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    sla a
    sla a
    sla a
    sla a
    or b
    xor $FF
    ld [bJoypadDown], a
    ; Update the "just pressed" mask
    ld b, a
    ld a, c
    xor b
    and b
    ld [bJoypadPressed], a
    ret