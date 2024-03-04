MODULE_NAME='mExtronDMPFaderUIArray'    (
                                            dev dvTP[],
                                            dev vdvLevelObject,
                                            dev vdvStateObject
                                        )

(***********************************************************)
#include 'NAVFoundation.ModuleBase.axi'
#include 'NAVFoundation.Math.axi'
#include 'NAVFoundation.UIUtils.axi'

/*
 _   _                       _          ___     __
| \ | | ___  _ __ __ _  __ _| |_ ___   / \ \   / /
|  \| |/ _ \| '__/ _` |/ _` | __/ _ \ / _ \ \ / /
| |\  | (_) | | | (_| | (_| | ||  __// ___ \ V /
|_| \_|\___/|_|  \__, |\__,_|\__\___/_/   \_\_/
                 |___/

MIT License

Copyright (c) 2023 Norgate AV Services Limited

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

constant integer ADDRESS_LEVEL_PERCENTAGE    = 1
constant integer ADDRESS_LABEL    = 2

constant integer LOCK_TOGGLE    = 301
constant integer LOCK_ON    = 302
constant integer LOCK_OFF    = 303
constant integer LEVEL_TOUCH    = 304

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile integer iLocked

volatile integer iLevelTouched
volatile sinteger siRequestedLevel = -1

volatile sinteger iLevel
volatile sinteger iOldLevel


volatile char cLabel[NAV_MAX_CHARS]

volatile integer iMuteFeedbackBlink = false

(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)

define_function Update() {
    iOldLevel = iLevel

    if (siRequestedLevel >= 0) {
        if (siRequestedLevel == iLevel) {
            siRequestedLevel = -1
        }
    }
    else {
        if (!iLevelTouched) {
            stack_var integer x

            for (x = 1; x <= length_array(dvTP); x++) {
                send_level dvTP[x], VOL_LVL, iLevel
            }

            send_command dvTP, "'^TXT-', itoa(ADDRESS_LEVEL_PERCENTAGE), ', 0, ', itoa(NAVScaleValue(type_cast(iLevel), 255, 100, 0)), '%'"
        }
    }

    NAVTextArray(dvTP, ADDRESS_LABEL, '0', cLabel)
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {

}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

level_event[vdvLevelObject, VOL_LVL] {
    iLevel = level.value
    Update()
}


button_event[dvTP, 0] {
    push: {
        switch (button.input.channel) {
            case VOL_UP:
            case VOL_DN: {
                if (!iLocked) {
                    to[vdvLevelObject, button.input.channel]
                }
            }
            case VOL_MUTE: { to[vdvStateObject, button.input.channel] }
            case LOCK_TOGGLE: {
                iLocked = !iLocked
            }
            case LOCK_ON: {
                iLocked = true
            }
            case LOCK_OFF: {
                iLocked = false
            }
            case LEVEL_TOUCH: {
                iLevelTouched = true
            }
        }
    }
    release: {
        switch (button.input.channel) {
            case LEVEL_TOUCH: {
                iLevelTouched = false
            }
        }
    }
}


level_event[dvTP, VOL_LVL] {
    if (iLevelTouched && !iLocked) {
        siRequestedLevel = level.value
        send_command vdvLevelObject, "'VOLUME-', itoa(siRequestedLevel)"
        send_command dvTP, "'^TXT-', itoa(ADDRESS_LEVEL_PERCENTAGE), ', 0, ', itoa(NAVScaleValue(type_cast(siRequestedLevel), 255, 100, 0)), '%'"
    }
}


data_event[dvTP] {
    online: {
        Update()
    }
}


data_event[vdvLevelObject] {
    online: {
        NAVCommand(data.device, "'?LABEL'")
    }
    command: {
        stack_var char cCmdHeader[NAV_MAX_CHARS]
        stack_var char cCmdParam[2][NAV_MAX_CHARS]

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'Command from ',
                                            NAVStringSurroundWith(NAVDeviceToString(data.device), '[', ']'),
                                            ': [', data.text, ']'")

        cCmdHeader = DuetParseCmdHeader(data.text)
        cCmdParam[1] = DuetParseCmdParam(data.text)
        cCmdParam[2] = DuetParseCmdParam(data.text)

        switch (cCmdHeader) {
            case 'PROPERTY': {
                switch (cCmdParam[1]) {
                    case 'LABEL': {
                        cLabel = cCmdParam[2]
                        Update()
                    }
                }
            }
        }
    }
}


data_event[vdvStateObject] {
    command: {
        stack_var char cCmdHeader[NAV_MAX_CHARS]
        stack_var char cCmdParam[2][NAV_MAX_CHARS]

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'Command from ',
                                            NAVStringSurroundWith(NAVDeviceToString(data.device), '[', ']'),
                                            ': [', data.text, ']'")

        cCmdHeader = DuetParseCmdHeader(data.text)
        cCmdParam[1] = DuetParseCmdParam(data.text)
        cCmdParam[2] = DuetParseCmdParam(data.text)

        switch (cCmdHeader) {
            case 'PROPERTY': {
                switch (cCmdParam[1]) {
                    case 'FEEDBACK_BLINK': {
                        switch (upper_string(cCmdParam[2])) {
                            case 'true': {
                                iMuteFeedbackBlink = true
                            }
                            case 'false': {
                                iMuteFeedbackBlink = false
                            }
                        }
                    }
                }
            }
        }
    }
}


timeline_event[TL_NAV_FEEDBACK] {
    if (!iMuteFeedbackBlink) {
        [dvTP, VOL_MUTE]    = ([vdvStateObject, VOL_MUTE_FB])
    }
    else {
        [dvTP, VOL_MUTE]    = ([vdvStateObject, VOL_MUTE_FB] && NAVBlinker)
    }

    [dvTP, LOCK_TOGGLE]    = (iLocked)
    [dvTP, LOCK_ON]    = (iLocked)
    [dvTP, LOCK_OFF]    = (!iLocked)
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

