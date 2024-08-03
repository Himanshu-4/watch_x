set(NAME "watch_x")
set(VERSION "1.0.1")
set(LANGUAGES "c c++ asm")
set(PROJECT 
	NAME	VERSION	LANGUAGES	)
set(END_TARGET "esp32s3")
set(TARGET 
	END_TARGET	)
set(BUILD_DIR "D:\smart_watch\watch_x\build")
set(SRC_DIR "D:\smart_watch\watch_x\src")
set(SRC_CONFIG_DIR "D:\smart_watch\watch_x\src\configs")
set(BUILD_CONFIG_DIR "D:\smart_watch\watch_x\build\configs")
set(GIT "C:\Program Files\Git\cmd")
set(CCACHE "C:\Program Files (x86)\idf-tools\tools\ccache\4.8\ccache-4.8-windows-x86_64")
set(PYTHON "C:\Program Files (x86)\idf-tools\python_env\idf5.0_py3.10_env\Scripts\python.exe")
set(IDF_PATH "D:\smart_watch\watch_x\esp-idf")
set(IDF_TOOLS "C:\Program Files (x86)\idf-tools\tools")
set(PATHS 
	BUILD_DIR	SRC_DIR	SRC_CONFIG_DIR	BUILD_CONFIG_DIR	GIT	CCACHE	PYTHON	IDF_PATH	IDF_TOOLS	)
set(FLASH "16MB")
set(FLASH_FREQ "80m")
set(FLASH_MODE "DIO")
set(PSRAM "2MB")
set(PSRAM_MODE "STR")
set(PSRAM_FREQ "120m")
set(COM_PORT "COM3")
set(FLASING 
	FLASH	FLASH_FREQ	FLASH_MODE	PSRAM	PSRAM_MODE	PSRAM_FREQ	COM_PORT	)
set(PROJECT_COMPILE_OPTIONS 
	-Wall	)
set(PROJECT_C_COMPILE_OPTIONS 
	-Wall	)
set(PROJECT_CXX_COMPILE_OPTIONS 
	-fnortti	)
set(PROJECT_ASM_COMPILE_OPTIONS 
	-O0	)
set(COMPILING 
	PROJECT_COMPILE_OPTIONS	PROJECT_C_COMPILE_OPTIONS	PROJECT_CXX_COMPILE_OPTIONS	PROJECT_ASM_COMPILE_OPTIONS	)
set(COMPONENTS 
	spi_flash	freertos	newlib	soc	driver	bt	freertos	nvs	esp_psram	esp_log	esp_rom	esp_system	esp_timer	hal	)
set(PARTITIONS 
	ota_metadata>0x20,data	ble_nvs>0x22,data	ota1>0x30,app	ota2>0x40,app	file>0x50,data	)
