create table RawInput (Column1 Text, Column2 Text);
.mode csv
.separator ,
.import 'input.txt' RawInput

create table Folds (Axis Text, Offset Int);
insert into Folds (Axis, Offset)
select  substr(Column1, 12, instr(Column1, '=') - 12),
        substr(Column1, instr(Column1, '=') + 1)
from RawInput
where Column1 like 'fold along%';

with recursive

Solution (Nr, X, Y) as (
    select 1, cast(Column1 as Int), cast (Column2 as Int)
    from RawInput
    where Column2 is not null
    
    union
    
    select  Nr + 1,
            case when Axis = 'y' or X <= Offset then X else Offset * 2 - X end,
            case when Axis = 'x' or Y <= Offset then Y else Offset * 2 - Y end
    from Solution
    join Folds on Nr = Folds.RowID
),

MaxSolution (Nr, X, Y) as (
    select * from Solution where Nr = (select max(Nr) from Solution)
),

Lines (MaxX, Y, Chars) as (
    select distinct -1, Y, char(10)
    from MaxSolution

    union

    select  MaxX + 1,
            Lines.Y,
            Chars || case when Nr is null then ' ' else '█' end
    from Lines
    left join MaxSolution on X = MaxX + 1 and MaxSolution.Y = Lines.Y
    where MaxX < (select max(X) from MaxSolution)
),

Display (MaxY, Chars) as (
    select -1, ''

    union

    select MaxY + 1, Display.Chars || Lines.Chars
    from Display
    join Lines on MaxX = (select max(MaxX) from Lines) and Y = MaxY + 1
)

select '2021-12-13 Part 1: ' || count(*)
from Solution
where Nr = 2

union all

select '2021-12-13 Part 2: ' || Chars
from Display
where MaxY = (select max(MaxY) from Display);