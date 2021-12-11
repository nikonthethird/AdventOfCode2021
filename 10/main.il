.assembly extern mscorlib { auto }
.assembly AdventOfCode { }

.field static class [mscorlib]System.Collections.Generic.Dictionary`2<char, char> brackets
.field static class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64> corruptBracketScores
.field static class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64> unfinishedBracketScores

.method static void Main() {
    .entrypoint
    .locals init (
        class [mscorlib]System.IO.StreamReader lineReader,
        class [mscorlib]System.Collections.Generic.Stack`1<char> bracketStack,
        valuetype [mscorlib]System.Collections.Generic.Stack`1/Enumerator<char> bracketStackEnumerator,
        class [mscorlib]System.Collections.Generic.List`1<int64> unfinishedBracketFinalScores,
        string currentLine,
        char currentCharacter,
        int64 corruptBracketFinalScore
    )

    // Initialize all static dictionaries for brackets.
    call void InitializeBrackets()
    call void InitializeCorruptBracketScores()
    call void InitializeUnfinishedBracketScores()

    // Open a reader for the input lines.
    ldstr "input.txt"
    call [mscorlib]System.IO.StreamReader [mscorlib]System.IO.File::OpenText(string)
    stloc lineReader

    // Initialize the stack to handle open brackets.
    newobj instance void class [mscorlib]System.Collections.Generic.Stack`1<char>::.ctor()
    stloc bracketStack

    // Initialize the list that contains the final scores for unfinished bracket lines.
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int64>::.ctor()
    stloc unfinishedBracketFinalScores

    // Read a new line from the input.
    AdvanceToNextLine:
    ldloc lineReader
    call instance string [mscorlib]System.IO.StreamReader::ReadLine()
    stloc currentLine

    // If no more input line is available, print the final scores and exit.
    ldloc currentLine
    brfalse PrintFinalScores

    // If no mor input line characters are available, the line is unfinished.
    // Calculate the unfinished bracket scores on the stack.
    AdvanceToNextCharacter:
    ldloc currentLine
    call instance int32 string::get_Length()
    brfalse CalculateUnfinishedBracketScore

    // Read a new character from the front of the line.
    ldloc currentLine
    ldc.i4 0
    call instance char string::get_Chars(int32)
    stloc currentCharacter

    // Remove the character from the line itself.
    ldloc currentLine
    ldc.i4 1
    call instance string string::Substring(int32)
    stloc currentLine

    // Check if the current character is an opening bracket.
    ldsfld class [mscorlib]System.Collections.Generic.Dictionary`2<char, char> brackets
    ldloc currentCharacter
    call instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<char, char>::ContainsKey(!0)
    brfalse CheckForCorruptBracket

    // If the current character is an opening bracket, push it on the bracket stack.
    ldloc bracketStack
    ldsfld class [mscorlib]System.Collections.Generic.Dictionary`2<char, char> brackets
    ldloc currentCharacter
    call instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<char, char>::get_Item(!0)
    call instance void class [mscorlib]System.Collections.Generic.Stack`1<char>::Push(!0)
    br AdvanceToNextCharacter

    // If the current character is a closing bracket, check if it matches the top of the bracket stack.
    CheckForCorruptBracket:
    ldloc bracketStack
    call instance !0 class [mscorlib]System.Collections.Generic.Stack`1<char>::Pop()
    ldloc currentCharacter
    ceq
    brtrue AdvanceToNextCharacter

    // The current closing bracket does not match the top of the bracket stack.
    // The current line is corrupt, increase the corrupt bracket final score.
    ldloc corruptBracketFinalScore
    ldsfld class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64> corruptBracketScores
    ldloc currentCharacter
    call instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::get_Item(!0)
    add
    stloc corruptBracketFinalScore
    ldloc bracketStack
    call instance void class [mscorlib]System.Collections.Generic.Stack`1<char>::Clear()
    br AdvanceToNextLine

    // Calculate the unfinished bracket score. Create the enumerator and start at zero.
    // Also load the final scores list onto the stack so it will be in the right spot to add the total.
    CalculateUnfinishedBracketScore:
    ldloc bracketStack
    call instance valuetype [mscorlib]System.Collections.Generic.Stack`1/Enumerator<!0> class [mscorlib]System.Collections.Generic.Stack`1<char>::GetEnumerator()
    stloc bracketStackEnumerator
    ldloc unfinishedBracketFinalScores
    ldc.i8 0

    // Fetch the next item from the bracket stack enumerator.
    FetchNextItemFromBracketStackEnumerator:
    ldloca bracketStackEnumerator
    call instance bool valuetype [mscorlib]System.Collections.Generic.Stack`1/Enumerator<char>::MoveNext()
    brfalse UpdateUnfinishedBracketScore

    // Update the unfinished bracket score value on the stack.
    ldc.i8 5
    mul
    ldsfld class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64> unfinishedBracketScores
    ldloca bracketStackEnumerator
    call instance !0 valuetype [mscorlib]System.Collections.Generic.Stack`1/Enumerator<char>::get_Current()
    call instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::get_Item(!0)
    add
    br FetchNextItemFromBracketStackEnumerator

    // Store the calculated unfinished bracket score into the total.
    UpdateUnfinishedBracketScore:
    call instance void class [mscorlib]System.Collections.Generic.List`1<int64>::Add(!0)
    ldloc bracketStack
    call instance void class [mscorlib]System.Collections.Generic.Stack`1<char>::Clear()
    br AdvanceToNextLine

    // First, print the corrupt bracket score.
    PrintFinalScores:
    ldstr "2021-12-10 Part 1: {0}"
    ldloc corruptBracketFinalScore
    box int64
    call string string::Format(string, object)
    call void [mscorlib]System.Console::WriteLine(string)

    // Then print the unfinished bracket score.
    ldstr "2021-12-10 Part 2: {0}"
    ldloc unfinishedBracketFinalScores
    dup
    call instance void class [mscorlib]System.Collections.Generic.List`1<int64>::Sort()
    dup
    call instance int32 class [mscorlib]System.Collections.Generic.List`1<int64>::get_Count()
    ldc.i4 2
    div
    call instance !0 class [mscorlib]System.Collections.Generic.List`1<int64>::get_Item(int32)
    box int64
    call string string::Format(string, object)
    call void [mscorlib]System.Console::WriteLine(string)
    ret
}

.method static void InitializeBrackets() {
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, char>::.ctor()
    dup
    ldc.i4 60 // <
    ldc.i4 62 // >
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, char>::Add(!0, !1)
    dup
    ldc.i4 123 // {
    ldc.i4 125 // }
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, char>::Add(!0, !1)
    dup
    ldc.i4 91 // [
    ldc.i4 93 // ]
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, char>::Add(!0, !1)
    dup
    ldc.i4 40 // (
    ldc.i4 41 // )
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, char>::Add(!0, !1)
    stsfld class [mscorlib]System.Collections.Generic.Dictionary`2<char, char> brackets
    ret
}

.method static void InitializeCorruptBracketScores() {
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::.ctor()
    dup
    ldc.i4 62 // >
    ldc.i8 25137
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::Add(!0, !1)
    dup
    ldc.i4 125 // }
    ldc.i8 1197
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::Add(!0, !1)
    dup
    ldc.i4 93 // ]
    ldc.i8 57
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::Add(!0, !1)
    dup
    ldc.i4 41 // )
    ldc.i8 3
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::Add(!0, !1)
    stsfld class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64> corruptBracketScores
    ret
}

.method static void InitializeUnfinishedBracketScores() {
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::.ctor()
    dup
    ldc.i4 62 // >
    ldc.i8 4
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::Add(!0, !1)
    dup
    ldc.i4 125 // }
    ldc.i8 3
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::Add(!0, !1)
    dup
    ldc.i4 93 // ]
    ldc.i8 2
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::Add(!0, !1)
    dup
    ldc.i4 41 // )
    ldc.i8 1
    call instance void class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64>::Add(!0, !1)
    stsfld class [mscorlib]System.Collections.Generic.Dictionary`2<char, int64> unfinishedBracketScores
    ret
}