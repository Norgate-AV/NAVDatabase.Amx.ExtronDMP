MODULE_NAME='mExtronDMPComm'	(
                                    dev vdvObject,
                                    dev vdvCommObjects[],
                                    dev dvPort
                                )

(***********************************************************)
#DEFINE USING_NAV_DEVICE_PRIORITY_QUEUE_SEND_NEXT_ITEM_EVENT_CALLBACK
#DEFINE USING_NAV_DEVICE_PRIORITY_QUEUE_FAILED_RESPONSE_EVENT_CALLBACK
#DEFINE USING_NAV_MODULE_BASE_CALLBACKS
#DEFINE USING_NAV_MODULE_BASE_PROPERTY_EVENT_CALLBACK
#DEFINE USING_NAV_STRING_GATHER_CALLBACK
#include 'NAVFoundation.ModuleBase.axi'
#include 'NAVFoundation.StringUtils.axi'
#include 'NAVFoundation.ErrorLogUtils.axi'
#include 'NAVFoundation.SocketUtils.axi'
#include 'NAVFoundation.DevicePriorityQueue.axi'
#include 'NAVFoundation.InterModuleApi.axi'
#include 'NAVFoundation.SnapiHelpers.axi'
#include 'NAVFoundation.TimelineUtils.axi'
#include 'LibExtronDMP.axi'

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

constant long TL_SOCKET_CHECK   = 1
constant long TL_HEARTBEAT	    = 2

constant long TL_SOCKET_CHECK_INTERVAL[]    = { 3000 }
constant long TL_HEARTBEAT_INTERVAL[]       = { 20000 }

constant char HEARTBEAT_COMMAND[] = "NAV_ESC, '3CV', NAV_CR"
constant char HEARTBEAT_RESPONSE_HEADER[] = 'Vrb'

constant char PASSWORD_PROMPT[] = 'Password:'

constant char DEVICE_DELIMITER[] = "{NAV_CR}, {NAV_LF}"


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile _DspObject object[MAX_OBJECTS]
volatile _NAVCredential credential

volatile char initializing = false
volatile integer initializingObjectID

volatile char ready = false


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
    if (dvPort.NUMBER == 0) {
        NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_STRING_TO,
                                            dvPort,
                                            payload))
    }


    send_string dvPort, "payload"
}


define_function SendString(char payload[]) {
    SendStringRaw("payload")
}


#IF_DEFINED USING_NAV_DEVICE_PRIORITY_QUEUE_SEND_NEXT_ITEM_EVENT_CALLBACK
define_function NAVDevicePriorityQueueSendNextItemEventCallback(char item[]) {
    stack_var char payload[NAV_MAX_BUFFER]

    payload = NAVInterModuleApiGetObjectMessage(item)

    SendString(payload)
}
#END_IF


define_function InitializeObjects() {
    stack_var integer x

    if (module.Device.IsInitialized || !ready) {
        return
    }

    if (initializing) {
        return
    }

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => Initializing objects'")

    for (x = 1; x <= length_array(vdvCommObjects); x++) {
        if (object[x].Api.IsRegistered && !object[x].Api.IsInitialized) {
            initializing = true
            SendObjectInitRequest(x)
            initializingObjectID = x

            break
        }

        if (x == length_array(vdvCommObjects) && !initializing) {
            initializingObjectID = x
            module.Device.IsInitialized = true
            UpdateFeedback()
        }
    }
}


#IF_DEFINED USING_NAV_DEVICE_PRIORITY_QUEUE_FAILED_RESPONSE_EVENT_CALLBACK
define_function NAVDevicePriorityQueueFailedResponseEventCallback(_NAVDevicePriorityQueue queue) {
    module.Device.IsCommunicating = false
    UpdateFeedback()
}
#END_IF


define_function Reset() {
    ReInitializeObjects()
}


define_function ReInitializeObjects() {
    stack_var integer x

    initializing = false
    module.Device.IsInitialized = false
    UpdateFeedback()

    initializingObjectID = 1

    for (x = 1; x <= length_array(object); x++) {
        object[x].Api.IsInitialized = false
    }
}


define_function SendObjectRegistrationRequest(integer id) {
    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => Requesting registration from Object ID: ', itoa(id)")
    send_string vdvCommObjects[id], "NAVInterModuleApiGetRegisterCommand(id)"
}


define_function SendObjectResponse(integer id, char data[]) {
    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => Sending response to Object ID: ', itoa(id), ' :: ', data")
    send_string vdvCommObjects[id], "NAVInterModuleApiBuildObjectResponseMessage(data)"
}


