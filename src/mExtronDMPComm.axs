MODULE_NAME='mExtronDMPComm'	(
                                    dev vdvObject,
                                    dev vdvCommObjects[],
                                    dev dvPort
                                )

(***********************************************************)
#include 'NAVFoundation.ModuleBase.axi'
#include 'NAVFoundation.SocketUtils.axi'

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
constant long TL_IP_CHECK = 1
constant long TL_QUEUE_FAILED_RESPONSE	= 2
constant long TL_HEARTBEAT	= 3
constant long TL_REGISTER	= 4


constant integer MAX_QUEUE_COMMANDS = 50
constant integer MAX_QUEUE_STATUS = 100
constant integer MAX_OBJECTS	= 100
constant integer MAX_OBJECT_TAGS	= 5

constant integer TELNET_WILL	= $FB
constant integer TELNET_DO	= $FD
constant integer TELNET_DONT	= $FE
constant integer TELNET_WONT	= $FC

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE
struct _Object {
    integer iInitialized
    integer iRegistered
}

struct _Queue {
    integer iBusy
    integer iHasItems
    integer iCommandHead
    integer iCommandTail
    integer iStatusHead
    integer iStatusTail
    integer iStrikeCount
    integer iResendLast
    char cLastMess[NAV_MAX_BUFFER]
}

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
volatile long ltHeartbeat[] = { 30000 }
volatile long ltIPCheck[] = { 3000 }
volatile long ltQueueFailedResponse[]	= { 2500 }
volatile long ltRegister[]	= { 500 }

volatile _Object uObject[MAX_OBJECTS]

volatile _Queue uQueue
volatile char cCommandQueue[MAX_QUEUE_COMMANDS][NAV_MAX_BUFFER]
volatile char cStatusQueue[MAX_QUEUE_STATUS][NAV_MAX_BUFFER]

volatile char cRxBuffer[NAV_MAX_BUFFER]
volatile integer iSemaphore

volatile char cIPAddress[15]
volatile integer iIPConnected = false
volatile integer iIPAuthenticated

volatile integer iInitializing
volatile integer iInitializingObjectID

volatile integer iInitialized
volatile integer iCommunicating

volatile char cUserName[NAV_MAX_CHARS]
volatile char cPassword[NAV_MAX_CHARS]

volatile char cObjectTag[MAX_OBJECT_TAGS][MAX_OBJECTS][NAV_MAX_CHARS]

volatile integer iDelayedRegisterRequired[MAX_OBJECTS]

volatile integer iRegistering
volatile integer iRegisteringObjectID
volatile integer iAllRegistered

volatile integer iReadyToInitialize

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

define_function SendStringRaw(char cString[]) {
    NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_STRING_TO,
                                            dvPort,
                                            cString))

    send_string dvPort,"cString"
}


define_function SendString(char cString[]) {
    SendStringRaw("cString")
}


define_function AddToQueue(char cString[], integer iPriority) {
    stack_var integer iQueueWasEmpty

    iQueueWasEmpty = (!uQueue.iHasItems && !uQueue.iBusy)

    switch (iPriority) {
        case true: {
            select {
                active (uQueue.iCommandHead == max_length_array(cCommandQueue)): {
                    if (uQueue.iCommandTail != 1) {
                        uQueue.iCommandHead = 1
                        cCommandQueue[uQueue.iCommandHead] = cString
                        uQueue.iHasItems = true
                    }
                }
                active (uQueue.iCommandTail != (uQueue.iCommandHead + 1)): {
                    uQueue.iCommandHead++
                    cCommandQueue[uQueue.iCommandHead] = cString
                    uQueue.iHasItems = true
                }
            }
        }
        case false: {
            select {
                active (uQueue.iStatusHead == max_length_array(cStatusQueue)): {
                    if (uQueue.iStatusTail != 1) {
                        uQueue.iStatusHead = 1
                        cStatusQueue[uQueue.iStatusHead] = cString
                        uQueue.iHasItems = true
                    }
                }
                active (uQueue.iStatusTail != (uQueue.iStatusHead + 1)): {
                    uQueue.iStatusHead++
                    cStatusQueue[uQueue.iStatusHead] = cString
                    uQueue.iHasItems = true
                }
            }
        }
    }

    if (iQueueWasEmpty) { SendNextQueueItem(); }
}


