#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

static void init(void) __attribute__((constructor));

static int (*orig_open)(const char *path, int flags, mode_t mode);
static int (*orig_mkdir)(const char *pathname, mode_t mode);

/*
 * Constructor.
 *
 * Save pointer to the original open function.
 */
static void init(void)
{
    orig_open = dlsym(RTLD_NEXT, "open");
    orig_mkdir = dlsym(RTLD_NEXT, "mkdir");
}

/*
 * Wrapper for the open function.
 *
 * If we are opening an MKV file, override the mode.
 */
int open(const char *path, int flags, mode_t mode)
{
    return orig_open(path, flags, mode | S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
}

/*
 * Wrapper for the mkdir function.
 */
int mkdir(const char *pathname, mode_t mode)
{
    return orig_mkdir(pathname, mode | S_IRWXU | S_IRWXG | S_IRWXO);
}
