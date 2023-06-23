MODULE_NAME='mExtronDMPLevel'	(
                                    dev vdvObject,
                                    dev vdvCommObject
                                )

(***********************************************************)
#include 'NAVFoundation.ModuleBase.axi'
#include 'NAVFoundation.Math.axi'
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

constant long TL_DRIVE = 1


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile long drive[] = { 500 }

volatile char att[NAV_MAX_CHARS]
volatile char index[4][NAV_MAX_CHARS]

volatile char label[NAV_MAX_CHARS]

volatile _NAVVolume volume

volatile sinteger maxLevel = 2168
volatile sinteger minLevel = 1048

volatile integer isInitialized

volatile integer registered
volatile integer registerReady
volatile integer registerRequested

volatile integer id
volatile char objectTag[MAX_OBJECT_TAGS][NAV_MAX_CHARS]

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
    NAVLog("'Command to ', NAVStringSurroundWith(NAVDeviceToString(vdvCommObject), '[', ']'), ': [', param, ']'")
    send_command vdvCommObject, "param"
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

    switch (att) {
        case 'G': {	//Standard Level
            objectTag[1] = "'Ds', att, format('%02d' ,atoi(index[1])), '*'"
            objectTag[2] = "'Ds', att, format('%01d', atoi(index[1])), '*'"
            objectTag[3] = ''
            objectTag[4] = ''
        }
        case 'D': { 	//Group Level
            objectTag[1] = "'Grpm', att, format('%02d', atoi(index[1])), '*'"
            objectTag[2] = "'GrpmL', format('%02d', atoi(index[1])), '*'"
            objectTag[3] = "'Grpm', att, format('%01d', atoi(index[1])), '*'"
            objectTag[4] = "'GrpmL', format('%01d', atoi(index[1])), '*'"
        }
    }

    if (id) { BuildCommand('REGISTER', "objectTag[1], ',', objectTag[2], ',', objectTag[3], ',', objectTag[4]") }
    NAVLog("'EXTRON_DMP_REGISTER<', itoa(id), '>'")
}


