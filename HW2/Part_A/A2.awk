BEGIN { FS="," }
NR > 1 { counts[$NF]++ }
END {
    for (c in counts) {
        print c, counts[c]
    }
}