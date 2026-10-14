#include "security/license_validator.h"
#include "security/switcher.h"
#include "model_license.h"
#include "utils/path_utils.h"
#include <cstdio>
#include <cstring>
#include <ctime>
#include <unistd.h>
#include <chrono>
#include <vector>

LicenseValidator& LicenseValidator::instance() {
    static LicenseValidator s_instance;
    return s_instance;
}

LicenseValidator::LicenseValidator()
    : _is_licensed(false), _last_status(-999), _running(false), _stop_flag(false) {
}

LicenseValidator::~LicenseValidator() {
    stop_monitor();
}


std::string LicenseValidator::get_device_hwid() {
#if !ENABLE_SECURITY
    return "unsecured";
#else
    std::lock_guard<std::mutex> lock(_mutex);
    if (!_cached_hwid.empty()) {
        return _cached_hwid;
    }
    char buf[128] = {0};
    int ret = get_hwid(buf, sizeof(buf));
    if (ret > 0) {
        _cached_hwid = std::string(buf);
    } else {
        _cached_hwid = "unknown_hwid";
    }
    return _cached_hwid;
#endif
}

std::string LicenseValidator::find_license_path(const std::string& user_path) {
#if !ENABLE_SECURITY
    return "";
#else
    if (!user_path.empty()) {
        std::string resolved = PathUtils::resolve_path(user_path);
        if (!resolved.empty()) return resolved;
        return user_path;
    }
    std::string resolved = PathUtils::resolve_path(LICENSE_PATH);
    if (!resolved.empty()) return resolved;
    return LICENSE_PATH;
#endif
}

bool LicenseValidator::verify_license(const std::string& custom_license_path) {
#if !ENABLE_SECURITY
    _is_licensed = true;
    return true;
#else
    if (!custom_license_path.empty()) {
        _license_path = custom_license_path;
    }
    return do_check_license(true);
#endif
}

bool LicenseValidator::do_check_license(bool print_on_change) {
#if !ENABLE_SECURITY
    _is_licensed = true;
    return true;
#else
    std::string lic_path = find_license_path(_license_path);
    std::string hwid = get_device_hwid();

    int status = LICENSE_STATUS_OK;
    if (lic_path.empty() || access(lic_path.c_str(), R_OK) != 0) {
        status = LICENSE_STATUS_IO_ERROR;
    } else {
        status = ::verify_license(lic_path.c_str(), hwid.c_str());
    }

    bool is_ok = (status == LICENSE_STATUS_OK);
    _is_licensed.store(is_ok);

    if (!print_on_change) {
        _last_status = status;
        return is_ok;
    }

    if (status == _last_status) {
        return is_ok;
    }

    if (is_ok) {
        if (_last_status != -999) {
            fprintf(stdout, "[license] 授权已恢复, ai 检测已激活 (hwid: %s)\n", hwid.c_str());
        } else {
            fprintf(stdout, "[license] 授权通过 (hwid: %s)\n", hwid.c_str());
        }
        fflush(stdout);
    } else {
        const char* reason = "证书损坏或签名无效";
        switch (status) {
            case LICENSE_STATUS_EXPIRED:
                reason = "授权已过期";
                break;
            case LICENSE_STATUS_HWID_MISMATCH:
                reason = "机器码不匹配";
                break;
            case LICENSE_STATUS_TIME_ROLLBACK:
                reason = "系统时钟早于签发时间";
                break;
            case LICENSE_STATUS_IO_ERROR:
                reason = "未找到证书文件";
                break;
            default:
                break;
        }
        fprintf(stderr, "[license] 授权未通过: %s (status=%d, hwid: %s)\n",
                reason, status, hwid.c_str());
        fprintf(stderr, "[license] ai 检测已降级: 纯推流正常, 不吐数据 (后台每 %ds 复检)\n",
                LICENSE_CHECK_INTERVAL_SEC);
        fflush(stderr);
    }

    _last_status = status;
    return is_ok;
#endif
}

void LicenseValidator::monitor_worker() {
    while (!_stop_flag.load()) {
        {
            std::unique_lock<std::mutex> lk(_cv_mutex);
            _cv.wait_for(lk, std::chrono::seconds(LICENSE_CHECK_INTERVAL_SEC), [this]() {
                return _stop_flag.load();
            });
        }
        if (_stop_flag.load()) break;

        do_check_license(true);
    }
}

void LicenseValidator::start_monitor(const std::string& custom_license_path) {
#if ENABLE_SECURITY
    std::lock_guard<std::mutex> lock(_mutex);
    if (!custom_license_path.empty()) {
        _license_path = custom_license_path;
    }
    if (_running.load()) return;
    _stop_flag = false;
    _running = true;
    _monitor_thread = std::thread(&LicenseValidator::monitor_worker, this);
#endif
}

void LicenseValidator::stop_monitor() {
#if ENABLE_SECURITY
    if (!_running.load()) return;
    _stop_flag = true;
    _cv.notify_all();
    if (_monitor_thread.joinable()) {
        _monitor_thread.join();
    }
    _running = false;
#endif
}
