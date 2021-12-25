#! /usr/bin/env pwsh

Using Namespace System.Collections.Generic
Using Namespace System.IO
Using Namespace System.Linq
Using Namespace System.Text

[List[Char[]]] $cucumbersList = [List[Char[]]]::new()
[File]::ReadAllLines('input.txt') `
| ForEach-Object {
    $cucumbersList.Add($PSItem.ToCharArray())
}
[Char[][]] $global:cucumbers = $cucumbersList.ToArray()

Function Out-Cucumbers {
    [CmdletBinding()]
    Param ()
    [StringBuilder] $builder = [StringBuilder]::new([Environment]::NewLine)
    $global:cucumbers `
    | ForEach-Object {
        [Void] $builder.AppendLine([String]::new($PSItem))
    }
    $builder.ToString() | Out-Default
}

Function Move-Cucumbers {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)] [Func[Int32, Int32, Char]] $GetCucumber,
        [Parameter(Mandatory)] [Action[Int32, Int32, Char]] $SetCucumber,
        [Parameter(Mandatory)] [Char] $CucumberChar,
        [Parameter(Mandatory)] [Int32] $LengthY,
        [Parameter(Mandatory)] [Int32] $LengthX
    )
    [List[ValueTuple[Int32, Int32, Char]]] $actions = [List[ValueTuple[Int32, Int32, Char]]]::new()
    ForEach ($y in [Enumerable]::Range(0, $LengthY)) {
        ForEach ($x in [Enumerable]::Range(0, $LengthX)) {
            [Boolean] $cucumberInSpot = $GetCucumber.Invoke($y, $x) -eq $CucumberChar
            [Boolean] $nextSpotFree = $GetCucumber.Invoke($y, ($x + 1) % $LengthX) -eq '.'
            If ($cucumberInSpot -and $nextSpotFree) {
                $actions.Add([ValueTuple[Int32, Int32, Char]]::new($y, $x, '.'))
                $actions.Add([ValueTuple[Int32, Int32, Char]]::new($y, ($x + 1) % $LengthX, $CucumberChar))
            }
        }
    }
    $actions.ForEach({
        Param ([ValueTuple[Int32, Int32, Char]] $action)
        $SetCucumber.Invoke($action.Item1, $action.Item2, $action.Item3)
    })
    Out-Cucumbers
    $actions.Count
}

[Int32] $cucumbersMoved = 0
[Int32] $steps = 0
Do {
    $steps++
    $cucumbersMoved = Move-Cucumbers `
        -GetCucumber ([Func[Int32, Int32, Char]] {
            Param ([Int32] $Y, [Int32] $X)
            $global:cucumbers[$Y][$X]
        }) `
        -SetCucumber ([Action[Int32, Int32, Char]] {
            Param ([Int32] $Y, [Int32] $X, [Char] $C)
            $global:cucumbers[$Y][$X] = $C
        }) `
        -CucumberChar '>' `
        -LengthY $global:cucumbers.Length `
        -LengthX $global:cucumbers[0].Length

    $cucumbersMoved += Move-Cucumbers `
        -GetCucumber ([Func[Int32, Int32, Char]] {
            Param ([Int32] $Y, [Int32] $X)
            $global:cucumbers[$X][$Y]
        }) `
        -SetCucumber ([Action[Int32, Int32, Char]] {
            Param ([Int32] $Y, [Int32] $X, [Char] $C)
            $global:cucumbers[$X][$Y] = $C
        }) `
        -CucumberChar 'v' `
        -LengthY $global:cucumbers[0].Length `
        -LengthX $global:cucumbers.Length
} While ($cucumbersMoved -gt 0)

"2021-12-25: $steps"