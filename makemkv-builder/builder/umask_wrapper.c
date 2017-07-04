#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

static void init(void) __attribute__((constructor));

static int (*orig_open)(const char *path, int flags, mode_t mode);

/*
 * Constructor.
 *
 * Save pointer to the original open function.
 */
static void init(void) {
    orig_open = dlsym(RTLD_NEXT, "open");
}

/*
 * Wrapper for the open function.
 *
 * If we are opening an MKV file, override the mode.
 */
int open(const char *path, int flags, mode_t mode) {
    char *dot = strrchr(path, '.');
    if (dot && strcmp(dot, ".mkv") == 0) {
        return orig_open(path, flags, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
    }
    else {
        return orig_open(path, flags, mode);
    }
}
