
INCLUDE "include/directions.inc"
INCLUDE "include/entities.inc"
INCLUDE "include/players.inc"
INCLUDE "include/switch.inc"

SECTION "Octavia AI", ROMX

OctaviaPlayerLogic::
    ; Always start by offsetting frame by facing direction
    ld a, [wOctavia_Direction]
    ld [wOctavia_Frame], a

    ; Check for damage
    ld a, [wOctavia_InvTimer] ; Check the timer...
    and a, a ; If the inv timer is running, no damage!
    jr z, .acceptDamage
    ; If we're here and not accepting damage, set it to 0
    xor a, a
    ld [wOctavia_CollisionData], a
    ld a, [wOctavia_InvTimer]
    jr .decTimer
.acceptDamage
    ld a, [wOctavia_CollisionData] ; Load the collision data
    and a, a
    jr z, .noDamage
    ld a, PLAYER_STATE_HURT
    ld [wOctavia_State], a 
    ld a, KNOCK_FRAMES
    ld [wOctavia_Timer], a
    ; Next, set the timer. This falls through.
    ld a, INVINCIBLE_FRAMES + 1
.decTimer
    dec a
    ld [wOctavia_InvTimer], a
.noDamage
.activeControl

    ld a, [wOctavia_State]
    switch
        case PLAYER_STATE_NORMAL, OctaviaActiveNormal
        case PLAYER_STATE_HURT, OctaviaDamage
        case PLAYER_STATE_FIRE_WAND, OctaviaFireRod
    end_switch

OctaviaActiveNormal: ; How to move.

    ; Is this the active player?
    ld a, [wActivePlayer]
    ASSERT PLAYER_OCTAVIA == 0
    and a, a
    ret nz ; For now, skip processing if the entity is not active.
    
    ; Attack check
    ld a, [wOctaviaEquipped]
    ld b, a
    ld hl, wOctavia_State
    call UseItemCheck
.activeMove
    ld bc, PLAYER_OCTAVIA * sizeof_Entity
    call PlayerInputMovement
.transitionCheck
    ld a, [wOctavia_YPos]
    ld b, a
    ld a, [wOctavia_XPos]
    ld c, a
    call ScreenTransitionCheck
.activeScroll
    ; Scroll
    ld a, [wOctavia_YPos]
    sub a, 80 + 8
    ld e, a
    ld a, [wOctavia_XPos]
    sub a, 72 + 8
    ld d, a
    jp SetScrollBuffer
    ret

; Damage should be a function, not a per-player state.
OctaviaDamage:
    ld bc, PLAYER_OCTAVIA * sizeof_Entity
    call PlayerDamage
.damageScroll
    ; Scroll
    ld a, [hli]
    sub a, 80 + 8
    ld e, a
    ld a, [hl]
    sub a, 72 + 8
    ld d, a
    jp SetScrollBuffer

OctaviaFireRod:
    ld a, [wOctavia_Flags]
    and a, a
    jr nz, .skipInit ; Are the flags == 0? initiallize!
    ld [wOctavia_Timer], a
    inc a
    ld [wOctavia_Flags], a
.skipInit
    ld a, [wOctavia_Timer]
    inc a
    ld [wOctavia_Timer], a
    cp a, 4 + 1 ; 4 frame delay...
    ret c
    ld a, [wOctavia_Frame]
    add a, FRAMEOFF_SWING
    ld [wOctavia_Frame], a
    ld a, [wOctavia_Timer]
    cp a, 8 + 4 + 1 ; 8 frame action!
    ret c
    ASSERT PLAYER_STATE_NORMAL == 0
    ld a, [wOctavia_YPos]
    ld c, a
    ld a, [wOctavia_XPos]
    ld b, a
    ld de, PlayerSpell
    call SpawnEntity
    xor a, a
    ld [wOctavia_State], a
    ld a, [wOctavia_Direction]
    ASSERT DIR_DOWN == 0
    and a, a
    jr z, .down
    ASSERT DIR_UP == 1
    dec a
    jr z, .up
    ASSERT DIR_RIGHT == 2
    inc l
    dec a
    jr z, .right
    ASSERT DIR_LEFT == 3
.left
    ld a, -3
    ld [hl], a
    ret
.down
    ld a, 3
    ld [hl], a ; Copy/pasting this is faster and smaller than jr.
    ret
.up
    ld a, -3
    ld [hl], a
    ret
.right
    ld a, 3
    ld [hl], a
    ret
