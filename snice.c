#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <unistd.h>
#include <asm-generic/errno-base.h>

int main(const int argc, char **argv) {

    if (argc < 4) {
        //for (int i = 1; i < argc; i++) {
        //    printf("%s\n", argv[i]);
        //}
        printf("Usage: snice -n priority [-p pid | command [args...]]\n");
        return EXIT_FAILURE;
    }

    if (strcmp(argv[1], "-n") != 0) {
        //for (int i = 1; i < argc; i++) {
        //    printf("%s\n", argv[i]);
        //}
        printf("Usage: snice -n priority [-p pid | command [args...]]\n");
        return EXIT_FAILURE;
    }

    char *endptr;
    const long val = strtol(argv[2], &endptr, 10);
    if (errno == ERANGE) {
        perror("strtol(priority)");
        return EXIT_FAILURE;
    }
    if (endptr == argv[2]) return EXIT_FAILURE;
    if (*endptr != '\0') return EXIT_FAILURE;
    if (val > 19 || val < -20) {
        printf("Invalid priority value\n");
        return EXIT_FAILURE;
    }

    int priority_value = (int)val;


    if (strcmp(argv[3], "-p") == 0) {
        if (argc < 5) {
            printf("Usage: snice -n priority [-p pid | command [args...]]\n");
            return EXIT_FAILURE;
        }


        char *pid_endptr;
        errno = 0;
        const long pid_val = strtol(argv[4], &pid_endptr, 10);
        if (errno == ERANGE) {
            perror("strtol(pid)");
            return EXIT_FAILURE;
        }

        if (pid_endptr == argv[4]) return EXIT_FAILURE;
        if (*pid_endptr != '\0') return EXIT_FAILURE;
        if (pid_val > INT_MAX || pid_val < 0) {
            fprintf(stderr, "Invalid PID");
            return EXIT_FAILURE;
        }

        if (setpriority(PRIO_PROCESS, (id_t)pid_val, priority_value) == -1) {
            if (errno == EPERM || errno == EACCES) {
                fprintf(stderr, "Permission denied - are you root?\n");
                return EXIT_FAILURE;
            }
            if (errno == ESRCH) {
                fprintf(stderr, "No process found with pid %ld\n", pid_val);
                return EXIT_FAILURE;
            }
            perror("setpriority");
            return EXIT_FAILURE;
        }
    } else {
        errno = 0;
        nice(priority_value);
        if (errno != 0) {
            if (errno == EPERM || errno == EACCES) {
                fprintf(stderr, "Permission denied - are you root?\n");
                return EXIT_FAILURE;
            }
            perror("nice");
            return EXIT_FAILURE;
        }

        char **args = malloc((argc - 3 + 1) * sizeof(char*));
        if (!args) {
            perror("malloc");
            return EXIT_FAILURE;
        }
        args[0] = argv[3];
        for (int i = 4; i < argc; i++) {
            args[i-4+1] = argv[i];
        }
        args[argc-3] = NULL;

        execvp(argv[3], args);
        perror("execvp");
        free(args);
        return EXIT_FAILURE;
    }
    return 0;
}