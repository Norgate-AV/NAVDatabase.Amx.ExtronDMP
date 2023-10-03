MODULE_NAME='mExtronDMPState'	(
                                    dev vdvObject,
                                    dev vdvCommObject
                                )

(***********************************************************)
#DEFINE USING_NAV_MODULE_BASE_PROPERTY_EVENT_CALLBACK
#DEFINE USING_NAV_STRING_GATHER_CALLBACK
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

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile _DspState object

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

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPState => Object Registering: ID-', itoa(object.Id)")

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
                        "'mExtronDMPState => Object Registration Requested: ID-', itoa(object.Properties.Id)")

            Register(object.Properties)
        }
        active (NAVStartsWith(args.Data, OBJECT_INIT_MESSAGE_HEADER)): {
            object.Properties.IsInitialized = false
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                        "'mExtronDMPState => Object Initialization Requested: ID-', itoa(object.Properties.Id)")

            GetInitialized(object.Properties)
        }
        active (NAVStartsWith(args.Data, OBJECT_RESPONSE_MESSAGE_HEADER)): {
            stack_var char response[NAV_MAX_BUFFER]
            stack_var integer x

            response = GetObjectFullMessage(args.Data)

            for (x = 1; x <= length_array(object.Properties.Tag); x++) {
                if (!NAVContains(response, object.Properties.Tag[x])) {
                    continue
                }

                GetObjectState(response, object.Properties.Tag[x])
            }
        }
    }
}


define_function GetInitialized(_DspObject object) {
    SendObjectMessage(vdvCommObject,
                                BuildObjectMessage(OBJECT_QUERY_MESSAGE_HEADER,
                                                    object.Id,
                                                    BuildPayload(object, '')))
}


define_function GetObjectState(char response[], char tag[]) {
    remove_string(response, "tag", 1)

    if (ObjectIsCrosspointState(object.Properties)) {
        object.State.Actual = !atoi(response)
    }
    else {
        object.State.Actual = atoi(response)
    }

    if (object.Properties.IsInitialized) {
        return
    }

    SendObjectMessage(vdvCommObject,
                        BuildObjectMessage(OBJECT_INIT_DONE_MESSAGE_HEADER,
                                            object.Properties.Id,
                                            ''))

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                "'mExtronDMPState => Object Initialization Complete: ID-', itoa(object.Properties.Id)")
    object.Properties.IsInitialized = true
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
    }
}


define_function SetObjectState(_DspState object, integer value) {
    SendObjectMessage(vdvCommObject,
                        BuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                            object.Properties.Id,
                                            BuildPayload(object.Properties, itoa(value))))
}


define_function ObjectChannelEvent(integer channel) {
    switch (channel) {
        case VOL_MUTE: {
            SetObjectState(object, !object.State.Actual)
        }
    }
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {
    create_buffer vdvCommObject, module.RxBuffer.Data
    DspStateInit(object)
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
            case 'INIT': {
                GetInitialized(object.Properties)
            }
            case 'MUTE': {
                switch (message.Parameter[1]) {
                    case 'ON': {
                        SetObjectState(object, true)
                    }
                    case 'OFF': {
                        SetObjectState(object, false)
                    }
                    case 'TOGGLE': {
                        SetObjectState(object, !object.State.Actual)
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

    }
}


timeline_event[TL_NAV_FEEDBACK] {
    [vdvObject, VOL_MUTE_FB]	= (object.State.Actual)
}


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
