MODULE_NAME='mExtronDMPLevel'	(
                                    dev vdvObject,
                                    dev vdvCommObject
                                )

(***********************************************************)
#DEFINE USING_NAV_MODULE_BASE_CALLBACKS
#DEFINE USING_NAV_MODULE_BASE_PROPERTY_EVENT_CALLBACK
#DEFINE USING_NAV_STRING_GATHER_CALLBACK
#include 'NAVFoundation.ModuleBase.axi'
#include 'NAVFoundation.Math.axi'
#include 'NAVFoundation.InterModuleApi.axi'
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

constant long TL_LEVEL_RAMP = 1

constant long TL_LEVEL_RAMP_INTERVAL[] = { 500 }


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile char label[NAV_MAX_CHARS]

volatile _DspLevel object

volatile integer registerReady
volatile integer registerRequested


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

define_function Register(_DspObject object) {
    stack_var char message[NAV_MAX_BUFFER]
    if (!registerRequested || !registerReady || !object.Api.Id) {
        return
    }

    ObjectTagInit(object)

    message = NAVInterModuleApiBuildObjectMessage(OBJECT_REGISTRATION_MESSAGE_HEADER,
                                    object.Api.Id,
                                    NAVInterModuleApiGetObjectTagList(object.Api))

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPLevel => ID: ', itoa(object.Api.Id), ' Data: ', message")

    NAVInterModuleApiSendObjectMessage(vdvCommObject, message)

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPLevel => Object Registering: ID: ', itoa(object.Api.Id)")

    object.Api.IsRegistered = true
}


#IF_DEFINED USING_NAV_STRING_GATHER_CALLBACK
define_function NAVStringGatherCallback(_NAVStringGatherResult args) {
    stack_var integer id

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_PARSING_STRING_FROM,
                                            vdvCommObject,
                                            args.Data))

    // if (NAVContains(module.RxBuffer.Data, args.Data)) {
    //     module.RxBuffer.Data = "''"
    // }

    id = NAVInterModuleApiGetObjectId(args.Data)
    // if (id != object.Properties.Id) {
    //     return
    // }
    NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                "'mExtronDMPLevel => Object ID: ', itoa(id), ' Data: ', args.Data");

    select {
        active (NAVStartsWith(args.Data, OBJECT_REGISTRATION_MESSAGE_HEADER)): {
            // object.Properties.Api.Id = NAVInterModuleApiGetObjectId(args.Data)
            object.Properties.Api.Id = id

            registerRequested = true
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                        "'mExtronDMPLevel => Object Registration Requested: ID: ', itoa(object.Properties.Api.Id)")

            Register(object.Properties)
        }
        active (NAVStartsWith(args.Data, OBJECT_INIT_MESSAGE_HEADER)): {
            object.Properties.Api.IsInitialized = false
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                        "'mExtronDMPLevel => Object Initialization Requested: ID: ', itoa(object.Properties.Api.Id)")

            GetInitialized(object.Properties)
        }
        active (NAVStartsWith(args.Data, OBJECT_RESPONSE_MESSAGE_HEADER)): {
            stack_var char response[NAV_MAX_BUFFER]

            response = NAVInterModuleApiGetObjectFullMessage(args.Data)

            switch (object.Properties.Attribute.Id) {
                case ATTRIBUTE_ID_GAIN: {
                    stack_var integer x

                    for (x = 1; x <= length_array(object.Properties.Api.Tag); x++) {
                        if (!NAVContains(response, object.Properties.Api.Tag[x])) {
                            continue
                        }

                        GetObjectLevel(response, object.Properties.Api.Tag[x])
                    }
                }
                case ATTRIBUTE_ID_GROUP: {
                    stack_var integer x

                    for (x = 1; x <= length_array(object.Properties.Api.Tag); x++) {
                        if (!NAVContains(response, object.Properties.Api.Tag[x])) {
                            continue
                        }

                        if (NAVContains(object.Properties.Api.Tag[x], ATTRIBUTE_RESPONSE_HEADER_GROUP_SOFT_LIMITS)) {
                            GetObjectLimits(response, object.Properties.Api.Tag[x])
                            continue
                        }

                        GetObjectLevel(response, object.Properties.Api.Tag[x])
                    }
                }
            }
        }
    }
}
#END_IF


