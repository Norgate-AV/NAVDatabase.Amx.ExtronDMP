MODULE_NAME='mExtronDMPComm'	(
                                    dev vdvObject,
                                    dev vdvCommObjects[],
                                    dev dvPort
                                )

(***********************************************************)
#include 'NAVFoundation.ModuleBase.axi'
#include 'NAVFoundation.SocketUtils.axi'
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

constant long TL_IP_CHECK = 1
constant long TL_QUEUE_FAILED_RESPONSE	= 2
constant long TL_HEARTBEAT	= 3
constant long TL_REGISTER	= 4

constant integer MAX_QUEUE_COMMANDS = 50
constant integer MAX_QUEUE_STATUS = 100


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

struct _Object {
    integer Initialized
    integer Registered
}

struct _Queue {
    integer Busy
    integer HasItems
    integer CommandHead
    integer CommandTail
    integer StatusHead
    integer StatusTail
    integer StrikeCount
    integer ResendLast
    char LastMess[NAV_MAX_BUFFER]
}


(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile long heartbeat[] = { 30000 }
volatile long ipCheck[] = { 3000 }
volatile long queueFailedResponse[]	= { 2500 }
volatile long register[]	= { 500 }

volatile _Object object[MAX_OBJECTS]

volatile _Queue queue
volatile char commandQueue[MAX_QUEUE_COMMANDS][NAV_MAX_BUFFER]
volatile char statusQueue[MAX_QUEUE_STATUS][NAV_MAX_BUFFER]

volatile char rxBuffer[NAV_MAX_BUFFER]
volatile integer semaphore

volatile char ipAddress[15]
volatile integer ipConnected = false
volatile integer ipAuthenticated

volatile integer initializing
volatile integer initializingObjectID

volatile integer initialized
volatile integer communicating

volatile char userName[NAV_MAX_CHARS] = 'clearone'
volatile char password[NAV_MAX_CHARS] = 'converge'

volatile char objectTag[MAX_OBJECT_TAGS][MAX_OBJECTS][NAV_MAX_CHARS]

volatile integer delayedRegisterRequired[MAX_OBJECTS]

volatile integer registering
volatile integer registeringObjectID
volatile integer allRegistered

volatile integer readyToInitialize


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

define_function SendStringRaw(char payload[]) {
    NAVLog(NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_STRING_TO, dvPort, payload))
    send_string dvPort, "payload"
}


define_function SendString(char payload[]) {
    SendStringRaw("payload")
}


define_function AddToQueue(char item[], integer priority) {
    stack_var integer queueWasEmpty

    queueWasEmpty = (!queue.HasItems && !queue.Busy)

    switch (priority) {
        case true: {
            select {
                active (queue.CommandHead == max_length_array(commandQueue)): {
                    if (queue.CommandTail != 1) {
                        queue.CommandHead = 1
                        commandQueue[queue.CommandHead] = item
                        queue.HasItems = true
                    }
                }
                active (queue.CommandTail != (queue.CommandHead + 1)): {
                    queue.CommandHead++
                    commandQueue[queue.CommandHead] = item
                    queue.HasItems = true
                }
            }
        }
        case false: {
            select {
                active (queue.StatusHead == max_length_array(statusQueue)): {
                    if (queue.StatusTail != 1) {
                        queue.StatusHead = 1
                        statusQueue[queue.StatusHead] = item
                        queue.HasItems = true
                    }
                }
                active (queue.StatusTail != (queue.StatusHead + 1)): {
                    queue.StatusHead++
                    statusQueue[queue.StatusHead] = item
                    queue.HasItems = true
                }
            }
        }
    }

    if (queueWasEmpty) { SendNextQueueItem(); }
}


define_function char[NAV_MAX_BUFFER] RemoveFromQueue() {
    if (queue.HasItems && !queue.Busy) {
        queue.Busy = true

        select {
            active (queue.CommandHead != queue.CommandTail): {
                if (queue.CommandTail == max_length_array(commandQueue)) {
                    queue.CommandTail = 1
                }
                else {
                    queue.CommandTail++
                }

                queue.LastMess = commandQueue[queue.CommandTail]
            }
            active (queue.StatusHead != queue.StatusTail): {
                if (queue.StatusTail == max_length_array(statusQueue)) {
                    queue.StatusTail = 1
                }
                else {
                    queue.StatusTail++
                }

                queue.LastMess = statusQueue[queue.StatusTail]
            }
        }

        if ((queue.CommandHead == queue.CommandTail) && (queue.StatusHead == queue.StatusTail)) {
            queue.HasItems = false
        }

        return GetMess(queue.LastMess)
    }

    return ''
}


define_function integer GetMessID(char param[]) {
    return atoi(NAVGetStringBetween(param, '<', '|'))
}


define_function integer GetSubscriptionMessID(char param[]) {
    return atoi(NAVGetStringBetween(param, '[', '*'))
}