define_function SendObjectInitRequest(integer id) {
    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => Sending initialization request to Object ID: ', itoa(id)")
    send_string vdvCommObjects[id], "NAVInterModuleApiGetInitCommand(id)"
}


#IF_DEFINED USING_NAV_STRING_GATHER_CALLBACK
define_function NAVStringGatherCallback(_NAVStringGatherResult args) {
    if (dvPort.NUMBER == 0) {
        NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_PARSING_STRING_FROM,
                                            dvPort,
                                            args.Data))
    }

    args.Data = NAVStripCharsFromRight(args.Data, length_array(args.Delimiter))

    select {
        active (NAVContains(args.Data, HEARTBEAT_RESPONSE_HEADER)): {
            if (!module.Device.IsCommunicating) {
                module.Device.IsCommunicating = true
                UpdateFeedback()
            }

            InitializeObjects()
        }
        active (true): {
            stack_var integer x
            stack_var integer z

            for (x = 1; x <= length_array(vdvCommObjects); x++) {
                for (z = 1; z <= length_array(object[x].Api.Tag); z++) {
                    if (!NAVContains(args.Data, object[x].Api.Tag[z])) {
                        continue
                    }

                    SendObjectResponse(x, args.Data)

                    x = length_array(vdvCommObjects) + 1
                    break
                }
            }
        }
    }

    NAVDevicePriorityQueueGoodResponse(priorityQueue)
}
#END_IF


define_function Process(_NAVRxBuffer buffer) {
    if (NAVContains(buffer.Data, PASSWORD_PROMPT)) {
        buffer.Data = "''"
        SendString("credential.Password, NAV_CR, NAV_LF")

        return
    }

    NAVStringGather(buffer, "NAV_CR, NAV_LF")
}


define_function MaintainSocketConnection() {
    if (module.Device.SocketConnection.IsConnected) {
        return
    }

    NAVClientSocketOpen(dvPort.PORT,
                        module.Device.SocketConnection.Address,
                        module.Device.SocketConnection.Port,
                        IP_TCP)
}


define_function SendHeartbeat() {
    if (NAVDevicePriorityQueueHasItems(priorityQueue) || priorityQueue.Busy) {
        return
    }

    NAVDevicePriorityQueueEnqueue(priorityQueue,
                                    NAVInterModuleApiGetPollMessageCommand("'HEARTBEAT|', NAV_ESC, '3CV', NAV_CR"),
                                    false)
}


define_function SocketConnectionReset() {
    NAVTimelineStop(TL_SOCKET_CHECK)

    NAVClientSocketClose(dvPort.PORT)

    NAVTimelineStart(TL_SOCKET_CHECK,
                    TL_SOCKET_CHECK_INTERVAL,
                    TIMELINE_ABSOLUTE,
                    TIMELINE_REPEAT)
}


#IF_DEFINED USING_NAV_MODULE_BASE_PROPERTY_EVENT_CALLBACK
define_function NAVModulePropertyEventCallback(_NAVModulePropertyEvent event) {
    switch (upper_string(event.Name)) {
        case 'IP_ADDRESS': {
            module.Device.SocketConnection.Address = NAVTrimString(event.Args[1])
            module.Device.SocketConnection.Port = NAV_TELNET_PORT

            SocketConnectionReset()
        }
        case 'PASSWORD': {
            credential.Password = NAVTrimString(event.Args[1])
        }
    }
}
#END_IF


define_function ObjectRegister(integer index, tdata data) {
    stack_var integer id
    stack_var char tagList[NAV_MAX_BUFFER]
    stack_var integer count
    stack_var integer total

    id = NAVInterModuleApiGetObjectId(data.text)

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => New object registration received from Object ID: ', itoa(id)")

    if (NAVContains(data.text, '|')) {
        tagList = NAVInterModuleApiGetObjectMessage(data.text)
        NAVSplitString(tagList, ',', object[id].Api.Tag)
        set_length_array(object[id].Api.Tag, GetStringArrayLength(object[id].Api.Tag))

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => Object ID: ', itoa(id), ' has ', itoa(length_array(object[id].Api.Tag)), ' tags'")

        {
            stack_var integer x

            for (x = 1; x <= length_array(object[id].Api.Tag); x++) {
                NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => Object ID: ', itoa(id), ' Tag ', itoa(x), ': ', object[id].Api.Tag[x]")
            }
        }
    }

    object[id].Api.IsRegistered = true
    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => Object ID: ', itoa(id), ' is now registered'")

    total = length_array(vdvCommObjects)
    count = GetObjectRegistrationCount(total)
    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => ', itoa(count), ' out of ', itoa(total), ' objects are now registered'")

    if (count < total) {
        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => Waiting for more objects to register'")
        return
    }

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => All objects are now registered'")
    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => Object initialization will start after the next successful heartbeat'")
    ready = true
}


