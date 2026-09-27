#include "security/license_validator.h"
#include "security/switcher.h"
#include "model_license.h"
#include "utils/path_utils.h"
#include <cstdio>
#include <cstring>
#include <ctime>
#include <unistd.h>
#include <chrono>

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

void LicenseValidator::set_config_path(const std::string& path) {
    std::lock_guard<std::mutex> lock(_mutex);
    _config_path = path;
}

std::string LicenseValidator::get_config_path() {
    std::lock_guard<std::mutex> lock(_mutex);
    if (!_config_path.empty()) {
        return _config_path;
    }
    return RUNNING_TIME_DURATION_FILE;
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
    std::string cfg_path = get_config_path();

    int status = LICENSE_STATUS_OK;
    int64_t issue_time = 0;
    int64_t expire_time = 0;
    char bound_hwid[128] = {0};

    if (lic_path.empty() || access(lic_path.c_str(), R_OK) != 0) {
        status = LICENSE_STATUS_IO_ERROR;
    } else {
        status = ::inspect_license_details(
            lic_path.c_str(),
            hwid.c_str(),
            &status,
            &issue_time,
            &expire_time,
            bound_hwid,
            sizeof(bound_hwid)
        );
    }

    int64_t total_runtime_sec = 0;
    int64_t last_active_time = 0;
    bool runtime_exhausted = false;

    if (status == LICENSE_STATUS_OK) {
        time_t now_ts = time(nullptr);
        int64_t now_sec = static_cast<int64_t>(now_ts);
        int cfg_ret = ::read_running_duration(cfg_path.c_str(), hwid.c_str(), &total_runtime_sec, &last_active_time);

        if (cfg_ret == 0) {
            if (last_active_time > 0 && now_sec < (last_active_time - 300)) {
                status = LICENSE_STATUS_TIME_ROLLBACK;
            } else if (expire_time > issue_time) {
                int64_t max_runtime = expire_time - issue_time;
                if (total_runtime_sec >= max_runtime) {
                    status = LICENSE_STATUS_EXPIRED;
                    runtime_exhausted = true;
                }
            }
        } else {
            if (access(cfg_path.c_str(), F_OK) == 0) {
                status = LICENSE_STATUS_INVALID_FORMAT;
            }
        }
    }

    if (status == LICENSE_STATUS_OK && _last_status == -999) {
        time_t now_ts = time(nullptr);
        int64_t now_sec = static_cast<int64_t>(now_ts);
        if (last_active_time <= 0 || now_sec >= (last_active_time - 300)) {
            int w_ret = ::write_running_duration(cfg_path.c_str(), hwid.c_str(), total_runtime_sec, now_sec);
            if (w_ret != 0) {
                fprintf(stderr, "[license] 写入工时文件失败 (%s, 错误码: %d)\n", cfg_path.c_str(), w_ret);
                fflush(stderr);
            }
        }
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
        time_t now_ts = time(nullptr);
        char now_buf[32] = {0};
        strftime(now_buf, sizeof(now_buf), "%Y-%m-%d %H:%M:%S", localtime(&now_ts));

        if (status == LICENSE_STATUS_EXPIRED) {
            if (runtime_exhausted) {
                fprintf(stderr, "[license] 授权未通过: 授权工作时长已耗尽 (累计运行: %lld 秒, hwid: %s)\n",
                        (long long)total_runtime_sec, hwid.c_str());
            } else {
                char expire_buf[32] = {0};
                if (expire_time > 0) {
                    time_t t = static_cast<time_t>(expire_time);
                    strftime(expire_buf, sizeof(expire_buf), "%Y-%m-%d %H:%M:%S", localtime(&t));
                }
                fprintf(stderr, "[license] 授权未通过: 授权已过期 (到期: %s, 当前: %s, hwid: %s)\n",
                        expire_buf, now_buf, hwid.c_str());
            }
        } else if (status == LICENSE_STATUS_HWID_MISMATCH) {
            fprintf(stderr, "[license] 授权未通过: 机器码不匹配 (当前 hwid: %s)\n", hwid.c_str());
        } else if (status == LICENSE_STATUS_TIME_ROLLBACK) {
            char issue_buf[32] = {0};
            if (issue_time > 0) {
                time_t t = static_cast<time_t>(issue_time);
                strftime(issue_buf, sizeof(issue_buf), "%Y-%m-%d %H:%M:%S", localtime(&t));
            }
            if (now_ts < (issue_time - 300)) {
                fprintf(stderr, "[license] 授权未通过: 系统时钟早于签发时间 (签发: %s, 当前: %s)\n",
                        issue_buf, now_buf);
            } else {
                fprintf(stderr, "[license] 授权未通过: 检测到系统时钟往前回拨异常 (当前: %s)\n", now_buf);
            }
        } else if (status == LICENSE_STATUS_IO_ERROR) {
            fprintf(stderr, "[license] 授权未通过: 未找到证书文件 (%s)\n", lic_path.c_str());
        } else {
            fprintf(stderr, "[license] 授权未通过: 证书损坏或签名无效 (status=%d)\n", status);
        }
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

        if (_is_licensed.load()) {
            std::string cfg_path = get_config_path();
            std::string hwid = get_device_hwid();
            int64_t total_sec = 0;
            int64_t last_active = 0;
            int ret = ::read_running_duration(cfg_path.c_str(), hwid.c_str(), &total_sec, &last_active);
            if (ret == 0 || access(cfg_path.c_str(), F_OK) != 0) {
                time_t now_ts = time(nullptr);
                int64_t now_sec = static_cast<int64_t>(now_ts);
                if (last_active <= 0 || now_sec >= (last_active - 300)) {
                    int w_ret = ::write_running_duration(cfg_path.c_str(), hwid.c_str(), total_sec + LICENSE_CHECK_INTERVAL_SEC, now_sec);
                    if (w_ret != 0) {
                        fprintf(stderr, "[license] 写入工时文件失败 (%s, 错误码: %d)\n", cfg_path.c_str(), w_ret);
                        fflush(stderr);
                    }
                }
            }
        }

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
