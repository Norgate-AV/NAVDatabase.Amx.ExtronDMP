MODULE_NAME='mExtronDMPStateUIArray'    (
                                            dev dvTP[],
                                            dev vdvObject
                                        )

(***********************************************************)
#include 'NAVFoundation.ModuleBase.axi'

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

constant integer LOCK_TOGGLE    = 301
constant integer LOCK_ON    = 302
constant integer LOCK_OFF    = 303


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile integer locked

volatile integer blinkerEnabled = false


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


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {

}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

button_event[dvTP, 0] {
    push: {
        switch (button.input.channel) {
            case VOL_MUTE: {
                to[vdvObject, button.input.channel]
            }
            case LOCK_TOGGLE: {
                locked = !locked
            }
            case LOCK_ON: {
                locked = true
            }
            case LOCK_OFF: {
                locked = false
            }
        }
    }
}


data_event[vdvObject] {
    command: {
        stack_var _NAVSnapiMessage message

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                    NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_FROM,
                                                data.device,
                                                data.text))

        NAVParseSnapiMessage(data.text, message)

        switch (message.Header) {
            case 'PROPERTY': {
                switch (message.Parameter[1]) {
                    case 'MUTE_BLINK': {
                        blinkerEnabled = atoi(NAVStringToBoolean(message.Parameter[2]))
                    }
                }
            }
        }
    }
}


timeline_event[TL_NAV_FEEDBACK] {
    if (!blinkerEnabled) {
        [dvTP, VOL_MUTE]    = ([vdvObject, VOL_MUTE_FB])
    }
    else {
        [dvTP, VOL_MUTE]    = ([vdvObject, VOL_MUTE_FB] && NAVBlinker)
    }

    [dvTP, LOCK_TOGGLE]    = (locked)
    [dvTP, LOCK_ON]    = (locked)
    [dvTP, LOCK_OFF]    = (!locked)
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