define_function integer GetObjectRegistrationCount(integer maxCount) {
    stack_var integer x
    stack_var integer count

    count = 0

    for (x = 1; x <= maxCount; x++) {
        if (object[x].Api.IsRegistered) {
            count++
        }
    }

    return count
}


define_function ObjectInitDone(integer index, tdata data) {
    stack_var integer id

    initializing = false

    id = NAVInterModuleApiGetObjectId(data.text)
    object[id].Api.IsInitialized = true

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPComm => Object ID: ', itoa(id), ' is now initialized'")

    InitializeObjects()

    if (index < length_array(vdvCommObjects)) {
        return
    }

    // We are done!
    send_string vdvObject, "OBJECT_INIT_DONE_MESSAGE_HEADER"
}


define_function ObjectResponseOk(tdata data) {
    if (NAVInterModuleApiGetObjectFullMessage(data.text) != NAVInterModuleApiGetObjectFullMessage(priorityQueue.LastMessage)) {
        return
    }

    NAVDevicePriorityQueueGoodResponse(priorityQueue)
}


define_function UpdateFeedback() {
    [vdvObject, NAV_IP_CONNECTED]	= (module.Device.SocketConnection.IsConnected &&
                                        module.Device.SocketConnection.IsAuthenticated)
    [vdvObject, DEVICE_COMMUNICATING] = (module.Device.IsCommunicating)
    [vdvObject, DATA_INITIALIZED] = (module.Device.IsInitialized)
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

        NAVTimelineStart(TL_HEARTBEAT,
                        TL_HEARTBEAT_INTERVAL,
                        TIMELINE_ABSOLUTE,
                        TIMELINE_REPEAT)

        if (data.device.number == 0) {
            module.Device.SocketConnection.IsConnected = true
            module.Device.SocketConnection.IsAuthenticated = true
            UpdateFeedback()
        }
    }
    string: {
        if (data.device.number == 0) {
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                        NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_STRING_FROM,
                                                    data.device,
                                                    data.text))
        }

        Process(module.RxBuffer)
    }
    offline: {
        if (data.device.number == 0) {
            NAVClientSocketClose(data.device.port)

            module.Device.SocketConnection.IsConnected = false
            module.Device.SocketConnection.IsAuthenticated = false
            module.Device.IsCommunicating = false
            UpdateFeedback()

            NAVTimelineStop(TL_HEARTBEAT)
        }
    }
    onerror: {
        if (data.device.number == 0) {
            module.Device.SocketConnection.IsConnected = false
            module.Device.SocketConnection.IsAuthenticated = false
            module.Device.IsCommunicating = false
            UpdateFeedback()
        }

        NAVErrorLog(NAV_LOG_LEVEL_ERROR,
                    "'mExtronDMPComm => OnError: ', NAVGetSocketError(type_cast(data.number))");
    }
}


data_event[vdvObject] {
    online: {
        set_length_array(object, length_array(vdvCommObjects))
    }
    command: {
        stack_var _NAVSnapiMessage message

        NAVParseSnapiMessage(data.text, message)

        switch (message.Header) {
            case OBJECT_INIT_MESSAGE_HEADER: {
                stack_var integer x

                for (x = 1; x <= length_array(vdvCommObjects); x++) {
                    SendObjectRegistrationRequest(x)
                }
            }
        }
    }
}


data_event[vdvCommObjects] {
    online: {
        SendObjectRegistrationRequest(get_last(vdvCommObjects))
    }
    command: {
        stack_var _NAVSnapiMessage message
        stack_var integer index

        NAVParseSnapiMessage(data.text, message)
        index = get_last(vdvCommObjects)

        switch (message.Header) {
            case OBJECT_COMMAND_MESSAGE_HEADER: {
                NAVDevicePriorityQueueEnqueue(priorityQueue, "data.text", true)
            }
            case OBJECT_QUERY_MESSAGE_HEADER: {
                NAVDevicePriorityQueueEnqueue(priorityQueue, "data.text", false)
            }
            case OBJECT_RESPONSE_OK_MESSAGE_HEADER: {
                ObjectResponseOk(data)
            }
            case OBJECT_INIT_DONE_MESSAGE_HEADER: {
                ObjectInitDone(index, data)
            }
            case OBJECT_REGISTRATION_MESSAGE_HEADER: {
                ObjectRegister(index, data)
            }
        }
    }
}


timeline_event[TL_HEARTBEAT] { SendHeartbeat() }


timeline_event[TL_SOCKET_CHECK] { MaintainSocketConnection() }


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
