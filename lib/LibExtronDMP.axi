PROGRAM_NAME='LibExtronDMP'

(***********************************************************)
#include 'NAVFoundation.Core.axi'

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


#IF_NOT_DEFINED __LIB_EXTRONDMP__
#DEFINE __LIB_EXTRONDMP__ 'LibExtronDMP'

#include 'NAVFoundation.InterModuleApi.axi'


DEFINE_CONSTANT

constant integer MAX_OBJECT_ATTRIBUTE_VALUES = 10

constant char ATTRIBUTE_ID_GAIN[] = 'G'
constant char ATTRIBUTE_ID_MUTE[] = 'M'
constant char ATTRIBUTE_ID_GROUP[] = 'D'
constant char ATTRIBUTE_ID_GROUP_SOFT_LIMITS[] = 'L'

constant char ATTRIBUTE_RESPONSE_HEADER[] = 'Ds'
constant char ATTRIBUTE_RESPONSE_HEADER_GROUP[] = 'Grpm'
constant char ATTRIBUTE_RESPONSE_HEADER_GROUP_SOFT_LIMITS[] = 'GrpmL'

constant sinteger DSP_LEVEL_MAX_LEVEL = 2168
constant sinteger DSP_LEVEL_MIN_LEVEL = 1048


DEFINE_TYPE

struct _DspAttribute {
    char Id[NAV_MAX_CHARS]
    char Value[MAX_OBJECT_ATTRIBUTE_VALUES][NAV_MAX_CHARS]
}

struct _DspObject {
    _ModuleObject Api
    _DspAttribute Attribute
}


struct _DspLevel {
    _DspObject Properties
    _NAVStateSignedInteger Level
    sinteger MaxLevel
    sinteger MinLevel
}


struct _DspState {
    _DspObject Properties
    _NAVStateInteger State
}


define_function integer GetStringArrayLength(char array[][]) {
    stack_var integer x
    stack_var integer max

    max = max_length_array(array)

    for (x = max; x >= 1; x--) {
        if (array[x] == '') {
            continue
        }

        return x
    }

    return max
}


define_function ObjectTagInit(_DspObject object) {
    switch (upper_string(object.Attribute.Id)) {
        case ATTRIBUTE_ID_GAIN:
        case ATTRIBUTE_ID_MUTE: {
            if (length_array(object.Attribute.Value[1]) == 1) {
                // For single digit values, we need to set two tags
                // One with the value as is and the other with a leading zero
                // This is because certain firmware versions require the leading zero
                object.Api.Tag[1] = "ATTRIBUTE_RESPONSE_HEADER, object.Attribute.Id, format('%01d', atoi(object.Attribute.Value[1])), '*'"
                object.Api.Tag[2] = "ATTRIBUTE_RESPONSE_HEADER, object.Attribute.Id, format('%02d', atoi(object.Attribute.Value[1])), '*'"
            }
            else {
                object.Api.Tag[1] = "ATTRIBUTE_RESPONSE_HEADER, object.Attribute.Id, format('%01d', atoi(object.Attribute.Value[1])), '*'"
            }
        }
        case ATTRIBUTE_ID_GROUP: {
            if (length_array(object.Attribute.Value[1]) == 1) {
                // For single digit values, we need to set two tags
                // One with the value as is and the other with a leading zero
                // This is because certain firmware versions require the leading zero
                object.Api.Tag[1] = "ATTRIBUTE_RESPONSE_HEADER_GROUP, object.Attribute.Id, format('%01d', atoi(object.Attribute.Value[1])), '*'"
                object.Api.Tag[2] = "ATTRIBUTE_RESPONSE_HEADER_GROUP, object.Attribute.Id, format('%02d', atoi(object.Attribute.Value[1])), '*'"
                object.Api.Tag[3] = "ATTRIBUTE_RESPONSE_HEADER_GROUP_SOFT_LIMITS, format('%01d', atoi(object.Attribute.Value[1])), '*'"
                object.Api.Tag[4] = "ATTRIBUTE_RESPONSE_HEADER_GROUP_SOFT_LIMITS, format('%02d', atoi(object.Attribute.Value[1])), '*'"
            }
            else {
                object.Api.Tag[1] = "ATTRIBUTE_RESPONSE_HEADER_GROUP, object.Attribute.Id, format('%01d', atoi(object.Attribute.Value[1])), '*'"
                object.Api.Tag[2] = "ATTRIBUTE_RESPONSE_HEADER_GROUP_SOFT_LIMITS, format('%01d', atoi(object.Attribute.Value[1])), '*'"
            }
        }
    }

    set_length_array(object.Api.Tag, GetStringArrayLength(object.Api.Tag))
}


define_function DspLevelInit(_DspLevel object) {
    NAVInterModuleApiInit(object.Properties.Api)
    object.MaxLevel = DSP_LEVEL_MAX_LEVEL
    object.MinLevel = DSP_LEVEL_MIN_LEVEL
}


define_function DspStateInit(_DspState object) {
    NAVInterModuleApiInit(object.Properties.Api)
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
        case ATTRIBUTE_ID_GAIN:
        case ATTRIBUTE_ID_MUTE: {
            payload = "payload, 'AU'"
        }
        case ATTRIBUTE_ID_GROUP_SOFT_LIMITS:
        case ATTRIBUTE_ID_GROUP: {
            payload = "payload, 'GRPM'"
        }
    }

    return "NAV_ESC, payload, NAV_CR"
}


define_function integer ObjectIsCrosspointState(_DspObject object) {
    return NAVStartsWith(object.Attribute.Value[1], '2') && object.Attribute.Id == ATTRIBUTE_ID_MUTE
}


#END_IF // __LIB_EXTRONDMP__