define_function GetObjectLevel(char response[], char tag[]) {
    remove_string(response, "tag", 1)

    object.Level.Actual = atoi(response)
    UpdateObjectLevel(object)

    if (object.Properties.Api.IsInitialized) {
        return
    }

    NAVInterModuleApiSendObjectMessage(vdvCommObject,
                        NAVInterModuleApiBuildObjectMessage(OBJECT_INIT_DONE_MESSAGE_HEADER,
                                            object.Properties.Api.Id,
                                            ''))

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                "'mExtronDMPLevel => Object Initialization Complete: ID: ', itoa(object.Properties.Api.Id)")
    object.Properties.Api.IsInitialized = true
}


define_function UpdateObjectLevel(_DspLevel object) {
    stack_var sinteger level

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                "'mExtronDMPLevel => Object Soft Limits: ID: ', itoa(object.Properties.Api.Id), ' Min: ', itoa(object.MinLevel), ' Max: ', itoa(object.MaxLevel)")

    level = NAVScaleValue((object.Level.Actual - object.MinLevel),
                                (object.MaxLevel - object.MinLevel),
                                255,
                                0)

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                "'mExtronDMPLevel => Object Level: ID: ', itoa(object.Properties.Api.Id), ' Level: ', itoa(level)")

    send_level vdvObject, VOL_LVL, level
    send_string vdvObject, "'VOLUME-ABS,', itoa(object.Level.Actual)"
}


define_function GetObjectLimits(char response[], char tag[]) {
    remove_string(response, "tag", 1)

    object.MaxLevel = atoi(NAVStripCharsFromRight(remove_string(response, '*', 1), 1))
    object.MinLevel = atoi(response)

    if (abs_value(object.MaxLevel) >= 1000) {
        object.MaxLevel = object.MaxLevel / 100
    }

    if (abs_value(object.MinLevel) >= 1000) {
        object.MinLevel = object.MinLevel / 100
    }

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                "'mExtronDMPLevel => Object Soft Limits: ID: ', itoa(object.Properties.Api.Id), ' Min: ', itoa(object.MinLevel), ' Max: ', itoa(object.MaxLevel)")

    UpdateObjectLevel(object)
}


define_function GetInitialized(_DspObject object) {
    switch (object.Attribute.Id) {
        case ATTRIBUTE_ID_GAIN: {
            NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                NAVInterModuleApiBuildObjectMessage(OBJECT_QUERY_MESSAGE_HEADER,
                                                    object.Api.Id,
                                                    BuildPayload(object, '')))
        }
        case ATTRIBUTE_ID_GROUP: {
            NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                NAVInterModuleApiBuildObjectMessage(OBJECT_QUERY_MESSAGE_HEADER,
                                                    object.Api.Id,
                                                    BuildCustomPayload('L', object.Attribute.Value[1], '')))
            NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                NAVInterModuleApiBuildObjectMessage(OBJECT_QUERY_MESSAGE_HEADER,
                                                    object.Api.Id,
                                                    BuildPayload(object, '')))
        }
    }
}


#IF_DEFINED USING_NAV_MODULE_BASE_PROPERTY_EVENT_CALLBACK
define_function NAVModulePropertyEventCallback(_NAVModulePropertyEvent event) {
    switch (upper_string(event.Name)) {
        case 'ATTRIBUTE': {
            object.Properties.Attribute.Id = event.Args[1]
        }
        case 'INDEX_1': {
            object.Properties.Attribute.Value[1] = event.Args[1]
        }
        case 'INDEX_2': {
            object.Properties.Attribute.Value[2] = event.Args[1]
        }
        case 'INDEX_3': {
            object.Properties.Attribute.Value[3] = event.Args[1]
        }
        case 'INDEX_4': {
            object.Properties.Attribute.Value[4] = event.Args[1]
        }
        case 'MAX_LEVEL': {
            if (length_array(event.Args[1])) {
                object.MaxLevel = atoi(event.Args[1]) * 10
            }
        }
        case 'MIN_LEVEL': {
            if (length_array(event.Args[1])) {
                object.MinLevel = atoi(event.Args[1]) * 10
            }
        }
        case 'LABEL': {
            label = event.Args[1]
        }
    }
}
#END_IF


define_function IncrementLevel(integer direction) {
    switch (direction) {
        case VOL_UP: {
            if (object.Properties.Attribute.Id == ATTRIBUTE_ID_GAIN) {
                NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                    NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                        object.Properties.Api.Id,
                                                        BuildPayload(object.Properties, itoa(object.Level.Actual + 10))))
                return
            }

            NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                    object.Properties.Api.Id,
                                                    BuildPayload(object.Properties, '10+')))
        }
        case VOL_DN: {
            if (object.Properties.Attribute.Id == ATTRIBUTE_ID_GAIN) {
                NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                    NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                        object.Properties.Api.Id,
                                                        BuildPayload(object.Properties, itoa(object.Level.Actual - 10))))
                return
            }

            NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                    object.Properties.Api.Id,
                                                    BuildPayload(object.Properties, '10-')))
        }
    }
}


