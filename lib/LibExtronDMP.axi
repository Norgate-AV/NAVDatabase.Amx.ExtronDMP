PROGRAM_NAME='LibExtronDMP'

(***********************************************************)

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


#IF_NOT_DEFINED __LIB_EXTRONDMP__
#DEFINE __LIB_EXTRONDMP__ 'LibExtronDMP'


DEFINE_CONSTANT

constant integer MAX_OBJECTS	= 100
constant integer MAX_OBJECT_TAGS	= 10

constant integer MAX_OBJECT_ATTRIBUTE_VALUES = 10

constant char ATTRIBUTE_ID_GAIN[] = 'G'
constant char ATTRIBUTE_ID_MUTE[] = 'M'
constant char ATTRIBUTE_ID_GROUP[] = 'D'
constant char ATTRIBUTE_ID_GROUP_SOFT_LIMITS[] = 'L'

constant char ATTRIBUTE_RESPONSE_HEADER[] = 'Ds'
constant char ATTRIBUTE_RESPONSE_HEADER_GROUP[] = 'Grpm'
constant char ATTRIBUTE_RESPONSE_HEADER_GROUP_SOFT_LIMITS[] = "ATTRIBUTE_RESPONSE_HEADER_GROUP, ATTRIBUTE_ID_GROUP_SOFT_LIMITS"

constant sinteger DSP_LEVEL_MAX_LEVEL = 2168
constant sinteger DSP_LEVEL_MIN_LEVEL = 1048

constant char OBJECT_COMMAND_MESSAGE_HEADER[] = 'COMMAND_MSG'
constant char OBJECT_RESPONSE_MESSAGE_HEADER[] = 'RESPONSE_MSG'
constant char OBJECT_QUERY_MESSAGE_HEADER[] = 'POLL_MSG'
constant char OBJECT_INIT_MESSAGE_HEADER[] = 'INIT'
constant char OBJECT_INIT_DONE_MESSAGE_HEADER[] = 'INIT_DONE'
constant char OBJECT_REGISTRATION_MESSAGE_HEADER[] = 'REGISTER'


DEFINE_TYPE

struct _DspAttribute {
    char Id[NAV_MAX_CHARS]
    char Value[MAX_OBJECT_ATTRIBUTE_VALUES][NAV_MAX_CHARS]
}

struct _DspObject {
    integer Id
    integer IsInitialized
    integer IsRegistered
    _DspAttribute Attribute
    char Tag[MAX_OBJECT_TAGS][NAV_MAX_CHARS]
}


struct _DspLevel {
    _DspObject Properties
    _NAVStateSignedInteger Level
    sinteger MaxLevel
    sinteger MinLevel
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
            object.Tag[1] = "ATTRIBUTE_RESPONSE_HEADER, object.Attribute.Id, format('%01d', atoi(object.Attribute.Value[1])), '*'"
            object.Tag[2] = "ATTRIBUTE_RESPONSE_HEADER, object.Attribute.Id, format('%02d', atoi(object.Attribute.Value[1])), '*'"
        }
        case ATTRIBUTE_ID_GROUP: {
            object.Tag[1] = "ATTRIBUTE_RESPONSE_HEADER_GROUP, object.Attribute.Id, format('%01d', atoi(object.Attribute.Value[1])), '*'"
            object.Tag[2] = "ATTRIBUTE_RESPONSE_HEADER_GROUP, object.Attribute.Id, format('%02d', atoi(object.Attribute.Value[1])), '*'"
            object.Tag[3] = "ATTRIBUTE_RESPONSE_HEADER_GROUP_SOFT_LIMITS, format('%01d', atoi(object.Attribute.Value[1])), '*'"
            object.Tag[4] = "ATTRIBUTE_RESPONSE_HEADER_GROUP_SOFT_LIMITS, format('%02d', atoi(object.Attribute.Value[1])), '*'"
        }
    }

    set_length_array(object.Tag, GetStringArrayLength(object.Tag))
}


define_function DspLevelInit(_DspLevel level) {
    level.Properties.IsInitialized = false
    level.Properties.IsRegistered = false
    level.MaxLevel = DSP_LEVEL_MAX_LEVEL
    level.MinLevel = DSP_LEVEL_MIN_LEVEL
}


define_function integer GetObjectId(char buffer[]) {
    if (!NAVContains(buffer, '|')) {
        return atoi(NAVGetStringBetween(buffer, '<', '>'))
    }

    return atoi(NAVGetStringBetween(buffer, '<', '|'))
}


define_function char[NAV_MAX_BUFFER] GetObjectMessage(char buffer[]) {
    return NAVGetStringBetween(buffer, '|', '>')
}


define_function char[NAV_MAX_BUFFER] GetObjectFullMessage(char buffer[]) {
    return NAVGetStringBetween(buffer, '<', '>')
}


define_function char[NAV_MAX_BUFFER] BuildObjectMessage(char header[], integer id, char payload[]) {
    if (!length_array(payload)) {
        return "header, '-<', itoa(id), '>'"
    }

    return "header, '-<', itoa(id), '|', payload, '>'"
}


define_function char[NAV_MAX_BUFFER] BuildObjectResponseMessage(char data[]) {
    return "OBJECT_RESPONSE_MESSAGE_HEADER, '<', data, '>'"
}


define_function SendObjectMessage(dev device, char payload[]) {
    NAVLog(NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_TO, device, payload))
    NAVCommand(device, "payload")
}


define_function char[NAV_MAX_BUFFER] GetObjectTagList(_DspObject object) {
    return NAVArrayJoinString(object.Tag, ',')
}


#END_IF // __LIB_EXTRONDMP__
