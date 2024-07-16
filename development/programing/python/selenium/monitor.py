import os
import subprocess
import shlex
import time
import psutil


chrome_pid = 0
auto_script_pid = 0


AUTO_SCRIPT_FILE_NAME = "auto_script.py"


def is_auto_script_process_alive():
    name = AUTO_SCRIPT_FILE_NAME
    for proc in psutil.process_iter():
        if len(proc.cmdline()) == 2:
            if proc.cmdline()[-1].find(name) != -1:
                return proc.pid, True
    return -1, False


def is_pid_alive(pid):
    result = False
    if pid == 0 or pid == -1:
        return result
    try:
        os.kill(pid, 0)
        result = True
    except:
        result = False
    return result


def kill_pid(pid):
    if pid == 0 or pid == -1:
        return
    try:
        os.kill(pid, 9)
    except:
        return


def start_chrome():
    # command_line = "chromium --remote-debugging-port=9222"
    command_line = "chromium --headless --remote-debugging-port=9222"
    args = shlex.split(command_line)
    proc = subprocess.Popen(args)
    return proc.pid


def start_auto_script():
    command_line = "python %s" % AUTO_SCRIPT_FILE_NAME
    args = shlex.split(command_line)
    proc = subprocess.Popen(args)
    return proc.pid


def check():
    global chrome_pid
    global auto_script_pid

    auto_script_pid, is_auto_script_proc_alive = is_auto_script_process_alive()
    if is_pid_alive(chrome_pid) == False or is_auto_script_proc_alive == False:
        kill_pid(chrome_pid)
        kill_pid(auto_script_pid)
        time.sleep(1)

        chrome_pid = start_chrome()
        time.sleep(2)
        auto_script_pid = start_auto_script()


def loop_monitor():
    while True:
        check()
        time.sleep(5)


if __name__ == "__main__":
    loop_monitor()