define_function char[NAV_MAX_BUFFER] RemoveFromQueue() {
    if (!uQueue.iHasItems || uQueue.iBusy) {
        return ""
    }

    uQueue.iBusy = true

    select {
        active (uQueue.iCommandHead != uQueue.iCommandTail): {
            if (uQueue.iCommandTail == max_length_array(cCommandQueue)) {
                uQueue.iCommandTail = 1
            }
            else {
                uQueue.iCommandTail++
            }

            uQueue.cLastMess = cCommandQueue[uQueue.iCommandTail]
        }
        active (uQueue.iStatusHead != uQueue.iStatusTail): {
            if (uQueue.iStatusTail == max_length_array(cStatusQueue)) {
                uQueue.iStatusTail = 1
            }
            else {
                uQueue.iStatusTail++
            }

            uQueue.cLastMess = cStatusQueue[uQueue.iStatusTail]
        }
    }

    if ((uQueue.iCommandHead == uQueue.iCommandTail) && (uQueue.iStatusHead == uQueue.iStatusTail)) {
        uQueue.iHasItems = false
    }


    return GetMess(uQueue.cLastMess)
}


define_function integer GetMessID(char cParam[]) {
    return atoi(NAVGetStringBetween(cParam, '<', '|'))
}


define_function integer GetSubscriptionMessID(char cParam[]) {
    return atoi(NAVGetStringBetween(cParam, '[', '*'))
}


define_function char[NAV_MAX_BUFFER] GetMess(char cParam[]) {
    return NAVGetStringBetween(cParam, '|', '>')
}


define_function InitializeObjects() {
    stack_var integer x

    if (iInitializing) {
        return
    }

    for (x = 1; x <= length_array(vdvCommObjects); x++) {
        if (uObject[x].iRegistered && !uObject[x].iInitialized) {
            iInitializing = true
            send_string vdvCommObjects[x], "'INIT<', itoa(x), '>'"
            iInitializingObjectID = x
            break
        }

        if (x == length_array(vdvCommObjects) && !iInitializing) {
            iInitializingObjectID = x
            iInitialized = true
        }
    }
}


define_function GoodResponse() {
    uQueue.iBusy = false
    NAVTimelineStop(TL_QUEUE_FAILED_RESPONSE)

    uQueue.iStrikeCount = 0
    uQueue.iResendLast = false
    SendNextQueueItem()
}


define_function SendNextQueueItem() {
    stack_var char cTemp[NAV_MAX_BUFFER]

    if (uQueue.iResendLast) {
        uQueue.iResendLast = false
        cTemp = GetMess(uQueue.cLastMess)
    }
    else {
        cTemp= RemoveFromQueue()
    }

    if (length_array(cTemp)) {
        SendString(cTemp)
        NAVTimelineStart(TL_QUEUE_FAILED_RESPONSE, ltQueueFailedResponse, TIMELINE_ABSOLUTE, TIMELINE_ONCE)
    }
}


define_function Reset() {
    ReInitializeObjects()
    InitializeQueue()
}


define_function ReInitializeObjects() {
    stack_var integer x

    iInitializing = false
    iInitialized = false
    iInitializingObjectID = 1

    for (x = 1; x <= length_array(uObject); x++) {
        uObject[x].iInitialized = false
    }
}


define_function InitializeQueue() {
    uQueue.iBusy = false
    uQueue.iHasItems = false

    uQueue.iCommandHead = 1
    uQueue.iCommandTail = 1
    uQueue.iStatusHead = 1
    uQueue.iStatusTail = 1

    uQueue.iStrikeCount = 0
    uQueue.iResendLast = false
    uQueue.cLastMess = ""
}


