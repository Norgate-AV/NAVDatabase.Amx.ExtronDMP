MODULE_NAME='mExtronDMPLevel'	(
                                    dev vdvObject,
                                    dev vdvCommObject
                                )

(***********************************************************)
#DEFINE USING_NAV_MODULE_BASE_PROPERTY_EVENT_CALLBACK
#DEFINE USING_NAV_STRING_GATHER_CALLBACK
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

constant long TL_LEVEL_RAMP = 1


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile long levelRamp[] = { 500 }

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
    if (!registerRequested || !registerReady || !object.Id) {
        return
    }

    ObjectTagInit(object)

    SendObjectMessage(vdvCommObject,
                        BuildObjectMessage(OBJECT_REGISTRATION_MESSAGE_HEADER,
                                            object.Id,
                                            GetObjectTagList(object)))

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPLevel => Object Registering: ID-', itoa(object.Id)")

    object.IsRegistered = true
}


define_function NAVStringGatherCallback(_NAVStringGatherResult args) {
    stack_var integer id

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                    NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_PARSING_STRING_FROM,
                                                vdvCommObject,
                                                args.Data))

    if (NAVContains(module.RxBuffer.Data, args.Data)) {
        module.RxBuffer.Data = "''"
    }

    id = GetObjectId(args.Data)
    if (id != object.Properties.Id) {
        return
    }

    select {
        active (NAVStartsWith(args.Data, OBJECT_REGISTRATION_MESSAGE_HEADER)): {
            registerRequested = true
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                        "'mExtronDMPLevel => Object Registration Requested: ID-', itoa(object.Properties.Id)")

            Register(object.Properties)
        }
        active (NAVStartsWith(args.Data, OBJECT_INIT_MESSAGE_HEADER)): {
            object.Properties.IsInitialized = false
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                        "'mExtronDMPLevel => Object Initialization Requested: ID-', itoa(object.Properties.Id)")

            GetInitialized(object.Properties)
        }
        active (NAVStartsWith(args.Data, OBJECT_RESPONSE_MESSAGE_HEADER)): {
            stack_var char response[NAV_MAX_BUFFER]

            response = GetObjectFullMessage(args.Data)

            switch (object.Properties.Attribute.Id) {
                case ATTRIBUTE_ID_GAIN: {
                    stack_var integer x

                    for (x = 1; x <= length_array(object.Properties.Tag); x++) {
                        if (!NAVContains(response, object.Properties.Tag[x])) {
                            continue
                        }

                        GetObjectLevel(response, object.Properties.Tag[x])
                    }
                }
                case ATTRIBUTE_ID_GROUP: {
                    stack_var integer x

                    for (x = 1; x <= length_array(object.Properties.Tag); x++) {
                        if (!NAVContains(response, object.Properties.Tag[x])) {
                            continue
                        }

                        if (NAVContains(object.Properties.Tag[x], ATTRIBUTE_RESPONSE_HEADER_GROUP_SOFT_LIMITS)) {
                            GetObjectLimits(response, object.Properties.Tag[x])
                            continue
                        }

                        GetObjectLevel(response, object.Properties.Tag[x])
                    }
                }
            }
        }
    }
}


define_function GetObjectLevel(char response[], char tag[]) {
    remove_string(response, "tag", 1)

    object.Level.Actual = atoi(response)
    UpdateObjectLevel(object)

    if (object.Properties.IsInitialized) {
        return
    }

    SendObjectMessage(vdvCommObject,
                        BuildObjectMessage(OBJECT_INIT_DONE_MESSAGE_HEADER,
                                            object.Properties.Id,
                                            ''))

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                "'mExtronDMPLevel => Object Initialization Complete: ID-', itoa(object.Properties.Id)")
    object.Properties.IsInitialized = true
}


define_function UpdateObjectLevel(_DspLevel object) {
    send_level vdvObject,
                VOL_LVL,
                NAVScaleValue((object.Level.Actual - object.MinLevel),
                                (object.MaxLevel - object.MinLevel),
                                255,
                                0)
}


define_function GetObjectLimits(char response[], char tag[]) {
    remove_string(response, "tag", 1)

    object.MaxLevel = atoi(NAVStripCharsFromRight(remove_string(response, '*', 1), 1))
    object.MinLevel = atoi(response)

    UpdateObjectLevel(object)
}


define_function GetInitialized(_DspObject object) {
    switch (object.Attribute.Id) {
        case ATTRIBUTE_ID_GAIN: {
            SendObjectMessage(vdvCommObject,
                                BuildObjectMessage(OBJECT_QUERY_MESSAGE_HEADER,
                                                    object.Id,
                                                    BuildPayload(object, '')))
        }
        case ATTRIBUTE_ID_GROUP: {
            SendObjectMessage(vdvCommObject,
                                BuildObjectMessage(OBJECT_QUERY_MESSAGE_HEADER,
                                                    object.Id,
                                                    BuildCustomPayload('L', object.Attribute.Value[1], '')))
            SendObjectMessage(vdvCommObject,
                                BuildObjectMessage(OBJECT_QUERY_MESSAGE_HEADER,
                                                    object.Id,
                                                    BuildPayload(object, '')))
        }
    }
}


define_function char[NAV_MAX_BUFFER] BuildPayload(_DspObject object, char value[]) {
    return BuildCustomPayload(object.Attribute.Id, object.Attribute.Value[1], value)
}


