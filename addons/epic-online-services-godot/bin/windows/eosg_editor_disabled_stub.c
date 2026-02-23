#include <stddef.h>

typedef void (*GDExtensionInterfaceFunctionPtr)(void);
typedef GDExtensionInterfaceFunctionPtr (*GDExtensionInterfaceGetProcAddress)(const char *p_function_name);
typedef void *GDExtensionClassLibraryPtr;
typedef unsigned char GDExtensionBool;

typedef enum {
	GDEXTENSION_INITIALIZATION_CORE = 0,
	GDEXTENSION_INITIALIZATION_SERVERS = 1,
	GDEXTENSION_INITIALIZATION_SCENE = 2,
	GDEXTENSION_INITIALIZATION_EDITOR = 3,
	GDEXTENSION_MAX_INITIALIZATION_LEVEL = 4,
} GDExtensionInitializationLevel;

typedef void (*GDExtensionInitializeCallback)(void *p_userdata, GDExtensionInitializationLevel p_level);
typedef void (*GDExtensionDeinitializeCallback)(void *p_userdata, GDExtensionInitializationLevel p_level);

typedef struct {
	GDExtensionInitializationLevel minimum_initialization_level;
	void *userdata;
	GDExtensionInitializeCallback initialize;
	GDExtensionDeinitializeCallback deinitialize;
} GDExtensionInitialization;

static void eosg_editor_disabled_initialize(void *p_userdata, GDExtensionInitializationLevel p_level) {
	(void)p_userdata;
	(void)p_level;
}

static void eosg_editor_disabled_deinitialize(void *p_userdata, GDExtensionInitializationLevel p_level) {
	(void)p_userdata;
	(void)p_level;
}

#ifdef _WIN32
#define EOSG_EXPORT __declspec(dllexport)
#else
#define EOSG_EXPORT __attribute__((visibility("default")))
#endif

EOSG_EXPORT GDExtensionBool eosg_library_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	(void)p_get_proc_address;
	(void)p_library;
	if (r_initialization == NULL) {
		return 0;
	}
	r_initialization->minimum_initialization_level = GDEXTENSION_INITIALIZATION_CORE;
	r_initialization->userdata = NULL;
	r_initialization->initialize = eosg_editor_disabled_initialize;
	r_initialization->deinitialize = eosg_editor_disabled_deinitialize;
	return 1;
}