define_function Process() {
    stack_var char cTemp[NAV_MAX_BUFFER]

    if (iSemaphore) {
        return
    }

    iSemaphore = true

    while (length_array(cRxBuffer) && NAVContains(cRxBuffer, "NAV_LF")) {
        cTemp = remove_string(cRxBuffer, "NAV_LF", 1)

        if (!length_array(cTemp)) {
            continue
        }

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                    NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_PARSING_STRING_FROM,
                                                dvPort,
                                                cTemp))

        cTemp = NAVStripCharsFromRight(cTemp, 2)

        select {
            active (NAVContains(cTemp, 'Vrb')): {
                if (!iCommunicating) {
                    iCommunicating = true
                    //SendString("NAV_ESC,'3CV',NAV_CR")	//Set Verbose Mode
                }

                AttemptToInitialize()
            }
            active (true): {
                stack_var integer x
                stack_var integer i

                for (x = 1; x <= length_array(vdvCommObjects); x++) {
                    for (i = 1; i <= MAX_OBJECT_TAGS; i++) {
                        if (!NAVContains(cTemp, cObjectTag[i][x])) {
                            continue
                        }

                        send_string vdvCommObjects[x], "'RESPONSE_MSG<', cTemp, '>'"
                        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'EXTRON_DMP_SENDING_RESPONSE_MSG<', cTemp, '|', itoa(x), '>'")

                        i = (MAX_OBJECT_TAGS + 1)
                        x = (MAX_OBJECTS + 1)
                    }
                }
            }
        }

        GoodResponse()
    }

    iSemaphore = false
}


define_function MaintainIPConnection() {
    if (iIPConnected) {
        return
    }

    NAVClientSocketOpen(dvPort.PORT, cIPAddress, NAV_TELNET_PORT, IP_TCP)
}


