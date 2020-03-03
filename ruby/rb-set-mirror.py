#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os

os.system(
    "gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/"
)
os.system("gem install bundle")
os.system("bundle config mirror.https://rubygems.org https://gems.ruby-china.com")
