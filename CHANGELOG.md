# Changelog

## [1.3.3](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/compare/v1.3.2...v1.3.3) (2024-09-30)

### 🐛 Bug Fixes

-   fixbug with archiving ([22904cf](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/22904cf4e0c4b3153d3c22ec3f21eed3d83b6e6a))

## [1.3.2](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/compare/v1.3.1...v1.3.2) (2024-09-30)

### 🐛 Bug Fixes

-   fix symlink and archiving bugs for scoop ([05c7514](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/05c7514fdbf6005c7d09f56e6e5227848aaa346a))

## [1.3.1](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/compare/v1.3.0...v1.3.1) (2024-09-30)

### 🐛 Bug Fixes

-   send strings out of module to prevent retriggering incoming ([1c4f132](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/1c4f1328eb3872e025ae38de6daf64b762e4d277))

## [1.3.0](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/compare/v1.2.3...v1.3.0) (2024-09-29)

### 🌟 Features

-   add better logging to registrations ([b33fffc](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/b33fffce64efe8060d68e4ab080b8495d86e15a2))
-   add debug log for soft limits in level ([34dc328](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/34dc3288ad839b48643a48feab23cea4a68621c0))
-   add socket connection reset on change of ip address ([e5d7fb6](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/e5d7fb6ee732f8ee8f500b6dd2c4cf8a52ae8413))
-   add support for receiving string levels update to show dB levels ([483efde](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/483efde9742c975c0d8dd92c679774b669247d0a))
-   implement inter-module-api ([c2ceba0](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/c2ceba02cb8db092b57cdd2ade8e0b9f8aa15708))

### 🐛 Bug Fixes

-   break out of double loop correctly ([22b27b5](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/22b27b5e9a1ec414a169ce074e1ab80aa092f8b4))
-   ensure device ip address and password are free from trailing ([a0f9db4](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/a0f9db42e1de1e1234fca0307c50f718fba0a9e5))
-   reverse state for crosspoint mutes ([ceb2b61](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/ceb2b61c9ebc2464c0a9d12af42e77de76e48e86))
-   use constant string literal for software limits header ([289277f](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/289277ff73b2b5ca54d08c5b6c840efaa17ea1ea))
-   **preset:** use function that actually send the data ([a8c57dc](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/a8c57dcdf4e4dd5f60d02d71689bcc48dc74437e))
-   use string literal for delimiter ([ecffcaa](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/ecffcaaecc132d33d28b505ea3ea6ed4f1dba634))

### 📖 Documentation

-   update readme in installation and usage ([5e1a646](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/5e1a6464375c96416013ffcc1f4968574cb6783f))

### 💅 Style

-   remove extra line break ([e4a93d8](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/e4a93d8987dbd78f5186dcbe09e4b3bdf95928c7))

### ✨ Refactor

-   ensure ready and initializing variables are initialized to ([64fd832](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/64fd8326ddb55f8f01bf210670c3777f9805e828))
-   fix spelling error in debug log ([5235639](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/52356396299c28d044de53cfa2a3e22d1c074c50))
-   remove redundant code ([a2a6890](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/a2a68907c16243175222feebd8011cb7b572dcfd))
-   use NAVSendLevelArray function ([85a0fa7](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/85a0fa78ca8d99185a8975d95e7ce400868d32da))

### 🚀 Performance

-   set size of object array once known ([9602e71](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/9602e71213c76bd4e97830c75385abfb46a33543))

### 🤖 CI

-   update releaserc.json ([a6a5d72](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/a6a5d72f01a4bbae91b638982378d4ce498bae2e))
-   update semantic release step in workflow ([1b47806](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/1b478065599465cb3c6c289bce72af15e01a16f3))

## [1.2.3](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/compare/v1.2.2...v1.2.3) (2024-03-09)

### ✨ Refactor

-   **semantic-release:** dont add axis to release assets ([3831f57](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/3831f57355791b837eb35c24c903abf14ddda17b))

## [1.2.2](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/compare/v1.2.1...v1.2.2) (2024-03-09)

### 🐛 Bug Fixes

-   use git head for sha in dispatch payload ([397b088](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/397b088527b78374467b9afa7ddea2509e3bb7b9))

## [1.2.1](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/compare/v1.2.0...v1.2.1) (2024-03-08)

### 🐛 Bug Fixes

-   fix json formatting in dispatcher ([ed8827d](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/ed8827da381880f6f7883a22e72088d688c45cd5))

## [1.2.0](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/compare/v1.1.1...v1.2.0) (2024-03-08)

### 🌟 Features

-   add dispatch step to workflow to trigger scoop excavator ([e207709](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/e207709bd42507297dae101c96b63ac735b3d0e9))

### ✨ Refactor

-   **semantic-release:** add branches input ([87bf047](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/87bf0473bd42ffd759c80565aa93ca6a68b503a3))
-   **semantic-release:** use full length sha for commit ([57f7c60](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/57f7c60ccd9f61358383110e981e0d49ba0503d4))
-   **semantic-release:** use specific commit for action ([6c6407f](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/6c6407fc94594e26286dd95f74ecdc51ab60eb25))

