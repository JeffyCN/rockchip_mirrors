#include <stdio.h>
#include <stdbool.h>
#include <unistd.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#include <string.h>
#include "common.h"
#include "install.h"

extern bool bSDBootUpdate;
int do_rk_update(const char *binary, const char *path){
    printf("start with main.\n");
    int pipefd[2];
    pipe(pipefd);

    char** args = malloc(sizeof(char*) * 6);
    args[0] = (char* )binary;
    args[1] = "Version 1.0";
    args[2] = (char*)malloc(10);
    sprintf(args[2], "%d", pipefd[1]);
    args[3] = (char*)path;
    args[4] = (char*)malloc(8);
    sprintf(args[4], "%d", (int)bSDBootUpdate);
    args[5] = NULL;

    pid_t pid = fork();
    if(pid == 0){
        close(pipefd[0]);
        execv(binary, args);
        printf("E:Can't run %s (%s)\n", binary, strerror(errno));
        fprintf(stdout, "E:Can't run %s (%s)\n", binary, strerror(errno));
        _exit(-1);
    }
    close(pipefd[1]);

    char buffer[1024];
    FILE* from_child = fdopen(pipefd[0], "r");
    while (fgets(buffer, sizeof(buffer), from_child) != NULL) {
        char* command = strtok(buffer, " \n");
        if (command == NULL) {
            continue;
        } else if (strcmp(command, "progress") == 0) {
            char* fraction_s = strtok(NULL, " \n");
            char* seconds_s = strtok(NULL, " \n");

            float fraction = strtof(fraction_s, NULL);
            int seconds = strtol(seconds_s, NULL, 10);

            ui_show_progress(fraction * (1-VERIFICATION_PROGRESS_FRACTION), seconds);
        } else if (strcmp(command, "set_progress") == 0) {
            char* fraction_s = strtok(NULL, " \n");
            float fraction = strtof(fraction_s, NULL);
            ui_set_progress(fraction);
        } else if (strcmp(command, "ui_print") == 0) {
            char* str = strtok(NULL, "\n");
            if (str) {
                printf("ui_print = %s.\n", str);
                ui_print("%s", str);
            } else {
                ui_print("\n");
            }
        } else {
            LOGE("unknown command [%s]\n", command);
        }
    }

    fclose(from_child);

    int status;
    waitpid(pid, &status, 0);
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
        LOGE("Error in %s\n(Status %d)\n", path, WEXITSTATUS(status));
        return INSTALL_ERROR;
    }
    return INSTALL_SUCCESS;
}
