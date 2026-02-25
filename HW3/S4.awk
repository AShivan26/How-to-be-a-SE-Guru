BEGIN { FS = "," }
NR == 1 { next }
$NF !~ /^[1-5]$/ { n++; print NR }
END { print n + 0 > "/dev/stderr" }