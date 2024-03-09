# NAVDatabase.Amx.ExtronDMP

<!-- <div align="center">
 <img src="./" alt="logo" width="200" />
</div> -->

---

[![CI](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/actions/workflows/main.yml/badge.svg)](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/actions/workflows/main.yml)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![Commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/)
[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

AMX NetLinx module for Extron DMP 128/64/44 audio DSPs.

## Contents :book:

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

-   [Installation :zap:](#installation-zap)
-   [Usage :rocket:](#usage-rocket)
-   [Team :soccer:](#team-soccer)
-   [Contributors :sparkles:](#contributors-sparkles)
-   [LICENSE :balance_scale:](#license-balance_scale)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Installation :zap:

This module can be installed using [Scoop](https://scoop.sh/).

```powershell
scoop bucket add norgateav-amx https://github.com/Norgate-AV/scoop-norgateav-amx
scoop install navdatabase-amx-extron-dmp
```

## Usage :rocket:

```netlinx
DEFINE_DEVICE

// The real device
dvExtronDMP                     = 5001:1:0          // Serial/RS232 Connection

// or
// dvExtronDMP                  = 0:4:0             // IP/Socket Connection

// Virtual Devices
vdvExtronDMP_Main_Comm          = 33201:1:0         // The interface between the Extron DMP and the control system

vdvExtronDMP_Level_Program      = 33202:1:0         // Program Level
vdvExtronDMP_Level_Program_Comm = 33203:1:0         //
vdvExtronDMP_State_Program      = 33204:1:0         // Program Mute
vdvExtronDMP_State_Program_Comm = 33205:1:0         //

vdvExtronDMP_Preset             = 33206:1:0         // Preset
vdvExtronDMP_Preset_Comm        = 33207:1:0         //

// User Interface
dvTP_Main                       = 10001:1:0         // Main UI
dvTP_ExtronDMP_Fader_Program    = 10001:2:0         // Fader Program UI


DEFINE_CONSTANT

constant dev DVA_EXTRON_DMP_LEVEL_OBJECTS[] =   {
                                                    vdvExtronDMP_Level_Program,
                                                }

constant char EXTRON_DMP_ATTRIBUTE_FOR_LEVEL_OBJECT[][1]    =   {
                                                                    "D",    // Group
                                                                }

constant char EXTRON_DMP_INDEX_FOR_LEVEL_OBJECT[][2]    =   {
                                                                "1",        // Group Number
                                                            }

constant dev DVA_EXTRON_DMP_STATE_OBJECTS[] =   {
                                                    vdvExtronDMP_State_Program,
                                                }

constant char EXTRON_DMP_ATTRIBUTE_FOR_STATE_OBJECT[][1]    =   {
                                                                    "M",    // Direct I/O
                                                                }

constant char EXTRON_DMP_INDEX_FOR_STATE_OBJECT[][5]    =   {
                                                                "1",        // I/O Number
                                                            }

constant dev DVA_EXTRON_DMP_COMM_OBJECTS[]  =  {
                                                    vdvExtronDMP_Level_Program_Comm,
                                                    vdvExtronDMP_State_Program_Comm,
                                                    vdvExtronDMP_Preset_Comm
                                                }

constant dev DVA_TP_MAIN[]  =   {
                                    dvTP_Main
                                }

constant dev DVA_TP_EXTRON_DMP_FADER_PROGRAM[]  =   {
                                                        dvTP_ExtronDMP_Fader_Program
                                                    }


define_module 'mExtronDMPComm' ExtronDMPMainComm(vdvExtronDMP_Main_Comm, DVA_EXTRON_DMP_COMM_OBJECTS, dvExtronDMP)

define_module 'mExtronDMPLevel' ExtronDMPLevelProgram(vdvExtronDMP_Level_Program, vdvExtronDMP_Level_Program_Comm)
define_module 'mExtronDMPState' ExtronDMPStateProgram(vdvExtronDMP_State_Program, vdvExtronDMP_State_Program_Comm)

define_module 'mExtronDMPPreset' ExtronDMPPreset(vdvExtronDMP_Preset, vdvExtronDMP_Preset_Comm)

define_module 'mExtronDMPFaderUIArray' ExtronDMPFaderProgramUI(DVA_TP_EXTRON_DMP_FADER_PROGRAM, vdvExtronDMP_Level_Program, vdvExtronDMP_State_Program)


DEFINE_EVENT

data_event[vdvExtronDMP_Main_Comm] {
    online: {
        // If using IP/Socket Connection
        // send_command data.device, "'PROPERTY-IP_ADDRESS,', '192.168.1.21'"

        // Newer firmware versions require a password when connecting via IP
        // The default password is the serial number of the device
        // send_command data.device, "'PROPERTY-PASSWORD,', 'A2A3A4A'"
    }
}


channel_event[vdvExtronDMP_Main_Comm, DEVICE_COMMUNICATING] {
    on: {
        amx_log(AMX_INFO, 'Extron DMP Device is Communicating')
    }
    off: {
        amx_log(AMX_WARNING, 'Extron DMP Device is Not Communicating')
    }
}


channel_event[vdvExtronDMP_Main_Comm, DATA_INITIALIZED] {
    on: {
        amx_log(AMX_INFO, 'Extron DMP Comm module is Fully Initialized')

        // Do other stuff here
    }
}


data_event[DVA_EXTRON_DMP_LEVEL_OBJECTS] {
    online: {
        stack_var integer object
        stack_var char attribute[1]
        stack_var char index[5]

        object = get_last(DVA_EXTRON_DMP_LEVEL_OBJECTS)
        attribute = EXTRON_DMP_ATTRIBUTE_FOR_LEVEL_OBJECT[object]
        index = EXTRON_DMP_INDEX_FOR_LEVEL_OBJECT[object]

        send_command data.device, "'PROPERTY-ATTRIBUTE,', attribute"
        send_command data.device, "'PROPERTY-INDEX,', index"
        send_command data.device, "'REGISTER'"
    }
}


data_event[DVA_EXTRON_DMP_STATE_OBJECTS] {
    online: {
        stack_var integer object
        stack_var char attribute[1]
        stack_var char index[5]

        object = get_last(DVA_EXTRON_DMP_STATE_OBJECTS)
        attribute = EXTRON_DMP_ATTRIBUTE_FOR_STATE_OBJECT[object]
        index = EXTRON_DMP_INDEX_FOR_STATE_OBJECT[object]

        send_command data.device, "'PROPERTY-ATTRIBUTE,', attribute"
        send_command data.device, "'PROPERTY-INDEX,', index"
        send_command data.device, "'REGISTER'"
    }
}


// Trigger Presets
button_event[DVA_TP_MAIN, 1]
button_event[DVA_TP_MAIN, 2]
button_event[DVA_TP_MAIN, 3] {
    push: {
        pulse[vdvExtronDMP_Preset, button.input.channel]
        // Triggers preset 1, 2, or 3

        // or
        send_command vdvExtronDMP_Preset, "'PRESET-', itoa(button.input.channel)"
    }
}

```

## Team :soccer:

This project is maintained by the following person(s) and a bunch of [awesome contributors](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/graphs/contributors).

<table>
  <tr>
    <td align="center"><a href="https://github.com/damienbutt"><img src="https://avatars.githubusercontent.com/damienbutt?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Damien Butt</b></sub></a><br /></td>
  </tr>
</table>

## Contributors :sparkles:

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->

[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors-sparkles)

<!-- ALL-CONTRIBUTORS-BADGE:END -->

Thanks go to these awesome people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://allcontributors.org) specification.
Contributions of any kind are welcome!

## LICENSE :balance_scale:

[MIT](LICENSE)
