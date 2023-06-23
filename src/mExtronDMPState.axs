MODULE_NAME='mExtronDMPState'	(
                                    dev vdvObject,
                                    dev vdvControl
                                )

(***********************************************************)
#include 'NAVFoundation.ModuleBase.axi'
#include 'LibExtronDMP.axi'

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

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile char att[NAV_MAX_CHARS]
volatile char index[4][NAV_MAX_CHARS]

volatile _NAVVolume volume

volatile integer isInitialized

volatile integer registered
volatile integer registerReady
volatile integer registerRequested

volatile integer id

volatile integer semaphore
volatile char rxBuffer[NAV_MAX_BUFFER]

volatile char objectTag[MAX_OBJECT_TAGS][NAV_MAX_CHARS]


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

define_function SendCommand(char param[]) {
    NAVLog("'Command to ', NAVStringSurroundWith(NAVDeviceToString(vdvControl), '[', ']'), ': [', param, ']'")
    send_command vdvControl, "param"
}


define_function BuildCommand(char header[], char cmd[]) {
    if (length_array(cmd)) {
        SendCommand("header, '-<',itoa(id), '|', cmd, '>'")
    }
    else {
        SendCommand("header, '-<',itoa(id), '>'")
    }
}


define_function Register() {
    registered = true

    switch (att) {
        case 'M': {	//Standard Mute
            objectTag[1] = "'Ds', att, format('%02d', atoi(index[1])), '*'"
            objectTag[2] = "'Ds',att, format('%01d', atoi(index[1])), '*'"
        }
        case 'D': {	//Group Mute
            objectTag[1] = "'Grpm', att, format('%02d', atoi(index[1])), '*'"
            objectTag[2] = "'Grpm', att, format('%01d', atoi(index[1])), '*'"
        }
    }

    if (id) { BuildCommand('REGISTER', "objectTag[1], ',', objectTag[2]") }
    NAVLog("'EXTRON_DMP_REGISTER<', itoa(id), '>'")
}


define_function Process() {
    stack_var char temp[NAV_MAX_BUFFER]

    semaphore = true

    while (length_array(rxBuffer) && NAVContains(rxBuffer, '>')) {
        temp = remove_string(rxBuffer, "'>'", 1)

        if (length_array(temp)) {
            NAVLog("'Parsing String From ', NAVStringSurroundWith(NAVDeviceToString(vdvControl), '[', ']'), ': [', temp, ']'")

            if (NAVContains(rxBuffer, temp)) { rxBuffer = "''" }

            select {
                active (NAVStartsWith(temp, 'REGISTER')): {
                    id = atoi(NAVGetStringBetween(temp, '<', '>'))

                    registerRequested = true
                    if (registerReady) {
                        Register()
                    }

                    NAVLog("'EXTRON_DMP_REGISTER_REQUESTED<', itoa(id), '>'")
                }
                active (NAVStartsWith(temp, 'INIT')): {
                    isInitialized = false
                    GetInitialized()
                    NAVLog("'EXTRON_DMP_INIT_REQUESTED<', itoa(id), '>'")
                }
                active (NAVStartsWith(temp, 'RESPONSE_MSG')): {
                    stack_var char responseMess[NAV_MAX_BUFFER]

                    responseMess = NAVGetStringBetween(temp, '<', '>')

                    select {
                        active (NAVContains(responseMess, objectTag[1])): {
                            GetState(responseMess, objectTag[1])
                        }
                        active (NAVContains(responseMess, objectTag[2])): {
                            GetState(responseMess, objectTag[2])
                        }
                    }
                }
            }
        }
    }

    semaphore = false
}


define_function GetInitialized() {
    BuildCommand('POLL_MSG', BuildString(att, index[1], ''))
}


