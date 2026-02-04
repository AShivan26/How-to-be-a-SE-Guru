BEGIN { FS="," }
NR > 1 { counts[$NF]++ }
END {
    entropy(counts, NR-1)
}

function entropy(arr, n,    i, p, e) {
    e = 0
    for (i in arr) {
        p = arr[i] / n
        e -= p * log(p)
    }
    print e
}