## [1.1.1](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/compare/v1.1.0...v1.1.1) (2024-03-08)

### 🐛 Bug Fixes

-   fix type cast warning ([5a477e6](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/5a477e63d57641ea4c2e4a93cadf86e1c9a13ca1))

### ✨ Refactor

-   remove unused code ([5b2aeaf](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/5b2aeafc8a89f4973bafaad736fb3be2bff50165))

### 🤖 CI

-   remove axi files from archive as not needed in deployment ([46c8e72](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/46c8e72cbad154886b4c1df6cdca67f0e4f0c3de))

## [1.1.0](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/compare/v1.0.1...v1.1.0) (2024-03-06)

### 🌟 Features

-   log socket errors to error log ([281cfbf](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/281cfbfbf7f8a3be05bcf329098121ecb348de9c))

### 🤖 CI

-   update ci workflow for semantic-release ([9e226fd](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/9e226fd3e90562fa04d21c335a354d66a55a026e))

## [1.0.1](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/compare/v1.0.0...v1.0.1) (2024-03-05)

### 🐛 Bug Fixes

-   fix path so assets upload to release ([a3de133](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/a3de133b2830e4f82295969f3cb19b9afa5c9213))

## 1.0.0 (2024-03-04)

### 🌟 Features

-   add \_DspAttribute type ([b6c7ffc](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/b6c7ffc4bfa28c6ca17bcac984c80a783eaf21a0))
-   add LibExtronDMP ([7246e54](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/7246e54be5eba8e3c3116e530f20abb59bce2cb8))
-   add ObjectTagInit function ([d6d6ea8](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/d6d6ea861c3ba47e8d2d278d562b82ab11593b30))
-   add StateUI module ([67453ed](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/67453edf9c577f255556429244d5027da0d5cb43))

### 🐛 Bug Fixes

-   check ready for init ([3c8e547](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/3c8e54778baa9ea8b3462190f7779bf7172b211a))
-   correct constant name ([a3179b7](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/a3179b7a54dc90e063db8f48fbbea0b5291c9cb7))
-   determine object index in data event ([b7519e6](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/b7519e684b4715f75e71973d52ba2b99f366abda))
-   remove include of Core lib ([8dacccb](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/8dacccb28f10cc64f6d1cf6a28d3f92fd49101c0))

### 💅 Style

-   add spacing ([b8271fc](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/b8271fce51251d793cf2bd24f6fc93d48bb2e97e))
-   add spacing ([0001fbd](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/0001fbdac534486a593f232251f6d664529a1285))
-   add spacing ([ca63b36](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/ca63b363bd75dec2b9e65cf5286486302f1f9e8f))
-   add spacing ([94c52fc](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/94c52fc0b79269cc4f2cdb1470c04e30eba80ae3))
-   fix whitespacing and convert all tabs to spaces ([53a62f7](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/53a62f7a2851196bae8549353ab42943503c1378))
-   general cleanup of indentation and spacing ([fc84413](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/fc8441313e7d70a69ec30b495dfb46c64cacaa1e))
-   remove extra new line ([25b636d](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/25b636de8c412d6a270e36e3cc9e0ba73e96adf5))

### ✨ Refactor