define_function GetState(char responseMess[], char tag[]) {
    remove_string(responseMess, "tag", 1)
    NAVLog("'DMP_STATE_RESPONSE_MESSSAGE<', responseMess, '>'")

    if (NAVStartsWith(index[1], '2') && att == 'M') {	//XP Mute
        NAVLog("'DMP_STATE_OBJECT_IS_XP<', itoa(id), '>'")
        volume.Mute.Actual = !atoi(responseMess)
    }
    else {
        volume.Mute.Actual = atoi(responseMess)
    }

    NAVLog("'DMP_STATE_ACTUAL_MUTE<', itoa(volume.Mute.Actual), '>'")

    if (!isInitialized) {
        isInitialized = true
        BuildCommand('INIT_DONE', '')
        NAVLog("'EXTRON_DMP_INIT_DONE<', itoa(id), '>'")
    }
}


define_function Poll() {
    BuildCommand('POLL_MSG', BuildString(att, index[1], ''))
}


define_function char[NAV_MAX_BUFFER] BuildString(char att[], char index1[], char val[]) {
    stack_var char temp[NAV_MAX_BUFFER]

    if (length_array(att)) { temp = "NAV_ESC, att" }
    if (length_array(index1)) { temp = "temp, format('%01d', atoi(index1))" }
    if (length_array(val)) { temp = "temp, '*', val" }

    switch (att) {
        case 'M': { temp = "temp, 'AU'" }
        case 'D': { temp = "temp, 'GRPM'" }
    }

    temp = "temp, NAV_CR"
    return temp
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {
    create_buffer vdvControl,rxBuffer
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[vdvControl] {
    string: {
        if (!semaphore) {
            Process()
        }
    }
}


data_event[vdvObject] {
    online: {

    }
    command: {
        stack_var char cmdHeader[NAV_MAX_CHARS]
        stack_var char cmdParam[2][NAV_MAX_CHARS]

        NAVLog(NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_FROM, data.device, data.text))

        cmdHeader = DuetParseCmdHeader(data.text)
        cmdParam[1] = DuetParseCmdParam(data.text)
        cmdParam[2] = DuetParseCmdParam(data.text)

        switch (cmdHeader) {
            case 'PROPERTY': {
                switch (cmdParam[1]) {
                    case 'ATTRIBUTE': {
                        att = cmdParam[2]
                    }
                    case 'INDEX_1': {
                        index[1] = cmdParam[2]
                    }
                    case 'INDEX_2': {
                        index[2] = cmdParam[2]
                    }
                    case 'INDEX_3': {
                        index[3] = cmdParam[2]
                    }
                    case 'INDEX_4': {
                        index[4] = cmdParam[2]
                    }
                }
            }
            case 'REGISTER': {
                registerReady = true
                if (registerRequested) {
                    Register()
                }
            }
            case 'INIT': {
                GetInitialized()
            }
            case 'MUTE': {
                switch (cmdParam[1]) {
                    case 'ON': {
                        BuildCommand('COMMAND_MSG', BuildString(att, index[1], '1'))
                    }
                    case 'OFF': {
                        BuildCommand('COMMAND_MSG', BuildString(att, index[1], '0'))
                    }
                    case 'TOGGLE': {
                        if (volume.Mute.Actual) {
                            BuildCommand('COMMAND_MSG', BuildString(att, index[1], '0'))
                        }
                        else {
                            BuildCommand('COMMAND_MSG', BuildString(att, index[1], '1'))
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
                NAVLog("'DMP_STATE_OBJECT_MUTE_TOGGLE<', itoa(id), '>'")

                if (volume.Mute.Actual) {
                    BuildCommand('COMMAND_MSG', BuildString(att, index[1], '0'))
                }
                else {
                    BuildCommand('COMMAND_MSG', BuildString(att, index[1], '1'))
                }
            }
        }
    }
    off: {

    }
}


timeline_event[TL_NAV_FEEDBACK] {
    [vdvObject, VOL_MUTE_FB]	= (volume.Mute.Actual)
}


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
