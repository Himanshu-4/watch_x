set(PROJECT_NAME "watch_x")
set(PROJECT_VERSION "1.0.1")
set(PROJECT_LANGUAGES "c c++ asm")
set(PROJECT_SDK_VERSION "5.1")
set(PROJECT 
	NAME	VERSION	LANGUAGES	SDK_VERSION	)
set(TARGET_END_TARGET "esp32s3")
set(TARGET 
	END_TARGET	)
set(PATH_BUILD_DIR "D:\\smart_watch\\watch_x\\build")
set(PATH_SRC_DIR "D:\\smart_watch\\watch_x\\src")
set(PATH_SRC_CONFIG_DIR "D:\\smart_watch\\watch_x\\src\\configs")
set(PATH_BUILD_CONFIG_DIR "D:\\smart_watch\\watch_x\\build\\configs")
set(PATH_GIT "C:\\Program Files\\Git\\cmd")
set(PATH_CCACHE "C:\\Program Files (x86)\\idf-tools\\tools\\ccache\\4.8\\ccache-4.8-windows-x86_64")
set(PATH_PYTHON "C:\\Program Files (x86)\\idf-tools\\python_env\\idf5.0_py3.10_env\\Scripts\\python.exe")
set(PATH_IDF_PATH "D:\\smart_watch\\watch_x\\esp-idf")
set(PATH_IDF_TOOLS "C:\\Program Files (x86)\\idf-tools\\tools")
set(PATH 
	BUILD_DIR	SRC_DIR	SRC_CONFIG_DIR	BUILD_CONFIG_DIR	GIT	CCACHE	PYTHON	IDF_PATH	IDF_TOOLS	)
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
set(COMPILING_PROJECT_COMPILE_OPTIONS 
	-Wall	)
set(COMPILING_PROJECT_C_COMPILE_OPTIONS 
	-Wall	-Werror	)
set(COMPILING_PROJECT_CXX_COMPILE_OPTIONS 
	-Wall	-Werror	-fnortti	)
set(COMPILING_PROJECT_ASM_COMPILE_OPTIONS 
	-O0	)
set(COMPILING 
	PROJECT_COMPILE_OPTIONS	PROJECT_C_COMPILE_OPTIONS	PROJECT_CXX_COMPILE_OPTIONS	PROJECT_ASM_COMPILE_OPTIONS	)
set(COMPONENTS 
	spi_flash	freertos	newlib	soc	driver	bt	freertos	nvs	esp_psram	esp_log	esp_rom	esp_system	esp_timer	hal	)
set(PARTITIONS 
	ota_metadata>0x20,data	ble_nvs>0x22,data	ota1>0x30,app	ota2>0x40,app	file>0x50,data	)
