BEGIN { FS="," }
NR <= 10 { print; next }
$3 != "?" { print }