# /etc/chromium-browser/default
# Default settings for chromium-browser. This file is sourced by /bin/sh from
# /usr/bin/chromium-browser

# Keep the leading space before flags!
# REF: https://stackoverflow.com/a/1168084/1938889
CHROMIUM_FLAGS=$(
  cat <<'EOF'
 --incognito
EOF
)
