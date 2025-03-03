if [ -d /usr/local/etc/profile.d ]; then
  for script in /usr/local/etc/profile.d/*.sh; do
    if [ -r "$script" ]; then
      source "$script"
    fi
  done
  unset script
fi