define_function char[NAV_MAX_BUFFER] GetMess(char param[]) {
    return NAVGetStringBetween(param, '|', '>')
}


define_function InitializeObjects() {
    stack_var integer x

    if (!initializing) {
        for (x = 1; x <= length_array(vdvCommObjects); x++) {
            if (object[x].Registered && !object[x].Initialized) {
                initializing = true
                send_string vdvCommObjects[x], "'INIT<', itoa(x), '>'"
                initializingObjectID = x
                break
            }

            if (x == length_array(vdvCommObjects) && !initializing) {
                initializingObjectID = x
                initialized = true
            }
        }
    }
}


define_function GoodResponse() {
    queue.Busy = false
    NAVTimelineStop(TL_QUEUE_FAILED_RESPONSE)

    queue.StrikeCount = 0
    queue.ResendLast = false
    SendNextQueueItem()
}


define_function SendNextQueueItem() {
    stack_var char temp[NAV_MAX_BUFFER]

    if (queue.ResendLast) {
        queue.ResendLast = false
        temp = GetMess(queue.LastMess)
    }
    else {
        temp= RemoveFromQueue()
    }

    if (length_array(temp)) {
        SendString(temp)
        timeline_create(TL_QUEUE_FAILED_RESPONSE, queueFailedResponse, length_array(queueFailedResponse), TIMELINE_ABSOLUTE, TIMELINE_ONCE)
    }
}


define_function Reset() {
    ReInitializeObjects()
    InitializeQueue()
}


define_function ReInitializeObjects() {
    stack_var integer x

    initializing = false
    initialized = false
    initializingObjectID = 1

    for (x = 1; x <= length_array(object); x++) {
        object[x].Initialized = false
    }
}


define_function InitializeQueue() {
    queue.Busy = false
    queue.HasItems = false
    queue.CommandHead = 1
    queue.CommandTail = 1
    queue.StatusHead = 1
    queue.StatusTail = 1
    queue.StrikeCount = 0
    queue.ResendLast = false
    queue.LastMess = "''"
}


define_function Process() {
    stack_var char temp[NAV_MAX_BUFFER]

    semaphore = true

    while (length_array(rxBuffer) && NAVContains(rxBuffer, "NAV_LF")) {
        temp = remove_string(rxBuffer, "NAV_LF", 1)

        if (length_array(temp)) {
            stack_var integer responseMessID

            NAVLog(NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_PARSING_STRING_FROM, dvPort, temp))

            temp = NAVStripCharsFromRight(temp, 2)

            select {
                active (NAVContains(temp, 'Vrb')): {
                    if (!communicating) {
                        communicating = true
                    }

                    if (communicating && !initialized && readyToInitialize) {
                        InitializeObjects()
                    }
                }
                active (1): {
                    stack_var integer x
                    stack_var integer i
                    for (x = 1; x <= length_array(vdvCommObjects); x++) {
                        for (i = 1; i <= MAX_OBJECT_TAGS; i++) {
                            if (NAVContains(temp, objectTag[i][x])) {
                                send_string vdvCommObjects[x], "'RESPONSE_MSG<', temp, '>'"
                                NAVLog("'EXTRON_DMP_SENDING_RESPONSE_MSG<', temp, '|', itoa(x), '>'")
                                i = (MAX_OBJECT_TAGS + 1)
                                x = (MAX_OBJECTS + 1)
                            }
                        }
                    }
                }
            }

            GoodResponse()
        }
    }

    semaphore = false
}


define_function MaintainIPConnection() {
    if (!ipConnected) {
        NAVClientSocketOpen(dvPort.port, ipAddress, NAV_TELNET_PORT, IP_TCP)
    }
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {
    create_buffer dvPort, rxBuffer
    Reset()
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[dvPort] {
    online: {
        if (data.device.number != 0) {
            send_command data.device,"'SET BAUD 38400,N,8,1 485 DISABLE'"
            send_command data.device,"'B9MOFF'"
            send_command data.device,"'CHARD-0'"
            send_command data.device,"'CHARDM-0'"
            send_command data.device,"'HSOFF'"
        }

        timeline_create(TL_HEARTBEAT,heartbeat,length_array(heartbeat),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)

        if (data.device.number == 0) {
            ipConnected = true
        }
    }
    string: {
        NAVLog(NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_STRING_FROM, data.device, data.text))

        select {

            active (NAVContains(rxBuffer, "'Password:'")): {
                rxBuffer = "''"
                SendString("password, NAV_CR, NAV_LF");
            }
            active (1): {
                if (!semaphore) { Process() }
            }
        }
    }
    offline: {
        if (data.device.number == 0) {
            NAVClientSocketClose(dvPort.port)
            ipConnected = false
            ipAuthenticated = false
            communicating = false
            NAVTimelineStop(TL_HEARTBEAT)
        }
    }
    onerror: {
        if (data.device.number == 0) {
            // ipConnected = false
            // ipAuthenticated = false
            // communicating = false
        }
    }
}


data_event[vdvObject] {
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
                    case 'IP_ADDRESS': {
                        ipAddress = cmdParam[2]
                        timeline_create(TL_IP_CHECK, ipCheck, length_array(ipCheck), timeline_absolute, timeline_repeat)
                    }
                    case 'USER_NAME': {
                        userName = cmdParam[2]
                    }
                    case 'PASSWORD': {
                        password = cmdParam[2]
                    }
                }
            }
            case 'INIT': {
                stack_var integer x

                for (x = 1; x <= length_array(vdvCommObjects); x++) {
                    send_string vdvCommObjects[x], "'REGISTER<', itoa(x), '>'"
                    NAVLog("'EXTRON_DMP_REGISTER_SENT<', itoa(x), '>'")
                }
            }
        }
    }
}


