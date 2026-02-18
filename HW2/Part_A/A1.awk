BEGIN { FS="," }
$NF == " diaporthe-stem-canker" { print $0 }