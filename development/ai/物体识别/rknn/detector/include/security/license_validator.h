#ifndef LICENSE_VALIDATOR_H
#define LICENSE_VALIDATOR_H

#include <string>
#include <mutex>
#include <atomic>
#include <thread>
#include <condition_variable>

#define LICENSE_PATH "license.key"
#define LICENSE_CHECK_INTERVAL_SEC 60
#define RUNNING_TIME_DURATION_FILE "/etc/rk_config"

class LicenseValidator {
public:
    static LicenseValidator& instance();

    std::string get_device_hwid();
    bool verify_license(const std::string& custom_license_path = "");
    std::string find_license_path(const std::string& user_path = "");

    void set_config_path(const std::string& path);
    std::string get_config_path();

    bool is_licensed() const { return _is_licensed.load(); }
    void start_monitor(const std::string& custom_license_path = "");
    void stop_monitor();

private:
    LicenseValidator();
    ~LicenseValidator();

    LicenseValidator(const LicenseValidator&) = delete;
    LicenseValidator& operator=(const LicenseValidator&) = delete;

    void monitor_worker();
    bool do_check_license(bool print_on_change = true);

    std::mutex _mutex;
    std::string _cached_hwid;
    std::string _license_path;
    std::string _config_path;
    std::atomic<bool> _is_licensed{false};
    int _last_status{-999};

    std::thread _monitor_thread;
    std::atomic<bool> _running{false};
    std::atomic<bool> _stop_flag{false};
    std::condition_variable _cv;
    std::mutex _cv_mutex;
};

#endif
