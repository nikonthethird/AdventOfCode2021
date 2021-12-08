var lines = (
    from line in await File.ReadAllLinesAsync("input.txt")
    select line.Split(" | ").SelectMany((part, index) =>
        from segments in part.Split(' ') select new InputDisplay(
            Rhs: Convert.ToBoolean(index),
            Segments: ImmutableHashSet.Create(segments.ToCharArray())
        )
    ).ToArray()
).ToArray();

var count1478 = (
    from item in lines.SelectMany(line => line)
    where item.Rhs
    select Convert.ToInt32(item.Segments.Count is 2 or 3 or 4 or 7)
).Sum();
Console.WriteLine($"2021-12-08 Part 1: {count1478}");

var numbers = (
    from number in new[] {
        new[] { 'a', 'b', 'c', 'e', 'f', 'g' },
        new[] { 'c', 'f' },
        new[] { 'a', 'c', 'd', 'e', 'g' },
        new[] { 'a', 'c', 'd', 'f', 'g' },
        new[] { 'b', 'c', 'd', 'f' },
        new[] { 'a', 'b', 'd', 'f', 'g' },
        new[] { 'a', 'b', 'd', 'e', 'f', 'g' },
        new[] { 'a', 'c', 'f' },
        new[] { 'a', 'b', 'c', 'd', 'e', 'f', 'g' },
        new[] { 'a', 'b', 'c', 'd', 'f', 'g' },
    }
    select ImmutableHashSet.Create(number)
).ToArray();

var totalSum = (
    from displays in lines
    let solution = new Solution(
        displays,
        ImmutableDictionary.Create<Char, Char>(),
        numbers.MaxBy(number => number.Count)!
    )
    select SolutionToInt32(FindSolutions(solution).First())
).Sum();
Console.WriteLine($"2021-12-08 Part 2: {totalSum}");

IEnumerable<Solution> FindSolutions(Solution solution) =>
    !solution.AvailableSegments.Any() ? new[] { solution } :
    from pickedSegment in solution.AvailableSegments
    let updatedSolution = solution with {
        Permutation = solution.Permutation.Add((Char)('a' + solution.Permutation.Count), pickedSegment),
        AvailableSegments = solution.AvailableSegments.Remove(pickedSegment),
    }
    where updatedSolution.Displays.All(display =>
        !display.Segments.IsSubsetOf(updatedSolution.Permutation.Keys) ||
        numbers!.Any(number => number.SetEquals(
            from segment in display.Segments
            select updatedSolution.Permutation[segment]
        ))
    )
    from nextSolution in FindSolutions(updatedSolution)
    select nextSolution;

Int32 SolutionToInt32(Solution solution) =>
    Int32.Parse(String.Join(
        String.Empty,
        from display in solution.Displays
        where display.Rhs
        select Array.FindIndex(numbers!, number => number.SetEquals(
            from segment in display.Segments
            select solution.Permutation[segment]
        ))
    ));

readonly record struct InputDisplay(
    Boolean Rhs,
    IImmutableSet<Char> Segments
);

readonly record struct Solution(
    InputDisplay[] Displays,
    IImmutableDictionary<Char, Char> Permutation,
    IImmutableSet<Char> AvailableSegments
);