{-# LANGUAGE OverloadedStrings #-}

import qualified Data.Map as Map
import qualified Data.Set as Set
import Data.String (fromString)
import Data.Text (splitOn, toUpper)
import Text.Printf (printf)

main = do
    inputLines <- lines <$> readFile "input.txt"
    let caveMap = foldl buildCaveMap Map.empty $ fromString <$> inputLines
    let smallCavesOnlyOnce = length . Set.fromList . findPaths caveMap "start" [] (Set.singleton "start")
    printf "2021-12-12 Part 1: %d\n" $ smallCavesOnlyOnce True
    printf "2021-12-12 Part 2: %d\n" $ smallCavesOnlyOnce False
    
buildCaveMap caveMap caveString =
    case splitOn "-" caveString of
        [ from, to ] ->
            Map.insertWith Set.union from (Set.singleton to) .
            Map.insertWith Set.union to (Set.singleton from) $
            caveMap
        _ -> caveMap

findPaths caveMap cave path visitedCaves smallCaveVisited =
    concatMap traverseCave $
    flip Set.difference visitedCaves $
    caveMap Map.! cave
    where
        traverseCave nextCave
            | nextCave == "end" =
                [ "end" : cave : path ]
            | toUpper nextCave == nextCave =
                findNextPaths nextCave visitedCaves smallCaveVisited
            | smallCaveVisited =
                findNextPaths nextCave (Set.insert nextCave visitedCaves) True
            | otherwise =
                findNextPaths nextCave (Set.insert nextCave visitedCaves) False <>
                findNextPaths nextCave visitedCaves True
        findNextPaths nextCave = findPaths caveMap nextCave (cave : path)