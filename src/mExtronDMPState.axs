MODULE_NAME='mExtronDMPState'	(
                                    dev vdvObject,
                                    dev vdvControl
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

Copyright (c) 2022 Norgate AV Solutions Ltd

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

constant integer MAX_OBJECT_TAGS = 5


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile long ltDrive[] = { 200 }

volatile char cAtt[NAV_MAX_CHARS]
volatile char cIndex[4][NAV_MAX_CHARS]

volatile _NAVVolume uVolume

volatile integer iIsInitialized

volatile integer iRegistered
volatile integer iRegisterReady
volatile integer iRegisterRequested

volatile integer iID

volatile integer iSemaphore
volatile char cRxBuffer[NAV_MAX_BUFFER]

volatile char cObjectTag[MAX_OBJECT_TAGS][NAV_MAX_CHARS]


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
    NAVLog("'Command to ', NAVStringSurroundWith(NAVDeviceToString(vdvControl), '[', ']'), ': [', cParam, ']'")
    send_command vdvControl, "cParam"
}


define_function BuildCommand(char cHeader[], char cCmd[]) {
    if (length_array(cCmd)) {
        SendCommand("cHeader, '-<',itoa(iID), '|', cCmd, '>'")
    }
    else {
        SendCommand("cHeader, '-<',itoa(iID), '>'")
    }
}


define_function Register() {
    iRegistered = true

    switch (cAtt) {
        case 'M': {	//Standard Mute
            cObjectTag[1] = "'Ds', cAtt, format('%02d', atoi(cIndex[1])), '*'"
            cObjectTag[2] = "'Ds',cAtt, format('%01d', atoi(cIndex[1])), '*'"
        }
        case 'D': {	//Group Mute
            cObjectTag[1] = "'Grpm', cAtt, format('%02d', atoi(cIndex[1])), '*'"
            cObjectTag[2] = "'Grpm', cAtt, format('%01d', atoi(cIndex[1])), '*'"
        }
    }

    if (iID) { BuildCommand('REGISTER', "cObjectTag[1], ',', cObjectTag[2]") }
    NAVLog("'EXTRON_DMP_REGISTER<', itoa(iID), '>'")
}


define_function Process() {
    stack_var char cTemp[NAV_MAX_BUFFER]

    iSemaphore = true

    while (length_array(cRxBuffer) && NAVContains(cRxBuffer, '>')) {
        cTemp = remove_string(cRxBuffer, "'>'", 1)

        if (length_array(cTemp)) {
            NAVLog("'Parsing String From ', NAVStringSurroundWith(NAVDeviceToString(vdvControl), '[', ']'), ': [', cTemp, ']'")

            if (NAVContains(cRxBuffer, cTemp)) { cRxBuffer = "''" }

            select {
                active (NAVStartsWith(cTemp, 'REGISTER')): {
                    iID = atoi(NAVGetStringBetween(cTemp, '<', '>'))

                    iRegisterRequested = true
                    if (iRegisterReady) {
                        Register()
                    }

                    NAVLog("'EXTRON_DMP_REGISTER_REQUESTED<', itoa(iID), '>'")
                }
                active (NAVStartsWith(cTemp, 'INIT')): {
                    iIsInitialized = false
                    GetInitialized()
                    NAVLog("'EXTRON_DMP_INIT_REQUESTED<', itoa(iID), '>'")
                }
                active (NAVStartsWith(cTemp, 'RESPONSE_MSG')): {
                    stack_var char cResponseMess[NAV_MAX_BUFFER]

                    cResponseMess = NAVGetStringBetween(cTemp, '<', '>')

                    select {
                        active (NAVContains(cResponseMess, cObjectTag[1])): {
                            GetState(cResponseMess, cObjectTag[1])
                        }
                        active (NAVContains(cResponseMess, cObjectTag[2])): {
                            GetState(cResponseMess, cObjectTag[2])
                        }
                    }
                }
            }
        }
    }

    iSemaphore = false
}


define_function GetInitialized() {
    BuildCommand('POLL_MSG', BuildString(cAtt, cIndex[1], ''))
}


