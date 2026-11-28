#ifndef PATH_UTILS_H
#define PATH_UTILS_H

#include <string>
#include <unistd.h>
#include <cstring>

namespace PathUtils {

inline std::string get_executable_dir() {
    char buf[1024] = {0};
    ssize_t len = readlink("/proc/self/exe", buf, sizeof(buf) - 1);
    if (len > 0) {
        buf[len] = '\0';
        char* last_slash = strrchr(buf, '/');
        if (last_slash) {
            *last_slash = '\0';
            return std::string(buf);
        }
    }
    return "";
}

inline std::string resolve_path(const std::string& path) {
    if (path.empty()) return "";
    if (access(path.c_str(), R_OK) == 0) return path;

    std::string exe_dir = get_executable_dir();
    if (!exe_dir.empty()) {
        std::string cand = exe_dir + "/" + path;
        if (access(cand.c_str(), R_OK) == 0) return cand;
        cand = exe_dir + "/../" + path;
        if (access(cand.c_str(), R_OK) == 0) return cand;
    }
    std::string root_cand = "/" + path;
    if (access(root_cand.c_str(), R_OK) == 0) return root_cand;
    return "";
}

}

#endif
