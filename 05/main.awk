BEGIN {
    FS = ",| -> "
}

{
    if ($1 == $3) {
        min_max($2, $4)
        for (i = min; i <= max; i ++) {
            hfield[$1][i] ++
        }
    } else if ($2 == $4) {
        min_max($1, $3)
        for (i = min; i <= max; i ++) {
            hfield[i][$2] ++
        }
    } else {
        while ($1 != $3 && $2 != $4) {
            dfield[$1][$2] ++
            $1 += $1 > $3 ? -1 : 1
            $2 += $2 > $4 ? -1 : 1
        }
        dfield[$1][$2]++
    }
}

END {
    for (i in hfield) {
        for (j in hfield[i]) {
            dfield[i][j] += hfield[i][j]
            if (hfield[i][j] >= 2) {
                hoverlapping ++
            }
        }
    }
    print "2021-12-05 Part 1: " hoverlapping

    for (i in dfield) {
        for (j in dfield[i]) {
            if (dfield[i][j] >= 2) {
                doverlapping ++
            }
        }
    }
    print "2021-12-05 Part 2: " doverlapping
}

function min_max(a, b) {
    min = a <= b ? a : b
    max = a >= b ? a : b
}