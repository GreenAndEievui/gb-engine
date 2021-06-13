INCLUDE "include/banks.inc"
INCLUDE "include/directions.inc"
INCLUDE "include/entity.inc"
INCLUDE "include/entity_script.inc"
INCLUDE "include/graphics.inc"
INCLUDE "include/hardware.inc"

SECTION "Scripted Entity Definition", ROM0

ScriptedEntity::
    far_pointer ScriptedEntityLogic
    far_pointer SlimeMetasprites
    far_pointer RenderMetaspriteDirection.native

SECTION "Scripted Entity Logic", ROMX

    define_fields
    field DAMAGE_ENABLE
    field COUNTER
    field TARGET_PLAYER
    field ANIM

ScriptedEntityLogic:
    ; Check the Field array to see if we've initialized.
    ld h, HIGH(wEntityFieldArray)
    ld l, c
    ld a, [hli]
    ld d, [hl]
    or a, d
    jr nz, .skipInit
        ; Set Script
        ld a, HIGH(ScriptedEntityScript)
        ld [hld], a
        ld [hl], LOW(ScriptedEntityScript)
.skipInit
    ASSERT DAMAGE_ENABLE == 0
    inc l
    inc l
    ld a, [hl]
    and a, a
    jr z, .noDamage
    ; Check for damage.
    ld h, HIGH(wEntityArray)
    ld a, Entity_CollisionData
    add a, c
    ld l, a
    ASSERT Entity_CollisionData + 1 == Entity_Health
    ld a, [hli]
    and a, a
    jr z, .noDamage ; No damage? Return.
        and a, DAMAGE_MASK ; Ignore damage effects
        ld d, a
        ld a, [hl]
        sub a, d
        ASSERT Entity_CollisionData + 1 == Entity_Health
        ld [hld], a
        xor a, a
        ld [hl], a ; Clear old damage.
        ld h, HIGH(wEntityFieldArray)
        ld l, c
        ld a, LOW(ScriptedEntityScript.damage)
        ld [hli], a
        ld [hl], HIGH(ScriptedEntityScript.damage)
.noDamage
    ; Run the script thread
    call HandleEntityScript
    ret

ScriptedEntityScript:
    ; Enable the entity to take damage.
    setf DAMAGE_ENABLE, 1
    setf TARGET_PLAYER, 0

.chase
    ; Wait some frames before moving.
    randf COUNTER, %100001
    forf COUNTER
        animate ANIM, %1000, 0, 4
        yield
    endfor
    ; Move for a few frames.
    randf COUNTER, %11
    forf COUNTER
        animate ANIM, %1000, 0, 4
        chase_player TARGET_PLAYER
        attack_playerf COUNTER
        yield
    endfor
    ; Loop.
    jump .chase

.damage
    ; Get knocked back for 60 frames
    setf DAMAGE_ENABLE, 0 ; Disable damage during knockback.
    seta Entity_InvTimer, 12 ; Use InvTimer for automatic animation!
    fora Entity_InvTimer
        move ; Enemies set velocity to the knockback direction, so just move!
        yield
    endfor
    setf DAMAGE_ENABLE, 1 ; Re-enable damage when done.
    seta Entity_InvTimer, 0
    jump .chase ; Go back to chase when you're done.

SlimeMetasprites:
    dw .normal
    dw .flip
    dw .normal
    dw .flip
    dw .bounce
    dw .bounceFlip
    dw .bounce
    dw .bounceFlip

.normal
    db -8, -8, $86, OAMF_XFLIP
    db -8, 0, $84, OAMF_XFLIP
    db METASPRITE_END
.bounce
    db -8, -8, $8A, OAMF_XFLIP
    db -8, 0, $88, OAMF_XFLIP
    db METASPRITE_END
.flip
    db -8, -8, $84, 0
    db -8, 0, $86, 0
    db METASPRITE_END
.bounceFlip
    db -8, -8, $88, 0
    db -8, 0, $8A, 0
    db METASPRITE_END