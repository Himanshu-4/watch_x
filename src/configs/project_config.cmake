set(PROJECT_NAME "watch_x")
set(PROJECT_VERSION "1.0.1")
set(PROJECT_LANGUAGES "c c++ asm")
set(PROJECT_SDK_VERSION "5.1")
set(PROJECT 
	NAME	VERSION	LANGUAGES	SDK_VERSION	)
set(TARGET_BOARD "esp32s3")
set(TARGET 
	BOARD	)
set(PATH_BUILD_DIR "D:/smart_watch/watch_x/build")
set(PATH_SRC_DIR "D:/smart_watch/watch_x/src")
set(PATH_SRC_CONFIG_DIR "D:/smart_watch/watch_x/src/configs")
set(PATH_GIT "C:/Program Files/Git/cmd")
set(PATH_CCACHE "C:/Program Files (x86)/idf-tools/tools/ccache/4.6.2/ccache-4.6.2-windows-x86_64")
set(PATH_PYTHON "C:/Program Files (x86)/idf-tools/python_env/idf5.0_py3.10_env/Scripts")
set(PATH_IDF_PATH "D:/smart_watch/watch_x/esp-idf")
set(PATH_IDF_TOOLS "C:/Program Files (x86)/idf-tools/tools")
set(PATH_SDK_PATH "D:/smart_watch/watch_x/esp-idf/components")
set(PATH 
	BUILD_DIR	SRC_DIR	SRC_CONFIG_DIR	GIT	CCACHE	PYTHON	IDF_PATH	IDF_TOOLS	SDK_PATH	)
set(FLASH_FLASH "16MB")
set(FLASH_FLASH_FREQ "80m")
set(FLASH_FLASH_MODE "DIO")
set(FLASH_PSRAM "2MB")
set(FLASH_PSRAM_MODE "STR")
set(FLASH_PSRAM_FREQ "120m")
set(FLASH_COM_PORT "COM3")
set(FLASH_BAUD_RATE "115200")
set(FLASH 
	FLASH	FLASH_FREQ	FLASH_MODE	PSRAM	PSRAM_MODE	PSRAM_FREQ	COM_PORT	BAUD_RATE	)
set(COMPILER_DEFINATION 
	-Wall	)
set(COMPILER_C_OPTIONS 
	-Wall	-Werror	)
set(COMPILER_CXX_OPTIONS 
	-Wall	-Werror	-fnortti	)
set(COMPILER_ASM_OPTIONS 
	-O0	)
set(COMPILER 
	DEFINATION	C_OPTIONS	CXX_OPTIONS	ASM_OPTIONS	)
set(COMPONENTS 
	app_update	bootloader_support	bt	console	cxx	driver	efuse	esp_adc	esp_app_format	esp_common	esp_event	esp_gdbstub	esp_hw_support	esp_partition	esp_phy	esp_pm	esp_psram	esp_ringbuf	esp_rom	esp_system	esp_timer	esp_wifi	esp-tls	espcoredump	fatfs	freertos	hal	heap	log	lwip	mbedtls	newlib	nvs_flash	partition_table	pthread	riscv	soc	spi_flash	ulp	usb	wear_levelling	wifi_provisioning	wpa_supplicant	xtensa	)
set(PARTITIONS 
	ota_metadata>0x20,data	ble_nvs>0x22,data	ota1>0x30,app	ota2>0x40,app	file>0x50,data	)
