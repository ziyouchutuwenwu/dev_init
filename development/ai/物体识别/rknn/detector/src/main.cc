#include "detector.h"
#include "ipc_consts.h"

int main(int argc, char* argv[]) {
    const char* socket_name = DEFAULT_SOCKET_NAME;
    if (argc > 1 && argv[1][0] != '\0') {
        socket_name = argv[1];
    }
    return run_detector(socket_name);
}
