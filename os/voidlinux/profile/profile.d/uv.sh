# uv python install 3.11
export UV_PYTHON_INSTALL_MIRROR="https://registry.npmmirror.com/-/binary/python-build-standalone/"

# 三方包的源
# 从第一个开始匹配
# export UV_EXTRA_INDEX_URL="https://download.pytorch.org/whl/cu124 https://download.pytorch.org/whl/cu132"

# 优先级最低
export UV_DEFAULT_INDEX="https://mirrors.aliyun.com/pypi/simple"