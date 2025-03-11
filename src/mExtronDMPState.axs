MODULE_NAME='mExtronDMPState'	(
                                    dev vdvObject,
                                    dev vdvCommObject
                                )

(***********************************************************)
#DEFINE USING_NAV_MODULE_BASE_CALLBACKS
#DEFINE USING_NAV_MODULE_BASE_PROPERTY_EVENT_CALLBACK
#DEFINE USING_NAV_STRING_GATHER_CALLBACK
#include 'NAVFoundation.ModuleBase.axi'
#include 'NAVFoundation.StringUtils.axi'
#include 'NAVFoundation.ErrorLogUtils.axi'
#include 'NAVFoundation.InterModuleApi.axi'
#include 'NAVFoundation.SnapiHelpers.axi'
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

volatile char registerReady
volatile char registerRequested


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

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPState => ID: ', itoa(object.Api.Id), ' Data: ', message")

    NAVInterModuleApiSendObjectMessage(vdvCommObject, message)

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mExtronDMPState => Object Registering: ID: ', itoa(object.Api.Id)")

    object.Api.IsRegistered = true
}


#IF_DEFINED USING_NAV_STRING_GATHER_CALLBACK
define_function NAVStringGatherCallback(_NAVStringGatherResult args) {
    stack_var integer id

    id = NAVInterModuleApiGetObjectId(args.Data)

    select {
        active (NAVStartsWith(args.Data, OBJECT_REGISTRATION_MESSAGE_HEADER)): {
            object.Properties.Api.Id = id

            registerRequested = true
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                        "'mExtronDMPState => Object Registration Requested: ID: ', itoa(object.Properties.Api.Id)")

            Register(object.Properties)
        }
        active (NAVStartsWith(args.Data, OBJECT_INIT_MESSAGE_HEADER)): {
            object.Properties.Api.IsInitialized = false
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                        "'mExtronDMPState => Object Initialization Requested: ID: ', itoa(object.Properties.Api.Id)")

            GetInitialized(object.Properties)
        }
        active (NAVStartsWith(args.Data, OBJECT_RESPONSE_MESSAGE_HEADER)): {
            stack_var char response[NAV_MAX_BUFFER]
            stack_var integer x

            response = NAVInterModuleApiGetObjectFullMessage(args.Data)

            for (x = 1; x <= length_array(object.Properties.Api.Tag); x++) {
                if (!NAVContains(response, object.Properties.Api.Tag[x])) {
                    continue
                }

                GetObjectState(response, object.Properties.Api.Tag[x])
            }
        }
    }
}
#END_IF


define_function GetInitialized(_DspObject object) {
    NAVInterModuleApiSendObjectMessage(vdvCommObject,
                                NAVInterModuleApiBuildObjectMessage(OBJECT_QUERY_MESSAGE_HEADER,
                                                    object.Api.Id,
                                                    BuildPayload(object, '')))
}


define_function GetObjectState(char response[], char tag[]) {
    remove_string(response, "tag", 1)

    object.State.Actual = atoi(response)

    UpdateFeedback()

    if (object.Properties.Api.IsInitialized) {
        return
    }

    NAVInterModuleApiSendObjectMessage(vdvCommObject,
                        NAVInterModuleApiBuildObjectMessage(OBJECT_INIT_DONE_MESSAGE_HEADER,
                                            object.Properties.Api.Id,
                                            ''))

    NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                "'mExtronDMPState => Object Initialization Complete: ID: ', itoa(object.Properties.Api.Id)")
    object.Properties.Api.IsInitialized = true
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
    }
}
#END_IF


define_function SetObjectState(_DspState object, integer value) {
    NAVInterModuleApiSendObjectMessage(vdvCommObject,
                        NAVInterModuleApiBuildObjectMessage(OBJECT_COMMAND_MESSAGE_HEADER,
                                            object.Properties.Api.Id,
                                            BuildPayload(object.Properties, itoa(value))))
}


define_function ObjectChannelEvent(tchannel channel) {
    switch (channel.channel) {
        case VOL_MUTE: {
            SetObjectState(object, !object.State.Actual)
        }
    }
}


define_function UpdateFeedback() {
    [vdvObject, VOL_MUTE_FB]	= (object.State.Actual)
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

        NAVParseSnapiMessage(data.text, message)

        switch (message.Header) {
            case OBJECT_REGISTRATION_MESSAGE_HEADER: {
                // object.Properties.Id = GetObjectId(message.Parameter[1])

                registerReady = true

                Register(object.Properties)
            }
            case OBJECT_INIT_MESSAGE_HEADER: {
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
        ObjectChannelEvent(channel)
    }
    off: {

    }
}


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