define_function char[NAV_MAX_BUFFER] BuildCustomPayload(char attributeId[], char attributeValue[], char value[]) {
    stack_var char payload[NAV_MAX_BUFFER]

    payload = "attributeId, format('%01d', atoi(attributeValue))"

    if (length_array(value)) {
        payload = "payload, '*', value"
    }

    switch (attributeId) {
        case ATTRIBUTE_ID_GAIN: {
            payload = "payload, 'AU'"
        }
        case ATTRIBUTE_ID_GROUP_SOFT_LIMITS:
        case ATTRIBUTE_ID_GROUP: {
            payload = "payload, 'GRPM'"
        }
    }

    return "NAV_ESC, payload, NAV_CR"
}


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


define_function RampLevel() {
    select {
        active ([vdvObject, VOL_UP]): {
            if (object.Properties.Attribute.Id == ATTRIBUTE_ID_GAIN) {
                SendObjectMessage(vdvCommObject,
                                    BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                        object.Properties.Id,
                                                        BuildPayload(object.Properties, itoa(object.Level.Actual + 10))))
                return
            }

            SendObjectMessage(vdvCommObject,
                                BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                    object.Properties.Id,
                                                    BuildPayload(object.Properties, '10+')))
        }
        active ([vdvObject, VOL_DN]): {
            if (object.Properties.Attribute.Id == ATTRIBUTE_ID_GAIN) {
                SendObjectMessage(vdvCommObject,
                                    BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                        object.Properties.Id,
                                                        BuildPayload(object.Properties, itoa(object.Level.Actual - 10))))
                return
            }

            SendObjectMessage(vdvCommObject,
                                BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                    object.Properties.Id,
                                                    BuildPayload(object.Properties, '10-')))
        }
    }
}


define_function ObjectChannelEvent(integer channel) {
    switch (channel) {
        case VOL_UP:
        case VOL_DN: {
            if (!object.Properties.IsInitialized) {
                return
            }

            NAVTimelineStart(TL_LEVEL_RAMP, levelRamp, TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
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

        NAVLog(NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_FROM, data.device, data.text))

        NAVParseSnapiMessage(data.text, message)

        switch (message.Header) {
            case 'REGISTER': {
                object.Properties.Id = GetObjectId(message.Parameter[1])

                registerReady = true

                Register(object.Properties)
            }
            case '?LABEL': {
                if (length_array(label)) {
                    NAVCommand(data.device, "'PROPERTY-LABEL,', label")
                }
            }
            case 'INIT': {
                GetInitialized(object.Properties)
            }
            case 'VOLUME': {
                if (!object.Properties.IsInitialized) {
                    break
                }

                switch (message.Parameter[1]) {
                    case 'QUARTER': {
                        SendObjectMessage(vdvCommObject,
                                            BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                object.Properties.Id,
                                                                BuildPayload(object.Properties,
                                                                            itoa(NAVQuarterPointOfRange(object.MaxLevel, object.MinLevel)))))
                    }
                    case 'HALF': {
                        SendObjectMessage(vdvCommObject,
                                            BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                object.Properties.Id,
                                                                BuildPayload(object.Properties,
                                                                            itoa(NAVHalfPointOfRange(object.MaxLevel, object.MinLevel)))))
                    }
                    case 'THREE_QUARTERS': {
                        SendObjectMessage(vdvCommObject,
                                            BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                object.Properties.Id,
                                                                BuildPayload(object.Properties,
                                                                            itoa(NAVThreeQuarterPointOfRange(object.MaxLevel, object.MinLevel)))))
                    }
                    case 'FULL': {
                        SendObjectMessage(vdvCommObject,
                                            BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                object.Properties.Id,
                                                                BuildPayload(object.Properties, itoa(object.MaxLevel))))
                    }
                    case 'INC': {
                        if (object.Level.Actual < object.MaxLevel) {
                            SendObjectMessage(vdvCommObject,
                                                BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                    object.Properties.Id,
                                                                    BuildPayload(object.Properties, itoa(object.Level.Actual + 10))))
                        }
                    }
                    case 'DEC': {
                        if (object.Level.Actual > object.MinLevel) {
                            SendObjectMessage(vdvCommObject,
                                                BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                    object.Properties.Id,
                                                                    BuildPayload(object.Properties, itoa(object.Level.Actual - 10))))
                        }
                    }
                    case 'ABS': {
                        if ((atoi(message.Parameter[2]) >= object.MinLevel) && (atoi(message.Parameter[2]) <= object.MinLevel)) {
                            SendObjectMessage(vdvCommObject,
                                                BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                    object.Properties.Id,
                                                                    BuildPayload(object.Properties, message.Parameter[2])))
                        }
                    }
                    default: {
                        stack_var sinteger level

                        level = NAVScaleValue(atoi(message.Parameter[1]), 255, (object.MinLevel - object.MinLevel), object.MinLevel)

                        if ((level >= object.MinLevel) && (level <= object.MinLevel)) {
                            SendObjectMessage(vdvCommObject,
                                                BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                                                    object.Properties.Id,
                                                                    BuildPayload(object.Properties, itoa(level))))
                        }
                    }
                }
            }
        }
    }
}


channel_event[vdvObject, 0] {
    on: {
        ObjectChannelEvent(channel.channel)
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
