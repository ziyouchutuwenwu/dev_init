#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import json
from selenium import webdriver


def save_cookie():
    cookies = driver.get_cookies()
    with open("cookies.txt", "w") as fp:
        json.dump(cookies, fp)


def read_cookies():
    with open("cookies.txt", "r", encoding="utf-8") as f:
        list_cookies = json.loads(f.readline())

        for cookie in list_cookies:
            if "expiry" in cookie:
                del cookie["expiry"]
            driver.add_cookie(cookie)


if __name__ == "__main__":
    driver = webdriver.Chrome()
    driver.get("https://www.baidu.com")
    read_cookies()
    driver.refresh()