define_function Process() {
    stack_var char temp[NAV_MAX_BUFFER]

    semaphore = true

    while (length_array(rxBuffer) && NAVContains(rxBuffer, '>')) {
        temp = remove_string(rxBuffer, "'>'", 1)

        if (length_array(temp)) {
            NAVLog("'Parsing String From ', NAVStringSurroundWith(NAVDeviceToString(vdvCommObject), '[', ']'), ': [', temp, ']'")

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
                    NAVLog("'Response message: ', temp")

                    responseMess = NAVGetStringBetween(temp, '<', '>')

                    switch (att) {
                        case 'G': {
                            select {
                                active (NAVContains(responseMess, objectTag[1])): {
                                    GetLevel(responseMess, objectTag[1])
                                }
                                active (NAVContains(responseMess, objectTag[2])): {
                                    GetLevel(responseMess, objectTag[2])
                                }
                            }
                        }
                        case 'D': {
                            select {
                                active (NAVContains(responseMess, objectTag[1])): {
                                    GetLevel(responseMess, objectTag[1])
                                }
                                active (NAVContains(responseMess, objectTag[2])): {
                                    GetLimits(responseMess, objectTag[2])
                                }
                                active (NAVContains(responseMess, objectTag[3])): {
                                    GetLevel(responseMess, objectTag[3])
                                }
                                active (NAVContains(responseMess, objectTag[4])): {
                                    GetLimits(responseMess, objectTag[4])
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    semaphore = false
}


define_function GetLevel(char responseMess[], char tag[]) {
    remove_string(responseMess, "tag", 1)
    volume.Level.Actual = atoi(responseMess)
    send_level vdvObject, 1, NAVScaleValue((volume.Level.Actual - minLevel), (maxLevel - minLevel), 255, 0)

    if (!isInitialized) {
        isInitialized = true
        BuildCommand('INIT_DONE', '')
        NAVLog("'EXTRON_DMP_INIT_DONE<', itoa(id), '>'")
    }
}


define_function GetLimits(char responseMess[], char tag[]) {
    NAVLog("'EXTRON_DMP_FOUND_SOFT_LIMIT_RESPONSE<', itoa(id), '>'")
    remove_string(responseMess, "tag", 1)

    maxLevel = atoi(NAVStripCharsFromRight(remove_string(responseMess, '*', 1), 1))
    NAVLog("'EXTRON_DMP_MAX_LEVEL<', itoa(maxLevel), '>'")
    minLevel = atoi(responseMess)
    NAVLog("'EXTRON_DMP_MIN_LEVEL<', itoa(minLevel), '>'")

    send_level vdvObject, 1, NAVScaleValue((volume.Level.Actual - minLevel), (maxLevel - minLevel), 255, 0)
}


define_function GetInitialized() {
    switch (att) {
        case 'G': {	//Standard Level
            BuildCommand('POLL_MSG', BuildString(att, index[1], ''))
        }
        case 'D': {	//Group Level
            BuildCommand('POLL_MSG', BuildString('L', index[1], ''))	//Get Caps First
            BuildCommand('POLL_MSG', BuildString(att, index[1], ''))
        }
    }
}


define_function Poll() {
    switch (att) {
        case 'G': {	// Standard Level
            BuildCommand('POLL_MSG', BuildString(att, index[1], ''))
        }
        case 'D': {	// Group Level
            BuildCommand('POLL_MSG', BuildString('L', index[1], ''))	//Get Caps First
            BuildCommand('POLL_MSG', BuildString(att, index[1], ''))
        }
    }
}


define_function char[NAV_MAX_BUFFER] BuildString(char att[], char index1[], char val[]) {
    stack_var char temp[NAV_MAX_BUFFER]

    if (length_array(att)) { temp = "NAV_ESC, att" }
    if (length_array(index1)) { temp = "temp, format('%01d', atoi(index1))" }
    if (length_array(val)) { temp = "temp, '*', val" }

    switch (att) {
        case 'G': { temp = "temp, 'AU'" }
        case 'L':
        case 'D': { temp = "temp, 'GRPM'" }
    }

    temp = "temp, NAV_CR"
    return temp
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {
    create_buffer vdvCommObject, rxBuffer
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[vdvCommObject] {
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

        NAVLog("'Command from ', NAVStringSurroundWith(NAVDeviceToString(data.device), '[', ']'), ': [', data.text, ']'")

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
                    case 'MAX_LEVEL': {
                        if (length_array(cmdParam[2])) {
                            maxLevel = atoi(cmdParam[2]) * 10
                        }
                    }
                    case 'MIN_LEVEL': {
                        if (length_array(cmdParam[2])) {
                            minLevel = atoi(cmdParam[2]) * 10
                        }
                    }
                    case 'LABEL': {
                        label = cmdParam[2]
                    }
                }
            }
            case 'REGISTER': {
                registerReady = true
                if (registerRequested) {
                    Register()
                }
            }
            case '?LABEL': {
                if (length_array(label)) {
                    NAVCommand(data.device, "'PROPERTY-LABEL,', label")
                }
            }
            case 'INIT': {
                GetInitialized()
            }
            case 'VOLUME': {
                switch (cmdParam[1]) {
                    case 'QUARTER': {
                        if (isInitialized) {
                            BuildCommand('COMMAND_MSG', BuildString(att, index[1], itoa(NAVQuarterPointOfRange(maxLevel, minLevel))))
                        }
                    }
                    case 'HALF': {
                        if (isInitialized) {
                            BuildCommand('COMMAND_MSG', BuildString(att, index[1], itoa(NAVHalfPointOfRange(maxLevel, minLevel))))
                        }
                    }
                    case 'THREE_QUARTERS': {
                        if (isInitialized) {
                            BuildCommand('COMMAND_MSG' ,BuildString(att, index[1], itoa(NAVThreeQuarterPointOfRange(maxLevel, minLevel))))
                        }
                    }
                    case 'FULL': {
                        if (isInitialized) {
                            BuildCommand('COMMAND_MSG', BuildString(att, index[1], itoa(maxLevel)))
                        }
                    }
                    case 'INC': {
                        if (volume.Level.Actual < maxLevel && isInitialized) {
                            BuildCommand('COMMAND_MSG', BuildString(att, index[1], itoa(volume.Level.Actual + 10)))
                        }
                    }
                    case 'DEC': {
                        if (volume.Level.Actual > minLevel && isInitialized) {
                            BuildCommand('COMMAND_MSG', BuildString(att, index[1], itoa(volume.Level.Actual - 10)))
                        }
                    }
                    case 'ABS': {
                        if ((atoi(cmdParam[2]) >= minLevel) && (atoi(cmdParam[2]) <= maxLevel) && isInitialized) {
                            BuildCommand('COMMAND_MSG', BuildString(att, index[1], cmdParam[2]))
                        }
                    }
                    default: {
                        stack_var sinteger level

                        level = NAVScaleValue(atoi(cmdParam[1]), 255,(maxLevel - minLevel), minLevel)

                        if ((level >= minLevel) && (level <= maxLevel) && isInitialized) {
                            BuildCommand('COMMAND_MSG', BuildString(att, index[1], itoa(level)))
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
            case VOL_UP: {
                if (isInitialized) {
                    timeline_create(TL_DRIVE, drive, length_array(drive), TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
                }
            }
            case VOL_DN: {
                if (isInitialized) {
                    timeline_create(TL_DRIVE, drive, length_array(drive), TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
                }
            }
        }
    }
    off: {
        NAVTimelineStop(TL_DRIVE)
    }
}


timeline_event[TL_DRIVE] {
    select {
        active ([vdvObject, VOL_UP]): {
            if (NAVContains(att, 'G')) {
                BuildCommand('COMMAND_MSG', BuildString(att, index[1], itoa(volume.Level.Actual + 10)))
            }
            else {
                BuildCommand('COMMAND_MSG', BuildString(att, index[1], '10+'))
            }
        }
        active ([vdvObject, VOL_DN]): {
            if (NAVContains(att, 'G')) {
                BuildCommand('COMMAND_MSG', BuildString(att, index[1], itoa(volume.Level.Actual - 10)))
            }
            else {
                BuildCommand('COMMAND_MSG', BuildString(att, index[1], '10-'))
            }
        }
    }
}


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