-   add some constants ([f3f1357](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/f3f1357ebc41accd39734e318abc580d8eedc665))
-   add some constants and helper functions ([4356669](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/435666964bca638a7d02ceb7d46a4f8978687d22))
-   decrease heartbeat to 20s ([cda91e2](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/cda91e2d76c93ee7990049e789a14ce41842787a))
-   ensure attribute id is upper case ([c90d6bf](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/c90d6bf6a1e04edefecce3e8282d8f90cbed0ebf))
-   implement device priority queue ([b3706a3](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/b3706a3cce9fb5a4daff878febd7105eb555ed56))
-   implement NAVStringGather functionality ([1b3ce9c](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/1b3ce9cd9bb2b0ddde9cbb4a41e4914eb164dfdf))
-   include LibExtronDMP ([a11bb1c](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/a11bb1cc874b8d3ef164ecf116fa0c3afa9d3e1b))
-   include LibExtronDMP ([6108ca1](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/6108ca1752ba23cb9c7f5269323a14650a8cdbee))
-   increase max objects tags to 10 ([c2eb5d6](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/c2eb5d69d17afa90ae00617d6b476962bdc6e937))
-   major refactoring of Level module ([8dc412f](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/8dc412fb742676091eb1d666d962f7e1eeddb58b))
-   make better use of message parsing functions ([808433b](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/808433be3d058f9a4b6b8ab6afb4a0947452035e))
-   move guard clause into function to avoid nesting ([9da6626](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/9da66266f33792ae4378de0b2f2aa2c54f64f406))
-   move heartbeat into function ([b364472](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/b364472d0f58a134871dd7bae11956a8286ec866))
-   move initial string receive processing into a function ([5e08ff0](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/5e08ff0999d95d8fc7b20cded4d6c9bb9c95ebe9))
-   move object response ok into function ([75961d0](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/75961d0c35bd56c823ed825226bd6a11227dcbba))
-   move some function into LibExtronDMP ([9dec768](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/9dec7686c1a68b6e85fc483c6e8bee959c971149))
-   move some functions into LibExtronDMP ([27a48bd](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/27a48bd85217a6c49e3c9804935b150f6db1d6ec))
-   move variable initialization closer to use ([76b7014](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/76b7014ca4d230676c7b2f0bff676ceceefd82b6))
-   never nest where possible ([e460204](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/e4602042605680d99e18fc4b44df5c1dc8c41539))
-   pad preset with leading zero ([41266fb](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/41266fb907397ac4b99415bc4552265dfeee1537))
-   refactor code base to utilize foundation library ([6fc099a](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/6fc099a6e9e1ecccaa03e87632361eaf9f9e6862))
-   refactor modules ([#18](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/issues/18)) ([cd45007](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/cd450074b004252ad827bd053e354c68d3d6af95))
-   remove hungarian notation ([007836d](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/007836dba466f4e893d25a00d4570cf97bc50dc6))
-   remove length of delimiter rather than magic number ([805aff2](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/805aff24e94a9f559887a195e3dbc07b14d0f596))
-   remove level functionality from state modules ([efd7d36](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/efd7d367f1fcf6c93deec925433cb4d55f01f5f3))
-   remove redundant code ([013f113](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/013f1134d257ce526a6cfc26af15db3511fa9d1b))
-   remove unused constants ([14500ba](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/14500ba7463f8b1f9658872464f3c01fe8f5deb8))
-   remove username property ([d4162fe](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/d4162fe2fe07362eec10119f70c85aa0b0b2f950))
-   rename ipCheck to socketCheck ([891270b](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/891270bc9d86f02b2685c8c11fc165a624dd3c30))
-   replace vdvControl with vdvCommObject ([c52bc06](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/c52bc06994717c4c3f35da3b90a85f230ddea4a9))
-   replace vdvControl with vdvObject ([7ea55a0](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/7ea55a0af8392f5d8bcbf0de8cf82e0e84de2430))
-   update Preset module to work with LibExtronDMP and Foundation ([d2d9ead](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/d2d9ead1596860fe21c4a01f39252c24fdf8fb61))
-   update socket variables names ([38017db](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/38017db284d7ad76e15c9961fe5d67724657f2cb))
-   update State module to work with LibExtronDMP and Foundation ([6a2c241](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/6a2c2417bd90769e42370144c2b5e78b28a626d2))
-   use \_DspObject type ([cc01169](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/cc0116992e5da0b9d1457a9865c6715a555a2673))
-   use \_NAVCredential for password ([acd6f38](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/acd6f380675f6dd8b28102dce44f5a9196f74423))
-   use \_NAVModule built in members ([530d62d](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/530d62d74c0454ae8de122d9658be491dceb0e4a))
-   use more conventional not equal to operator ([b5d3ddd](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/b5d3ddd3320b99970ebb48ee6acbfa8267d612d7))
-   use NAVCommand instead of send_command ([b46b971](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/b46b97158c621fe16e1f84b7cfcbab0644bea906))
-   use NAVSplitString to parse object tags ([7dfaef5](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/7dfaef5bd8059f7e3bff91cef23cb6756768b30f))
-   use Snapi parsing functions and callback ([210abff](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/210abff1c6efee046a06818514773d443f19a7ed))
-   use TimelineUtils functions ([54896fb](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/54896fb2087895873a4651a55aeef8dd7c813dc9))
-   use TimelineUtils functions ([1604bce](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/1604bce45c1caecb8915aea85dafd3372638f2c1))

### 🚀 Performance

-   explicitly set tag array size after initialization ([b079ebc](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/b079ebcf6c8d882196969fc7316921e62ab5b2cb))

### 🛠️ Build

-   add build script ([61ec69b](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/61ec69bee0cb700b0211ca454d33eea22897f47d))
-   use project version of genlinx ([c4d16fe](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/c4d16fe289a27bd001c37a1b61a1a3d08176ace5))

### 🤖 CI

-   clear out before checking out ([b7be8b3](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/b7be8b3953da4fcac8b7d25e0e690503d3d35246))
-   disable build ([844dff6](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/844dff690ff46de480a6de6110fd87a51696c10d))
-   dont persist credentials ([a4a25fd](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/a4a25fd6b7931cd3934827870fd07876a3ad71bc))
-   force clean ([a61c4c8](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/a61c4c8705dc811c4b4dfd35841e778038e3a8e2))
-   remove clean ([f9b0403](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/f9b0403ea15e818d1306c49ac67d19731440cbcc))
-   run on any self-hosted windows ([d6cee8f](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/d6cee8ffa9cd3f33214aecb3afaef773d6e05bf3))
-   update checkout to v3 ([8d2b76a](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/8d2b76a51882d196f12bf2c2d044448eed05d06e))
-   update clean step ([3f60109](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/3f60109244108d463c417c4237faad930835c8a5))
-   use checkout@v4 ([6467b4c](https://github.com/Norgate-AV/NAVDatabase.Amx.ExtronDMP/commit/6467b4cb06bbe9d06ca03613e995ddc81587e122))
