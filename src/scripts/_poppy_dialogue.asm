
INCLUDE "include/players.inc"
INCLUDE "include/scripting.inc"
INCLUDE "include/text.inc"

SECTION "Poppy Dialogue", ROMX

PoppyGeneric::
    pause
    compare wPlayerWaitLink.poppy, wActivePlayer, .waitDialogue, .followDialogue

.waitDialogue
    poppy_text .waitText
    question_branch :++, :+
:   set_pointer wPlayerWaitLink.poppy, PLAYER_POPPY
:   end_script

.followDialogue
    poppy_text .followText
    question_branch :++, :+
:   call_function PlayerSetWaitLink.poppy
:   end_script

.waitText
    say "Huh? Oh, What's\n"
    say "up?\n"

    ask "Nothing.\n"
    ask "Wait here."
    end_ask

.followText
    say "Oh, you need my\n"
    say "help again?\n"

    ask "Not yet.\n"
    ask "Follow me."
    end_ask