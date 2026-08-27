pon() {
    export HTTP_PROXY=http://127.0.0.1:8118
    export HTTPS_PROXY=http://127.0.0.1:8118
    export ALL_PROXY=socks5://127.0.0.1:1080
    export NO_PROXY=localhost,127.0.0.1,10.0.2.1

    export http_proxy=$HTTP_PROXY
    export https_proxy=$HTTPS_PROXY
    export all_proxy=$ALL_PROXY
    export no_proxy=$NO_PROXY
}

poff() {
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset ALL_PROXY
    unset NO_PROXY

    unset http_proxy
    unset https_proxy
    unset all_proxy
    unset no_proxy
}