define_function GetState(char cResponseMess[], char cTag[]) {
    remove_string(cResponseMess, "cTag", 1)
    NAVLog("'DMP_STATE_RESPONSE_MESSSAGE<', cResponseMess, '>'")

    if (NAVStartsWith(cIndex[1], '2') && cAtt == 'M') {	//XP Mute
        NAVLog("'DMP_STATE_OBJECT_IS_XP<', itoa(iID), '>'")
        uVolume.Mute.Actual = !atoi(cResponseMess)
    }
    else {
        uVolume.Mute.Actual = atoi(cResponseMess)
    }

    NAVLog("'DMP_STATE_ACTUAL_MUTE<', itoa(uVolume.Mute.Actual), '>'")

    if (!iIsInitialized) {
        iIsInitialized = true
        BuildCommand('INIT_DONE', '')
        NAVLog("'EXTRON_DMP_INIT_DONE<', itoa(iID), '>'")
    }
}


define_function Poll() {
    BuildCommand('POLL_MSG', BuildString(cAtt, cIndex[1], ''))
}


define_function char[NAV_MAX_BUFFER] BuildString(char cAtt[], char cIndex1[], char cVal[]) {
    stack_var char cTemp[NAV_MAX_BUFFER]

    if (length_array(cAtt)) { cTemp = "NAV_ESC, cAtt" }
    if (length_array(cIndex1)) { cTemp = "cTemp, format('%01d', atoi(cIndex1))" }
    if (length_array(cVal)) { cTemp = "cTemp, '*', cVal" }

    switch (cAtt) {
        case 'M': { cTemp = "cTemp, 'AU'" }
        case 'D': { cTemp = "cTemp, 'GRPM'" }
    }

    cTemp = "cTemp, NAV_CR"
    return cTemp
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {
    create_buffer vdvControl,cRxBuffer
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[vdvControl] {
    string: {
        if (!iSemaphore) {
            Process()
        }
    }
}


data_event[vdvObject] {
    online: {

    }
    command: {
        stack_var char cCmdHeader[NAV_MAX_CHARS]
        stack_var char cCmdParam[2][NAV_MAX_CHARS]

        NAVLog(NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_FROM, data.device, data.text))

        cCmdHeader = DuetParseCmdHeader(data.text)
        cCmdParam[1] = DuetParseCmdParam(data.text)
        cCmdParam[2] = DuetParseCmdParam(data.text)

        switch (cCmdHeader) {
            case 'PROPERTY': {
                switch (cCmdParam[1]) {
                    case 'ATTRIBUTE': {
                        cAtt = cCmdParam[2]
                    }
                    case 'INDEX_1': {
                        cIndex[1] = cCmdParam[2]
                    }
                    case 'INDEX_2': {
                        cIndex[2] = cCmdParam[2]
                    }
                    case 'INDEX_3': {
                        cIndex[3] = cCmdParam[2]
                    }
                    case 'INDEX_4': {
                        cIndex[4] = cCmdParam[2]
                    }
                }
            }
            case 'REGISTER': {
                iRegisterReady = true
                if (iRegisterRequested) {
                    Register()
                }
            }
            case 'INIT': {
                GetInitialized()
            }
            case 'MUTE': {
                switch (cCmdParam[1]) {
                    case 'ON': {
                        BuildCommand('COMMAND_MSG', BuildString(cAtt, cIndex[1], '1'))
                    }
                    case 'OFF': {
                        BuildCommand('COMMAND_MSG', BuildString(cAtt, cIndex[1], '0'))
                    }
                    case 'TOGGLE': {
                        if (uVolume.Mute.Actual) {
                            BuildCommand('COMMAND_MSG', BuildString(cAtt, cIndex[1], '0'))
                        }
                        else {
                            BuildCommand('COMMAND_MSG', BuildString(cAtt, cIndex[1], '1'))
                        }
                    }
                }
            }
        }
    }
}


channel_event[vdvObject, 0] {
    on: {
        switch (channel.channel) {
            case VOL_MUTE: {
                NAVLog("'DMP_STATE_OBJECT_MUTE_TOGGLE<', itoa(iID), '>'")

                if (uVolume.Mute.Actual) {
                    BuildCommand('COMMAND_MSG', BuildString(cAtt, cIndex[1], '0'))
                }
                else {
                    BuildCommand('COMMAND_MSG', BuildString(cAtt, cIndex[1], '1'))
                }
            }
        }
    }
    off: {

    }
}


timeline_event[TL_NAV_FEEDBACK] {
    [vdvObject, VOL_MUTE_FB]	= (uVolume.Mute.Actual)
}


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
