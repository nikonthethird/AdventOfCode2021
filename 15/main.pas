program AdventOfCode;
{$mode ObjFPC}

uses SysUtils, Classes;

type
    PLocation = ^Location;
    Location = record X, Y: SmallInt; end;
    CavernMap = array of array of SmallInt;

var
    inputMap: CavernMap;
    largeInputMap: CavernMap;

function ReadInput(): CavernMap;
    var
        inputFile: TextFile;
        inputMap: CavernMap = nil;
        inputLine: String;
        xPos, yPos : SmallInt;
    begin
        AssignFile(inputFile, 'input.txt');
        Reset(inputFile);
        yPos := 0;
        while not Eof(inputFile) do begin
            ReadLn(inputFile, inputLine);
            if inputMap = Nil then
                SetLength(inputMap, Length(inputLine), Length(inputLine));
            for xPos := 0 to Length(inputLine) - 1 do
                inputMap[yPos, xPos] := SmallInt(inputLine[xPos + 1]) - SmallInt('0');
            yPos := yPos + 1;
        end;
        CloseFile(inputFile);
        Result := inputMap;
    end;

function ResizeInput(inputMap: CavernMap): CavernMap;
    var
        biggerMap: CavernMap;
        xFac, yFac, xPos, yPos, n: SmallInt;
    begin
        SetLength(biggerMap, Length(inputMap) * 5, Length(inputMap) * 5);
        for yFac := 0 to 4 do
            for xFac := 0 to 4 do
                for yPos := Low(inputMap) to High(inputMap) do
                    for xPos := Low(inputMap) to High(inputMap) do begin
                        n := inputMap[yPos, xPos] + yFac + xFac;
                        if n > 9 then n := n - 9;
                        biggerMap[Length(inputMap) * yFac + yPos, Length(inputMap) * xFac + xPos] := n;
                    end;
        Result := biggerMap;
    end;

function ComputeDistances(cavernMap: CavernMap): CavernMap;
    label 1;
    var
        distanceMap: CavernMap;
        locations: TList;
        location, minLocation: PLocation;
        xPos, yPos, xD, yD, newDistance: SmallInt;
    begin
        locations := TList.Create();
        SetLength(distanceMap, Length(cavernMap), Length(cavernMap));
        for yPos := Low(distanceMap) to High(distanceMap) do
            for xPos := Low(distanceMap) to High(distanceMap) do begin
                New(location);
                location^.X := xPos;
                location^.Y := yPos;
                locations.Add(location);
                if (xPos = 0) and (yPos = 0) 
                then distanceMap[yPos, xPos] := 0
                else distanceMap[yPos, xPos] := MaxSmallInt;
            end;

        while locations.Count > 0 do begin
            if locations.Count mod 1000 = 0 then
                WriteLn('Remaining Locations: ', locations.Count div 1000, 'k');
            minLocation := locations.First;
            for location in locations do begin
                if distanceMap[location^.Y, location^.X] < distanceMap[minLocation^.Y, minLocation^.X]
                then minLocation := location;
            end;
            locations.Remove(minLocation);
            for yD in [0 .. 2] do
                for xD in [0 .. 2] do begin
                    if not (((yD <> 1) or (xD <> 1)) and (Abs(yD - 1) <> Abs(xD - 1))) then continue;
                    for location in locations do
                        if (location^.X = minLocation^.X - xD + 1) and (location^.Y = minLocation^.Y - yD + 1) then goto 1;
                    continue;
                    1: newDistance := distanceMap[minLocation^.Y, minLocation^.X] + cavernMap[minLocation^.Y - yD + 1, minLocation^.X - xD + 1];
                    if newDistance < distanceMap[minLocation^.Y - yD + 1, minLocation^.X - xD + 1]
                    then distanceMap[minLocation^.Y - yD + 1, minLocation^.X - xD + 1] := newDistance;
                end;
        end;

        Result := distanceMap;
    end;

begin
    inputMap := ReadInput;
    largeInputMap := ResizeInput(inputMap);

    inputMap := ComputeDistances(inputMap);
    largeInputMap := ComputeDistances(largeInputMap);

    WriteLn('2021-12-15 Part 1: ', inputMap[High(inputMap), High(inputMap)]);
    WriteLn('2021-12-15 Part 2: ', largeInputMap[High(largeInputMap), High(largeInputMap)]);
end.