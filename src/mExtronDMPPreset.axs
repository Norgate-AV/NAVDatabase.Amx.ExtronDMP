MODULE_NAME='mExtronDMPPreset'    (
                                    dev vdvObject,
                                    dev vdvCommObject
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

constant long TL_DRIVE = 1

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile long ltDrive[] = { 200 }

volatile integer iIsInitialized

volatile integer iRegistered
volatile integer iRegisterReady
volatile integer iRegisterRequested

volatile integer iID

volatile integer iSemaphore
volatile char cRxBuffer[NAV_MAX_BUFFER]

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

define_function SendCommand(char cParam[]) {
    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'Command to ', NAVStringSurroundWith(NAVDeviceToString(vdvCommObject), '[', ']'), ': [', cParam, ']'")
    send_command vdvCommObject, "cParam"
}


define_function BuildCommand(char cHeader[], char cCmd[]) {
    if (length_array(cCmd)) {
        SendCommand("cHeader, '-<', itoa(iID), '|', cCmd, '>'")
    }
    else {
        SendCommand("cHeader, '-<', itoa(iID), '>'")
    }
}


define_function Register() {}


define_function Process() {
    stack_var char cTemp[NAV_MAX_BUFFER]

    if (iSemaphore) {
        return
    }

    iSemaphore = true

    while (length_array(cRxBuffer) && NAVContains(cRxBuffer, '>')) {
        cTemp = remove_string(cRxBuffer, "'>'", 1)

        if (!length_array(cTemp)) {
            continue
        }

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'Parsing String From ',
                                            NAVStringSurroundWith(NAVDeviceToString(vdvCommObject), '[', ']'),
                                            ': [', cTemp, ']'")

        if (NAVContains(cRxBuffer, cTemp)) { cRxBuffer = "''" }

        select {
            active (NAVStartsWith(cTemp, 'REGISTER')): {
                iID = atoi(NAVGetStringBetween(cTemp, '<', '>'))

                if (iID) {
                    BuildCommand('REGISTER', '')
                }

                iIsInitialized = false

                NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'EXTRON_DMP_REGISTER_REQUESTED<', itoa(iID), '>'")
                NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'EXTRON_DMP_REGISTER<', itoa(iID), '>'")
            }
            active (NAVStartsWith(cTemp, 'INIT')): {
                iIsInitialized = true
                BuildCommand('INIT_DONE', '')

                NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'EXTRON_DMP_INIT_REQUESTED<', itoa(iID), '>'")
                NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'EXTRON_DMP_INIT_DONE<', itoa(iID), '>'")
            }
            active (NAVStartsWith(cTemp, 'RESPONSE_MSG')): {
                stack_var char cResponseMess[NAV_MAX_BUFFER]
                cResponseMess = NAVGetStringBetween(cTemp, '<', '>')
            }
        }
    }

    iSemaphore = false
}


define_function char[255] GetPresetCommand(integer preset) {
    return format('%02d.', preset)
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {
    create_buffer vdvCommObject, cRxBuffer
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[vdvCommObject] {
    string: {
        if (!iSemaphore) {
            Process()
        }
    }
}


data_event[vdvObject] {
    command: {
        stack_var char cCmdHeader[NAV_MAX_CHARS]
        stack_var char cCmdParam[2][NAV_MAX_CHARS]

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                    NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_FROM,
                                                data.device,
                                                data.text))

        cCmdHeader = DuetParseCmdHeader(data.text)
        cCmdParam[1] = DuetParseCmdParam(data.text)

        switch (cCmdHeader) {
            case 'PRESET': {
                BuildCommand('COMMAND_MSG', GetPresetCommand(atoi(cCmdParam[1])))
            }
        }
    }
}


channel_event[vdvObject, 0] {
    on: {
        BuildCommand('COMMAND_MSG', "itoa(channel.channel), '.'")
    }
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