define_function AttemptToInitialize() {
    if (iCommunicating && !iInitialized && iReadyToInitialize) {
        InitializeObjects()
    }
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {
    create_buffer dvPort, cRxBuffer
    Reset()
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[dvPort] {
    online: {
        if (data.device.number != 0) {
            send_command data.device, "'SET BAUD 38400,N,8,1 485 DISABLE'"
            send_command data.device, "'B9MOFF'"
            send_command data.device, "'CHARD-0'"
            send_command data.device, "'CHARDM-0'"
            send_command data.device, "'HSOFF'"
        }

        if (data.device.number == 0) {
            iIPConnected = true
        }

        NAVTimelineStart(TL_HEARTBEAT, ltHeartbeat, TIMELINE_ABSOLUTE, TIMELINE_REPEAT)

    }
    string: {
        NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                    NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_STRING_FROM,
                                                data.device,
                                                data.text))

        select {
            active (NAVContains(cRxBuffer, "'Password:'")): {
                cRxBuffer = "''"
                SendString("cPassword, NAV_CR, NAV_LF");
            }
            active (true): {
                if (!iSemaphore) { Process() }
            }
        }
    }
    offline: {
        if (data.device.number == 0) {
            NAVClientSocketClose(dvPort.port)

            iIPConnected = false
            iIPAuthenticated = false
            iCommunicating = false

            NAVTimelineStop(TL_HEARTBEAT)
        }
    }
    onerror: {
        if (data.device.number == 0) {
            iIPConnected = false
            iIPAuthenticated = false
            iCommunicating = false
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
        cCmdParam[2] = DuetParseCmdParam(data.text)

        switch (cCmdHeader) {
            case 'PROPERTY': {
                switch (cCmdParam[1]) {
                    case 'IP_ADDRESS': {
                        cIPAddress = cCmdParam[2]
                        NAVTimelineStart(TL_IP_CHECK, ltIPCheck, TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
                    }
                    case 'USER_NAME': {
                        cUserName = cCmdParam[2]
                    }
                    case 'PASSWORD': {
                        cPassword = cCmdParam[2]
                    }
                }
            }
            case 'INIT': {
                stack_var integer x

                for (x = 1; x <= length_array(vdvCommObjects); x++) {
                    send_string vdvCommObjects[x], "'REGISTER<', itoa(x), '>'"
                    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'EXTRON_DMP_REGISTER_SENT<', itoa(x), '>'")
                }
            }
        }
    }
}


data_event[vdvCommObjects] {
    online: {
        send_string data.device, "'REGISTER<', itoa(get_last(vdvCommObjects)), '>'"
        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'EXTRON_DMP_REGISTER<', itoa(get_last(vdvCommObjects)), '>'")
    }
    command: {
        stack_var char cCmdHeader[NAV_MAX_CHARS]
        stack_var integer iResponseObjectMessID

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_FROM, data.device, data.text))

        cCmdHeader = DuetParseCmdHeader(data.text)

        switch (cCmdHeader) {
            case 'COMMAND_MSG': { AddToQueue("cCmdHeader,data.text",true) }
            case 'POLL_MSG': { AddToQueue("cCmdHeader,data.text",false) }
            case 'RESPONSE_OK': {
                if (NAVGetStringBetween(data.text, '<', '>') == NAVGetStringBetween(uQueue.cLastMess, '<', '>')) {
                    GoodResponse()
                }
            }
            case 'INIT_DONE': {
                iInitializing = false

                iResponseObjectMessID = atoi(NAVGetStringBetween(data.text, '<', '>'))
                uObject[iResponseObjectMessID].iInitialized = true

                InitializeObjects()

                if (get_last(vdvCommObjects) == length_array(vdvCommObjects)) {
                    send_string vdvObject, "'INIT_DONE'"
                }
            }
            case 'REGISTER': {
                if (NAVContains(data.text, '|')) {
                    iResponseObjectMessID = atoi(NAVGetStringBetween(data.text, '<', '|'))

                    if (NAVContains(data.text,',')) {
                        stack_var integer x

                        x = 1
                        remove_string(data.text, '|', 1)

                        while (length_array(data.text) &&  (NAVContains(data.text ,',') || NAVContains(data.text, '>'))) {
                            select {
                                active (NAVContains(data.text, ',')): {
                                    cObjectTag[x][iResponseObjectMessID] = NAVStripCharsFromRight(remove_string(data.text, ',', 1), 1)
                                    x++
                                }
                                active (NAVContains(data.text,'>')): {
                                    cObjectTag[x][iResponseObjectMessID] = NAVStripCharsFromRight(remove_string(data.text, '>', 1), 1)
                                }
                            }
                        }
                    }
                    else {
                        cObjectTag[1][iResponseObjectMessID] = NAVGetStringBetween(data.text, '|', '>')
                    }

                    uObject[iResponseObjectMessID].iRegistered = true
                }
                else {
                    iResponseObjectMessID = atoi(NAVGetStringBetween(data.text, '<', '>'))
                    uObject[iResponseObjectMessID].iRegistered = true
                }

                if (get_last(vdvCommObjects) == length_array(vdvCommObjects)) {
                    iReadyToInitialize = true
                    AttemptToInitialize()
                }
            }
        }
    }
}


timeline_event[TL_HEARTBEAT] {
    if (!uQueue.iHasItems && !uQueue.iBusy) {
        AddToQueue("'POLL_MSG<HEARTBEAT|', NAV_ESC, '3CV', NAV_CR, '>'", false)
    }
}


timeline_event[TL_IP_CHECK] { MaintainIPConnection() }


timeline_event[TL_REGISTER] {
    stack_var integer x

    x = type_cast(timeline.repetition + 1)

    send_string vdvCommObjects[x], "'REGISTER<', itoa(x), '>'"
    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'EXTRON_DMP_REGISTER_SENT<', itoa(x), '>'")

    if (x == length_array(vdvCommObjects)) {
        NAVTimelineStop(timeline.id)
    }
}


timeline_event[TL_QUEUE_FAILED_RESPONSE] {
    if (uQueue.iBusy) {
        if (uQueue.iStrikeCount < 3) {
            uQueue.iStrikeCount++
            uQueue.iResendLast = true
            SendNextQueueItem()
        }
        else {
            iCommunicating = false
            Reset()
        }
    }
}


timeline_event[TL_NAV_FEEDBACK] {
    [vdvObject,NAV_IP_CONNECTED]	= (iIPConnected && iIPAuthenticated)
    [vdvObject,DEVICE_COMMUNICATING] = (iCommunicating)
    [vdvObject,DATA_INITIALIZED] = (iInitialized)
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