data_event[vdvCommObjects] {
    online: {
        send_string data.device, "'REGISTER<', itoa(get_last(vdvCommObjects)), '>'"
        NAVLog("'EXTRON_DMP_REGISTER<', itoa(get_last(vdvCommObjects)), '>'")
    }
    command: {
        stack_var char cmdHeader[NAV_MAX_CHARS]
        stack_var integer responseObjectMessID

        NAVLog(NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_FROM, data.device, data.text))

        cmdHeader = DuetParseCmdHeader(data.text)

        switch (cmdHeader) {
            case 'COMMAND_MSG': { AddToQueue("cmdHeader, data.text", true) }
            case 'POLL_MSG': { AddToQueue("cmdHeader, data.text", false) }
            case 'RESPONSE_OK': {
                if (NAVGetStringBetween(data.text, '<', '>') == NAVGetStringBetween(queue.LastMess, '<', '>')) {
                    GoodResponse()
                }
            }
            case 'INIT_DONE': {
                initializing = false

                responseObjectMessID = atoi(NAVGetStringBetween(data.text, '<', '>'))
                object[responseObjectMessID].Initialized = true

                InitializeObjects()

                if (get_last(vdvCommObjects) == length_array(vdvCommObjects)) {
                    // Init is Done!
                    send_string vdvObject, "'INIT_DONE'"
                }
            }
            case 'REGISTER': {
                if (NAVContains(data.text, '|')) {
                    responseObjectMessID = atoi(NAVGetStringBetween(data.text, '<', '|'))

                    if (NAVContains(data.text, ',')) {
                        stack_var integer x

                        x = 1
                        remove_string(data.text, '|',1)

                        while (length_array(data.text) &&  (NAVContains(data.text, ',') || NAVContains(data.text, '>'))) {
                            select {
                                active (NAVContains(data.text, ',')): {
                                    objectTag[x][responseObjectMessID] = NAVStripCharsFromRight(remove_string(data.text, ',', 1), 1)
                                    x++
                                }
                                active (NAVContains(data.text, '>')): {
                                    objectTag[x][responseObjectMessID] = NAVStripCharsFromRight(remove_string(data.text, '>', 1), 1)
                                }
                            }
                        }
                    }
                    else {
                        objectTag[1][responseObjectMessID] = NAVGetStringBetween(data.text, '|', '>')
                    }

                    object[responseObjectMessID].Registered = true
                }
                else {
                    responseObjectMessID = atoi(NAVGetStringBetween(data.text, '<', '>'))
                    object[responseObjectMessID].Registered = true
                }

                if (get_last(vdvCommObjects) == length_array(vdvCommObjects)) {
                    readyToInitialize = true
                }
            }
        }
    }
}


timeline_event[TL_HEARTBEAT] {
    if (!queue.HasItems && !queue.Busy) {
        AddToQueue("'POLL_MSG<HEARTBEAT|', NAV_ESC, '3CV', NAV_CR, '>'", false)
    }
}


timeline_event[TL_IP_CHECK] { MaintainIPConnection() }


timeline_event[TL_REGISTER] {
    stack_var integer x

    x = type_cast(timeline.repetition + 1)
    send_string vdvCommObjects[x], "'REGISTER<', itoa(x), '>'"

    NAVLog("'EXTRON_DMP_REGISTER_SENT<', itoa(x), '>'")

    if (x == length_array(vdvCommObjects)) {
        timeline_kill(timeline.id)
    }
}


timeline_event[TL_QUEUE_FAILED_RESPONSE] {
    if (queue.Busy) {
        if (queue.StrikeCount < 3) {
            queue.StrikeCount++
            queue.ResendLast = true
            SendNextQueueItem()
        }
        else {
            communicating = false
            Reset()
        }
    }
}


timeline_event[TL_NAV_FEEDBACK] {
    [vdvObject, NAV_IP_CONNECTED]	= (ipConnected && ipAuthenticated)
    [vdvObject, DEVICE_COMMUNICATING] = (communicating)
    [vdvObject, DATA_INITIALIZED] = (initialized)
}


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
