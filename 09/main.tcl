#! /usr/bin/env tclsh

set inputFile [open {input.txt} r]
while { [gets $inputFile line] >= 0 } {
    lappend input $line
}
close $inputFile

proc item { input y x } {
    string index [ lindex $input $y ] $x
}

proc northNeighbor { input y x } { expr {
    $y > 0 ?
    [ string index [ lindex $input [ expr { $y - 1 } ] ] $x ] :
    -1
} }

proc eastNeighbor { input y x } { expr {
    $x < [ string length [ lindex $input $y ] ] - 1 ?
    [ string index [ lindex $input $y ] [ expr { $x + 1 } ] ] :
    -1
} }

proc southNeighbor { input y x } { expr {
    $y < [ llength $input ] - 1 ?
    [ string index [ lindex $input [ expr { $y + 1 } ] ] $x ] :
    -1
} }

proc westNeighbor { input y x } { expr {
    $x > 0 ?
    [ string index [ lindex $input $y ] [ expr { $x - 1 } ] ] :
    -1
} }

proc extractPoint { input point } {
    item $input [ lindex $point 0 ] [ lindex $point 1 ]
}

set numberOfLowestPoints 0
for { set i 0 } { $i < [ llength $input ] } { incr i } {
    for { set j 0 } { $j < [ string length [lindex $input $i ] ] } { incr j } {
        set character [ item $input $i $j ]
        set northLarger [ expr { [ northNeighbor $input $i $j ] > -1 ? [ northNeighbor $input $i $j ] > $character : 1 } ]
        set eastLarger [ expr { [ eastNeighbor $input $i $j ] > -1 ? [ eastNeighbor $input $i $j ] > $character : 1 } ]
        set southLarger [ expr { [ southNeighbor $input $i $j ] > -1 ? [ southNeighbor $input $i $j ] > $character : 1 } ]
        set westLarger [ expr { [ westNeighbor $input $i $j ] > -1 ? [ westNeighbor $input $i $j ] > $character : 1 } ]
        if { $northLarger && $eastLarger && $southLarger && $westLarger } then {
            set numberOfLowestPoints [ expr { $numberOfLowestPoints + $character + 1 } ]
            lappend lowestPoints "$i $j"
        }
    }
}
puts "2021-12-09 Part 1: $numberOfLowestPoints"

set basinSizes {}
while { [ llength $lowestPoints ] } {
    set pointsInBasin {}
    set lowestPoint [ lindex $lowestPoints 0 ]
    set lowestPoints [ lreplace $lowestPoints 0 0 ]
    if { [ expr { [ extractPoint $input $lowestPoint ] == 9 } ] } continue
    lappend pointsToConsider $lowestPoint
    while { [ llength $pointsToConsider ] } {
        set pointToConsider [ lindex $pointsToConsider 0 ]
        set pointsToConsider [ lreplace $pointsToConsider 0 0 ]
        if { [ expr { [ extractPoint $input $pointToConsider ] == 9 } ] } continue
        lappend pointsInBasin $pointToConsider
        set input [
            lreplace $input \
            [ lindex $pointToConsider 0 ] \
            [ lindex $pointToConsider 0 ] \
            [ string replace [ lindex $input [ lindex $pointToConsider 0 ] ] [ lindex $pointToConsider 1 ] [ lindex $pointToConsider 1 ] 9 ]
        ]
        set north [ expr {
            [ lindex $pointToConsider 0 ] > 0 ?
            "[ expr { [ lindex $pointToConsider 0 ] - 1 } ] [ lindex $pointToConsider 1 ]" :
            { }
        } ]
        set east [ expr {
            [ lindex $pointToConsider 1 ] < [ string length [ lindex $input [ lindex $pointToConsider 0 ] ] ] - 1 ?
            "[ lindex $pointToConsider 0 ] [ expr { [ lindex $pointToConsider 1 ] + 1 } ]" :
            { }
        } ]
        set south [ expr {
            [ lindex $pointToConsider 0 ] < [ llength $input ] - 1 ?
            "[ expr { [ lindex $pointToConsider 0 ] + 1 } ] [ lindex $pointToConsider 1 ]" :
            { }
        } ]
        set west [ expr {
            [ lindex $pointToConsider 1 ] > 0 ?
            "[ lindex $pointToConsider 0 ] [ expr { [ lindex $pointToConsider 1 ] - 1 } ]" :
            { }
        } ]
        if { $north != { } } then { lappend pointsToConsider $north }
        if { $east != { } } then { lappend pointsToConsider $east }
        if { $south != { } } then { lappend pointsToConsider $south }
        if { $west != { } } then { lappend pointsToConsider $west }
    }
    lappend basinSizes [ llength $pointsInBasin ]
}

set basinProduct 1
foreach x [ lrange [ lsort -integer -decreasing $basinSizes ] 0 2 ] {
    set basinProduct [ expr { $basinProduct * $x } ]
}
puts "2021-12-09 Part 2: $basinProduct"