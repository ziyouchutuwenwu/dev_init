#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from selenium import webdriver

if __name__ == '__main__':
    chrome_options = webdriver.ChromeOptions()

    chrome_options.add_argument("headless")
    chrome_options.add_argument('UTF-8')
    chrome_options.add_argument('--proxy-server=socks5://localhost:1081')
    # browser = webdriver.Chrome(options=chrome_options, executable_path='/xxx/chromedriver')
    browser = webdriver.Chrome(options=chrome_options)
    browser.get('http://www.google.com')
    browser.quit()
