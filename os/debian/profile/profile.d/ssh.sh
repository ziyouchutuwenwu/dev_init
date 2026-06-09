ssh() {
    set +x

    command ssh "$@"
    local exit_status=$?
    reset
    return $exit_status
}