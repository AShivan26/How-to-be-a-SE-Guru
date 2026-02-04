BEGIN { FS="," }
NR > 1 { counts[$2]++ }
END {
    max_count = 0
    most_common = ""
    for (val in counts) {
        if (counts[val] > max_count) {
            max_count = counts[val]
            most_common = val
        }
    }
    print most_common, max_count
}