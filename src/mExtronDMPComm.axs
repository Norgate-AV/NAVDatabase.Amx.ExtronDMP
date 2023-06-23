MODULE_NAME='mExtronDMPComm'	(
                                    dev vdvObject,
                                    dev vdvCommObjects[],
                                    dev dvPort
                                )

(***********************************************************)
#DEFINE USING_NAV_DEVICE_PRIORITY_QUEUE_SEND_NEXT_ITEM_EVENT_CALLBACK
#DEFINE USING_NAV_DEVICE_PRIORITY_QUEUE_FAILED_RESPONSE_EVENT_CALLBACK
#DEFINE USING_NAV_MODULE_BASE_PROPERTY_EVENT_CALLBACK
#DEFINE USING_NAV_STRING_GATHER_CALLBACK
#include 'NAVFoundation.ModuleBase.axi'
#include 'NAVFoundation.SocketUtils.axi'
#include 'NAVFoundation.DevicePriorityQueue.axi'
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
constant long TL_HEARTBEAT	= 3
constant long TL_REGISTER	= 4


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

struct _Object {
    integer Initialized
    integer Registered
}


(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile long heartbeat[] = { 30000 }
volatile long ipCheck[] = { 3000 }
volatile long register[]	= { 500 }

volatile _Object object[MAX_OBJECTS]
volatile _NAVCredential credential

volatile integer initializing
volatile integer initializingObjectID

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


define_function NAVDevicePriorityQueueSendNextItemEventCallback(char item[]) {
    stack_var char payload[NAV_MAX_BUFFER]

    payload = GetMess(item)

    SendString(payload)
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

    if (initializing) {
        return
    }

    for (x = 1; x <= length_array(vdvCommObjects); x++) {
        if (object[x].Registered && !object[x].Initialized) {
            initializing = true
            send_string vdvCommObjects[x], "'INIT<', itoa(x), '>'"
            initializingObjectID = x

            break
        }

        if (x == length_array(vdvCommObjects) && !initializing) {
            initializingObjectID = x
            module.Device.IsInitialized = true
        }
    }
}


define_function NAVDevicePriorityQueueFailedResponseEventCallback(_NAVDevicePriorityQueue queue) {
    module.Device.IsCommunicating = false
}


define_function Reset() {
    ReInitializeObjects()
    // InitializeQueue()
}


define_function ReInitializeObjects() {
    stack_var integer x

    initializing = false
    module.Device.IsInitialized = false
    initializingObjectID = 1

    for (x = 1; x <= length_array(object); x++) {
        object[x].Initialized = false
    }
}


define_function NAVStringGatherCallback(_NAVStringGatherResult args) {
    NAVLog(NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_PARSING_STRING_FROM, dvPort, args.Data))

    args.Data = NAVStripCharsFromRight(args.Data, 2)

    select {
        active (NAVContains(args.Data, 'Vrb')): {
            module.Device.IsCommunicating = true

            if (!module.Device.IsInitialized && readyToInitialize) {
                InitializeObjects()
            }
        }
        active (true): {
            stack_var integer x
            stack_var integer z

            for (x = 1; x <= length_array(vdvCommObjects); x++) {
                for (z = 1; z <= MAX_OBJECT_TAGS; z++) {
                    if (!NAVContains(args.Data, objectTag[z][x])) {
                        continue
                    }

                    send_string vdvCommObjects[x], "'RESPONSE_MSG<', args.Data, '>'"
                    NAVLog("'EXTRON_DMP_SENDING_RESPONSE_MSG<', args.Data, '|', itoa(x), '>'")

                    break
                }

                break
            }
        }
    }

    NAVDevicePriorityQueueGoodResponse(priorityQueue)
}


define_function MaintainIPConnection() {
    if (module.Device.SocketConnection.IsConnected) {
        return
    }

    NAVClientSocketOpen(dvPort.port, module.Device.SocketConnection.Address, NAV_TELNET_PORT, IP_TCP)
}


