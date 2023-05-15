#include <sys/mount.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

int loop() {
	while (1) {
		sleep(1);
	}
}

int main() {

    // Mount /proc
    if (mount("proc", "/proc", "proc", 0, NULL) == -1) {
        perror("Failed to mount /proc");
        loop();
    }
    // This is the child process
    setenv("LD_LIBRARY_PATH", "/usr/lib:/lib64", 1);

    // show if /lib64/ld-linux-x86-64.so.2 is exist
    if (access("/lib64/ld-linux-x86-64.so.2", F_OK) == -1) {
        perror("Failed to access /lib64/ld-linux-x86-64.so.2");
        loop();
    }

    execv("/usr/bin/julia", (char *[]) {"/usr/bin/julia", "/app/init.jl",NULL});
    // If execv() returns, there was an error invoking julia
    perror("execv");

    loop();
}