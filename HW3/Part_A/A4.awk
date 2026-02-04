BEGIN { FS="," }
NR > 1 {
    matrix[$NF, $1]++
    classes[$NF] = 1
    col1_vals[$1] = 1
}
END {
    for (c in classes) {
        for (v in col1_vals) {
            if (matrix[c, v] > 0) {
                print c, v, matrix[c, v]
            }
        }
    }
}