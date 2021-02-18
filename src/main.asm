INCLUDE "include/hardware.inc"
INCLUDE "include/defines.inc"
include "include/tiles.inc"


SECTION "VBlankInterrupt", ROM0[$40]
    ; Save register state
    push af
    push bc
    push de
    push hl
    jp VBlank


SECTION "Header", ROM0[$100]
	di
	jp EntryPoint
	ds $150 - $104, 0


SECTION "Entry point", ROM0
EntryPoint:
	jp Main


SECTION "Main", ROM0
Main:
    ld sp, $FFFE ; Reset Stack
    call Initialize

    ld de, Player ; Spawn Player at 16, 16
    ld bc, $1010
    call SpawnEntity


.loop
    xor a ; ld a, 0
    ld bc, wShadowOAM.end - wShadowOAM
    ld hl, wShadowOAM
    call OverwriteBytes
    ldh [hOAMIndex], a ; Reset the OAM index.

    call HandleEntities

    halt
    nop
    jr .loop


_hl_::
    jp hl


SECTION "Initialize", ROM0
Initialize:
    ; Wait to turn off the screen
    ld a, 144
    ld hl, rLY
.waitVBlank
    cp a, [hl]
    jr nz, .waitVBlank
    xor a ; Turn off the screen
    ld [rLCDC], a

; Enable VBlank interrupts
    ld a, IEF_VBLANK
    ld [rIE], a

; Clear VRAM, SRAM, and WRAM
    ld hl, _VRAM
    ld bc, RAM_LENGTH * 3
    xor a
    call OverwriteBytes

; Load the OAM Routine into HRAM
	ld hl, OAMDMA
	ld b, OAMDMA.end - OAMDMA 
    ld c, LOW(hOAMDMA)
.copyOAMDMA
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, .copyOAMDMA

; add a black tile to ram
    ld a, $FF
    ld bc, $0010
    ld hl, $8010
    call OverwriteBytes

;Load Tiles
    ld bc, DebugTiles.end - DebugTiles
    ld hl, DebugTiles
    ld de, VRAM_TILES_BG
    call MemCopy
    
    ld bc, GfxOctaviaMain.end - GfxOctaviaMain
    ld hl, GfxOctaviaMain
    ld de, VRAM_TILES_OBJ
    call MemCopy

    call LoadMetatileMap

; Configure Default Pallet
    ld a, %11100100 ; Black, Dark, Light, White
    ld hl, rBGP
    ld [hl], a
    ld a, %11010000 ; Black, Light, White
    ld hl, rOBP0
    ld [hl], a
    ld a, %11100100 ; Black, Dark, Light
    ld hl, rOBP1
    ld [hl], a

; Re-enable the screen
    ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON | LCDCF_OBJ16
    ld [rLCDC], a
    reti


SECTION "VBlank", ROM0
; Verticle Screen Blanking
VBlank:
    call UpdateInput

    ; push wShadowOAM to OAM though DMA
    ld a, high(wShadowOAM)
    call hOAMDMA

    ; Restore register state
    pop hl
    pop de
    pop bc
    pop af
    reti


SECTION "OAM DMA routine", ROM0
; OAM DMA prevents access to most memory, but never HRAM.
; This routine starts an OAM DMA transfer, then waits for it to complete.
; It gets copied to HRAM and is called there from the VBlank handler
OAMDMA:
	ldh [rDMA], a
	ld a, MAXIMUM_SPRITES
.wait
	dec a
	jr nz, .wait
	ret
.end


SECTION UNION "Shadow OAM", WRAM0,ALIGN[8]
wShadowOAM::
	ds MAXIMUM_SPRITES * 4
.end


SECTION "OAM DMA", HRAM
; Location of the copied OAM DMA Routine
hOAMDMA:
	ds OAMDMA.end - OAMDMA


SECTION "OAM Index", HRAM
; Used to order sprites in shadow OAM
hOAMIndex:: ds 1