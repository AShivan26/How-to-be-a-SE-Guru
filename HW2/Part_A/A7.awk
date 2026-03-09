BEGIN { FS=","; srand() }
NR > 1 {
    if (NR - 1 <= 20) {
        reservoir[NR - 1] = $0
    } else {
        r = int(rand() * (NR - 1)) + 1
        if (r <= 20) {
            reservoir[r] = $0
        }
    }
}
END {
    for (i in reservoir) {
        print reservoir[i]
    }
}