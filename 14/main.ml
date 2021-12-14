let polymerTemplate = "CBNBOKHVBONCPPBBCKVH";;

let insertionRules = [
    "FK", "O";
    "BK", "B";
    "PB", "N";
    "VS", "P";
    "OF", "H";
    "KP", "K";
    "PS", "K";
    "OV", "N";
    "FO", "H";
    "KN", "P";
    "HF", "K";
    "BV", "N";
    "OO", "B";
    "KC", "V";
    "CK", "H";
    "BC", "P";
    "VV", "S";
    "NS", "C";
    "SF", "O";
    "BN", "V";
    "NH", "N";
    "VP", "F";
    "KH", "S";
    "BO", "N";
    "VN", "K";
    "BB", "H";
    "CH", "H";
    "HP", "O";
    "KK", "O";
    "CB", "S";
    "VC", "P";
    "FH", "B";
    "SP", "C";
    "NF", "O";
    "HN", "N";
    "PO", "P";
    "PP", "C";
    "SO", "F";
    "FB", "B";
    "SB", "B";
    "SC", "B";
    "HK", "O";
    "BF", "V";
    "OB", "B";
    "NC", "V";
    "HC", "F";
    "KO", "C";
    "NV", "C";
    "HB", "H";
    "FP", "S";
    "OS", "O";
    "HH", "K";
    "OK", "B";
    "OH", "C";
    "NP", "V";
    "SN", "H";
    "SK", "B";
    "HV", "F";
    "VF", "P";
    "CP", "H";
    "FN", "H";
    "FV", "B";
    "CN", "H";
    "OC", "O";
    "KV", "P";
    "CF", "B";
    "OP", "B";
    "FC", "O";
    "PC", "B";
    "CV", "S";
    "PV", "H";
    "VK", "N";
    "SS", "C";
    "HO", "F";
    "VH", "C";
    "NB", "S";
    "NN", "F";
    "FF", "K";
    "CC", "H";
    "SV", "H";
    "CO", "K";
    "BP", "O";
    "SH", "H";
    "KS", "K";
    "FS", "F";
    "PF", "S";
    "BS", "H";
    "VO", "H";
    "NK", "F";
    "PK", "B";
    "KB", "K";
    "CS", "C";
    "VB", "V";
    "BH", "O";
    "KF", "N";
    "HS", "H";
    "PH", "K";
    "ON", "H";
    "PN", "K";
    "NO", "S";
];;

module PolymerMap = Map.Make(String);;

let polymerMap =
    (List.init (String.length polymerTemplate) (String.get polymerTemplate))
    |> List.fold_left (fun (previousChar, polymerMap) nextChar ->
        let pair = Printf.sprintf "%c%c" previousChar nextChar in
        nextChar,
        polymerMap |> PolymerMap.update pair (fun count ->
            Option.value count ~default:Int64.zero
            |> Int64.add 1L
            |> Option.some
        )
    ) (' ', PolymerMap.empty)
    |> snd
;;

let iterateOnce polymerMap =
    PolymerMap.fold (fun pair count polymerMap ->
        let updateCount pair = PolymerMap.update pair (fun count' ->
            Option.value count' ~default:Int64.zero
            |> Int64.add count
            |> Option.some
        ) in
        match List.assoc_opt pair insertionRules with
        | Some insertionChar ->
            let leftPair = Printf.sprintf "%c%c" (String.get pair 0) (String.get insertionChar 0) in
            let rightPair = Printf.sprintf "%c%c" (String.get insertionChar 0) (String.get pair 1) in
            polymerMap |> updateCount leftPair |> updateCount rightPair
        | None ->
            polymerMap |> updateCount pair
    ) polymerMap PolymerMap.empty
;;

let iterate count polymerMap =
    List.init count (fun index -> index)
    |> List.fold_left (fun polymerMap _ -> iterateOnce polymerMap) polymerMap
;;

let aggregate polymerMap =
    PolymerMap.fold (fun pair count ->
        PolymerMap.update (String.sub pair 1 1) (fun count' ->
            Option.value count' ~default:Int64.zero
            |> Int64.add count
            |> Option.some
        )
    ) polymerMap PolymerMap.empty
;;

let printResults part polymerMap =
    let (minChar, maxChar) = PolymerMap.fold (fun char count (minChar, maxChar) ->
        let compareChar comparisonChar op =
            comparisonChar
            |> Option.map (fun c -> if op (PolymerMap.find c polymerMap) count then char else c)
            |> Option.value ~default:char
            |> Option.some
        in
        compareChar minChar (>), compareChar maxChar (<)
    ) polymerMap (None, None) in
    Int64.sub (PolymerMap.find (Option.get maxChar) polymerMap) (PolymerMap.find (Option.get minChar) polymerMap)
    |> Printf.printf "2021-12-14 Part %d: %Li\n" part
;;

polymerMap
|> iterate 10
|> aggregate
|> printResults 1;;

polymerMap
|> iterate 40
|> aggregate
|> printResults 2;;