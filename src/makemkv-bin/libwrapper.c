#define _GNU_SOURCE
#include <dlfcn.h>
#include <sys/stat.h>

static void init(void) __attribute__((constructor));

static int (*orig_fchmod)(int fd, mode_t mode);

/*
 * Constructor.
 *
 * Save pointer to the original open function.
 */
static void init(void)
{
    orig_fchmod = dlsym(RTLD_NEXT, "fchmod");
}

/*
 * Wrapper for the fchmod function.
 */
int fchmod(int fd, mode_t mode)
{
    if (fd > 0) {
        // Ignore the file mode change.
        return 0;
    }
    else {
        return orig_fchmod(fd, mode);
    }
}
