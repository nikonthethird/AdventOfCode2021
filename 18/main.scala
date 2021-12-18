import scala.io.Source

sealed trait SnailfishNumber
case class Literal(n: Int) extends SnailfishNumber
case class Pair(lhs: SnailfishNumber, rhs: SnailfishNumber) extends SnailfishNumber

sealed trait ExplodeResult
case class ExplodeNone() extends ExplodeResult
case class ExplodeSome() extends ExplodeResult
case class Explode(lhn: Int, rhn: Int) extends ExplodeResult
case class ExplodeLeft(n: Int) extends ExplodeResult
case class ExplodeRight(n: Int) extends ExplodeResult

sealed trait SplitResult
case class SplitNone() extends SplitResult
case class SplitSome() extends SplitResult

object AdventOfCode extends App {
    def parse(cs: List[Char]): (List[Char], SnailfishNumber) = cs match {
        case '[' :: cs2 => 
            val (cs3, lhs) = parse(cs2)
            val (cs4, rhs) = parse(cs3.drop(1))
            (cs4.drop(1), Pair(lhs, rhs))
        case c :: cs2 =>
            (cs2, Literal(c.toInt - '0'.toInt))
        case _ =>
            throw new Exception("Unexpected input string.")
    }

    def mergeLeft(toMerge: Int, sfn: SnailfishNumber): SnailfishNumber = sfn match {
        case Literal(n) =>
            Literal(n + toMerge)
        case Pair(lhs, rhs) =>
            Pair(mergeLeft(toMerge, lhs), rhs)
    }

    def mergeRight(toMerge: Int, sfn: SnailfishNumber): SnailfishNumber = sfn match {
        case Literal(n) =>
            Literal(n + toMerge)
        case Pair(lhs, rhs) =>
            Pair(lhs, mergeRight(toMerge, rhs))
    }

    def performExplode(depth: Int, sfn: SnailfishNumber): (ExplodeResult, SnailfishNumber) = sfn match {
        case Literal(n) =>
            (ExplodeNone(), Literal(n))
        case Pair(Literal(lhn), Literal(rhn)) if depth >= 4 =>
            (Explode(lhn, rhn), Literal(0))
        case Pair(lhs, rhs) =>
            performExplode(depth + 1, lhs) match {
                case (ExplodeNone(), lhs2) =>
                    performExplode(depth + 1, rhs) match {
                        case (Explode(lhn, rhn), rhs2) =>
                            (ExplodeRight(rhn), Pair(mergeRight(lhn, lhs2), rhs2))
                        case (ExplodeLeft(n), rhs2) =>
                            (ExplodeSome(), Pair(mergeRight(n, lhs2), rhs2))
                        case (action, rhs2) =>
                            (action, Pair(lhs2, rhs2))
                    }
                case (Explode(lhn, rhn), lhs2) =>
                    (ExplodeLeft(lhn), Pair(lhs2, mergeLeft(rhn, rhs)))
                case (ExplodeRight(n), lhs2) =>
                    (ExplodeSome(), Pair(lhs2, mergeLeft(n, rhs)))
                case (action, lhs2) =>
                    (action, Pair(lhs2, rhs))
            }
    }

    def performSplit(sfn: SnailfishNumber): (SplitResult, SnailfishNumber) = sfn match {
        case Literal(n) if n >= 10 =>
            (SplitSome(), Pair(Literal((n / 2.0).floor.toInt), Literal((n / 2.0).ceil.toInt)))
        case Pair(lhs, rhs) =>
            (performSplit(lhs), performSplit(rhs)) match {
                case ((SplitSome(), lhs2), _) =>
                    (SplitSome(), Pair(lhs2, rhs))
                case (_, (action, rhs2)) =>
                    (action, Pair(lhs, rhs2))
            }
        case number =>
            (SplitNone(), number)
    }

    def reduce(sfn: SnailfishNumber): SnailfishNumber =
        performExplode(0, sfn) match {
            case (ExplodeNone(), _) =>
                performSplit(sfn) match {
                    case (SplitNone(), _) =>
                        sfn
                    case (_, sfn2) =>
                        reduce(sfn2)
                }
            case (_, sfn2) =>
                reduce(sfn2)
        }

    def magnitude(sfn: SnailfishNumber): Int = sfn match {
        case Literal(n) =>
            n
        case Pair(lhs, rhs) =>
            3 * magnitude(lhs) + 2 * magnitude(rhs)
    }

    val numbers = Source.fromFile("input.txt").getLines.map(line => parse(line.toList)._2).toList
    println(s"2021-12-18 Part 1: ${magnitude(numbers.reduce((n1, n2) => reduce(Pair(n1, n2))))}")

    val maxMagnitude = numbers.combinations(2).flatMap(numbers =>
        List(magnitude(reduce(Pair(numbers(0), numbers(1)))), magnitude(reduce(Pair(numbers(1), numbers(0)))))
    ).max
    println(s"2021-12-18 Part 2: $maxMagnitude")
}