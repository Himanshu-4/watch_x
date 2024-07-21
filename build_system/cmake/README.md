 
***note --> version 1.0.1***

### Cmake scripts
---
- this cmake scripts are used to compile, flash the code 
- you can have multiple applications that share some code in them 
- can have single libraries that are build with same configurations for the binary 
- have same build process if some binaries are need to be generated using different configuration 


### Build, flash and debug
---
- [Building the EASE firmware](doc/build_tools.md)
- [Debugging the EASE ](doc/debugging_logs.md)
- [custom tool for flashing](doc/flashing.md)


### Device Modules 
---
- [EEG ](doc/EEG_lib.md)
- [System](doc/system.md)
- [TDCS](doc/TDCS_lib.md)
- [BLE ](doc/Ble_module.md)
- [Main](doc/main.md)


## Licenses

This project is released under the GNU General Public License version 3 or, at your option, any later version.

It integrates the following projects:

- RTOS : **[FreeRTOS](https://freertos.org)** under the MIT license
- BLE stack : **[Bluedroid](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/bluetooth/) with the ESP-IDF SDk** 
- Toolchain : [ESP-IDF](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/)

<br>

## Credits
I’m  working alone on this project. if you find any bugs , vulnerability then please create a PR on the