define_function RampLevel() {
    select {
        active ([vdvObject, VOL_UP]): {
            IncrementLevel(VOL_UP)
        }
        active ([vdvObject, VOL_DN]): {
            IncrementLevel(VOL_DN)
        }
    }
}


define_function ObjectChannelEvent(tchannel channel) {
    switch (channel.channel) {
        case VOL_UP:
        case VOL_DN: {
            if (!object.Properties.Api.IsInitialized) {
                return
            }

            IncrementLevel(channel.channel)

            NAVTimelineStart(TL_LEVEL_RAMP, TL_LEVEL_RAMP_INTERVAL, TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
        }
    }
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {
    create_buffer vdvCommObject, module.RxBuffer.Data
    DspLevelInit(object)
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[vdvCommObject] {
    string: {
        NAVStringGather(module.RxBuffer, '>')
    }
}


data_event[vdvObject] {
    online: {

    }
    command: {
        stack_var _NAVSnapiMessage message

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                    NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_FROM,
                                                data.device,
                                                data.text))

        NAVParseSnapiMessage(data.text, message)

        switch (message.Header) {
            case OBJECT_REGISTRATION_MESSAGE_HEADER: {
                // object.Properties.Id = GetObjectId(message.Parameter[1])

                registerReady = true

                Register(object.Properties)
            }
            case '?LABEL': {
                if (length_array(label)) {
                    NAVCommand(data.device, "'PROPERTY-LABEL,', label")
                }
            }
            case OBJECT_INIT_MESSAGE_HEADER: {
                GetInitialized(object.Properties)
            }
            case 'VOLUME': {
                if (!object.Properties.Api.IsInitialized) {
                    break
                }

                switch (message.Parameter[1]) {
                    case 'QUARTER': {
                        NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                            NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                object.Properties.Api.Id,
                                                                BuildPayload(object.Properties,
                                                                            itoa(NAVQuarterPointOfRange(object.MaxLevel, object.MinLevel)))))
                    }
                    case 'HALF': {
                        NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                            NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                object.Properties.Api.Id,
                                                                BuildPayload(object.Properties,
                                                                            itoa(NAVHalfPointOfRange(object.MaxLevel, object.MinLevel)))))
                    }
                    case 'THREE_QUARTERS': {
                        NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                            NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                object.Properties.Api.Id,
                                                                BuildPayload(object.Properties,
                                                                            itoa(NAVThreeQuarterPointOfRange(object.MaxLevel, object.MinLevel)))))
                    }
                    case 'FULL': {
                        NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                            NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                object.Properties.Api.Id,
                                                                BuildPayload(object.Properties, itoa(object.MaxLevel))))
                    }
                    case 'INC': {
                        if (object.Level.Actual < object.MaxLevel) {
                            NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                                NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                    object.Properties.Api.Id,
                                                                    BuildPayload(object.Properties, itoa(object.Level.Actual + 10))))
                        }
                    }
                    case 'DEC': {
                        if (object.Level.Actual > object.MinLevel) {
                            NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                                NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                    object.Properties.Api.Id,
                                                                    BuildPayload(object.Properties, itoa(object.Level.Actual - 10))))
                        }
                    }
                    case 'ABS': {
                        if ((atoi(message.Parameter[2]) >= object.MinLevel) && (atoi(message.Parameter[2]) <= object.MaxLevel)) {
                            NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                                NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                    object.Properties.Api.Id,
                                                                    BuildPayload(object.Properties, message.Parameter[2])))
                        }
                    }
                    default: {
                        stack_var sinteger level
                        stack_var sinteger min
                        stack_var sinteger max

                        // Remove the decimal point
                        min = object.MinLevel / 10
                        max = object.MaxLevel / 10

                        level = NAVScaleValue(atoi(message.Parameter[1]),
                                                255,
                                                (max - min),
                                                min)

                        if ((level >= min) && (level <= max)) {
                            NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                                NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                    object.Properties.Api.Id,
                                                                    BuildPayload(object.Properties, itoa(level * 10))))
                        }
                    }
                }
            }
        }
    }
}


channel_event[vdvObject, 0] {
    on: {
        ObjectChannelEvent(channel)
    }
    off: {
        NAVTimelineStop(TL_LEVEL_RAMP)
    }
}


timeline_event[TL_LEVEL_RAMP] {
    RampLevel()
}


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
