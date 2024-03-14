#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import base64
import time
from selenium import webdriver
from selenium.webdriver import ActionChains
from selenium.webdriver.common.by import By
import ddddocr
import os
from selenium.webdriver.support.select import Select
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions


def init_webdriver():
    chrome_options = webdriver.ChromeOptions()
    # chrome_options.add_argument("headless")
    chrome_options.add_argument("UTF-8")
    # browser = webdriver.Chrome(options=chrome_options, executable_path='/xxx/chromedriver')
    browser = webdriver.Chrome(options=chrome_options)
    return browser


def do_auto_work(browser):
    browser.get("https://hk.sz.gov.cn:8118/userPage/login")

    mouse = ActionChains(browser)

    msgbox = browser.find_element(By.XPATH, '//*[@id="winLoginNotice"]/div[@class="flexbox btngroup"]')
    mouse.move_to_element(msgbox).click()
    mouse.perform()

    card_type_node = browser.find_element(By.XPATH, '//select[@id="select_certificate"]')
    card_selector = Select(card_type_node)
    card_selector.select_by_index(1)

    id_card_node = browser.find_element(By.XPATH, '//input[@id="input_idCardNo"]')
    id_card_node.send_keys("111111")

    pwd_node = browser.find_element(By.XPATH, '//input[@id="input_pwd"]')
    pwd_node.send_keys("111111")
    #
    # # 隐式等待
    # browser.implicitly_wait(5)
    # img_verify_node = browser.find_element(By.XPATH, '//*[@id="img_verify"]')

    # 显式等待
    wait = WebDriverWait(browser, 30)
    img_verify_node = wait.until(expected_conditions.presence_of_element_located((By.XPATH, '//*[@id="img_verify"]')))

    bytes = base64.b64decode(img_verify_node.screenshot_as_base64)
    img_verify_ocr_result = ddddocr.DdddOcr().classification(bytes)

    input_verify_code_node = browser.find_element(By.XPATH, '//input[@id="input_verifyCode"]')
    input_verify_code_node.send_keys(img_verify_ocr_result)


if __name__ == "__main__":
    browser = init_webdriver()
    while True:
        try:
            do_auto_work(browser)
        except:
            os._exit(0)