define_function SendHeartbeat() {
    if (NAVDevicePriorityQueueHasItems(priorityQueue) || priorityQueue.Busy) {
        return
    }

    NAVDevicePriorityQueueEnqueue(priorityQueue, "'POLL_MSG<HEARTBEAT|', NAV_ESC, '3CV', NAV_CR, '>'", false)
}


define_function NAVModulePropertyEventCallback(_NAVModulePropertyEvent event) {
    switch (upper_string(event.Name)) {
        case 'IP_ADDRESS': {
            module.Device.SocketConnection.Address = event.Args[1]
            NAVTimelineStart(TL_IP_CHECK, ipCheck, TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
        }
        case 'PASSWORD': {
            credential.Password = event.Args[1]
        }
    }
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {
    create_buffer dvPort, module.RxBuffer.Data
    Reset()
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[dvPort] {
    online: {
        if (data.device.number != 0) {
            NAVCommand(data.device, "'SET BAUD 38400,N,8,1 485 DISABLE'")
            NAVCommand(data.device, "'B9MOFF'")
            NAVCommand(data.device, "'CHARD-0'")
            NAVCommand(data.device, "'CHARDM-0'")
            NAVCommand(data.device, "'HSOFF'")
        }

        NAVTimelineStart(TL_HEARTBEAT, heartbeat, TIMELINE_ABSOLUTE, TIMELINE_REPEAT)

        if (data.device.number == 0) {
            module.Device.SocketConnection.IsConnected = true
        }
    }
    string: {
        NAVLog(NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_STRING_FROM, data.device, data.text))

        select {
            active (NAVContains(module.RxBuffer.Data, "'Password:'")): {
                module.RxBuffer.Data = "''"
                SendString("credential.Password, NAV_CR, NAV_LF");
            }
            active (true): {
                NAVStringGather(module.RxBuffer, "NAV_LF")
            }
        }
    }
    offline: {
        if (data.device.number == 0) {
            NAVClientSocketClose(dvPort.port)
            module.Device.SocketConnection.IsConnected = false
            module.Device.SocketConnection.IsAuthenticated = false
            module.Device.IsCommunicating = false
            NAVTimelineStop(TL_HEARTBEAT)
        }
    }
    onerror: {
        if (data.device.number == 0) {
            module.Device.SocketConnection.IsConnected = false
            module.Device.SocketConnection.IsAuthenticated = false
            module.Device.IsCommunicating = false
        }
    }
}


data_event[vdvObject] {
    command: {
        stack_var _NAVSnapiMessage message

        NAVLog(NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_FROM, data.device, data.text))

        NAVParseSnapiMessage(data.text, message)

        switch (message.Header) {
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
            case 'COMMAND_MSG': {
                NAVDevicePriorityQueueEnqueue(priorityQueue, "cmdHeader, data.text", true)
            }
            case 'POLL_MSG': {
                NAVDevicePriorityQueueEnqueue(priorityQueue, "cmdHeader, data.text", false)
            }
            case 'RESPONSE_OK': {
                if (NAVGetStringBetween(data.text, '<', '>') == NAVGetStringBetween(priorityQueue.LastMessage, '<', '>')) {
                    NAVDevicePriorityQueueGoodResponse(priorityQueue)
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


timeline_event[TL_HEARTBEAT] { SendHeartbeat() }


timeline_event[TL_IP_CHECK] { MaintainIPConnection() }


timeline_event[TL_REGISTER] {
    stack_var integer x

    x = type_cast(timeline.repetition + 1)
    send_string vdvCommObjects[x], "'REGISTER<', itoa(x), '>'"

    NAVLog("'EXTRON_DMP_REGISTER_SENT<', itoa(x), '>'")

    if (x == length_array(vdvCommObjects)) {
        NAVTimelineStop(timeline.id)
    }
}


timeline_event[TL_NAV_FEEDBACK] {
    [vdvObject, NAV_IP_CONNECTED]	= (module.Device.SocketConnection.IsConnected && module.Device.SocketConnection.IsAuthenticated)
    [vdvObject, DEVICE_COMMUNICATING] = (module.Device.IsCommunicating)
    [vdvObject, DATA_INITIALIZED] = (module.Device.IsInitialized)
}


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
