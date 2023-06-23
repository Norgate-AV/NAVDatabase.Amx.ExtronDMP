MODULE_NAME='mExtronDMPPreset'	(
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

volatile integer isInitialized

volatile integer registered
volatile integer registerReady
volatile integer registerRequested

volatile integer id

volatile integer semaphore
volatile char rxBuffer[NAV_MAX_BUFFER]


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
        SendCommand("header, '-<', itoa(id), '|', cmd, '>'")
    }
    else {
        SendCommand("header, '-<', itoa(id), '>'")
    }
}


define_function Register() {
    registered = true
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

                    if (id) { BuildCommand('REGISTER', '') }

                    isInitialized = false

                    NAVLog("'EXTRON_DMP_REGISTER_REQUESTED<', itoa(id), '>'")
                    NAVLog("'EXTRON_DMP_REGISTER<', itoa(id), '>'")
                }
                active (NAVStartsWith(temp, 'INIT')): {
                    isInitialized = true
                    BuildCommand('INIT_DONE', '')
                    NAVLog("'EXTRON_DMP_INIT_REQUESTED<', itoa(id), '>'")
                    NAVLog("'EXTRON_DMP_INIT_DONE<', itoa(id), '>'")
                }
                active (NAVStartsWith(temp, 'RESPONSE_MSG')): {
                    stack_var char responseMess[NAV_MAX_BUFFER]
                    responseMess = NAVGetStringBetween(temp, '<', '>')
                }
            }
        }
    }

    semaphore = false
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {
    create_buffer vdvControl, rxBuffer
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

        switch (cmdHeader) {
            case 'PRESET': {
                BuildCommand('COMMAND_MSG', "cmdParam[1], '.'")
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
