import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:linalg/linalg.dart';
import 'package:quiver/core.dart';

// One scanner is considered in range of another scanner if it has that many beacons overlapping.
const beaconsThatHaveToOverlap = 12;

// Vectors (based on matrices) are implemented to return their internal list's hashCode:
// https://github.com/altera2015/linalg/blob/0ea3ca8571d59b6862949688c01c13adbae64e79/lib/matrix.dart#L214
// This unfortunately means that using vectors in sets is useless,
// so we have to provide our own hashCode implementation using the quiver package.
HashSet<Vector> createVectorSet([Iterable<Vector> vectors = const []]) =>
  HashSet<Vector>(
    equals: (vec1, vec2) => vec1 == vec2,
    hashCode: (vec) => hashObjects(vec.toList()),
  )
  ..addAll(vectors);

// The rotation matrices for the 4 orientations of a cube face (around the X-axis).
final List<Matrix> singleFaceRotations = [
  Matrix([[1, 0, 0], [0, 1, 0], [0, 0, 1]]),   // +x=>+x +y=>+y +z=>+z
  Matrix([[1, 0, 0], [0, 0, -1], [0, 1, 0]]),  // +x=>+x +y=>-z +z=>+y
  Matrix([[1, 0, 0], [0, -1, 0], [0, 0, -1]]), // +x=>+x +y=>-y +z=>-z
  Matrix([[1, 0, 0], [0, 0, 1], [0, -1, 0]]),  // +x=>+x +y=>+z +z=>-y
];

// The rotation matrices aligning a face orthogonal to the X-axis.
final List<Matrix> faceToXRotations = [
  Matrix([[1, 0, 0], [0, 1, 0], [0, 0, 1]]),   // +x=>+x +y=>+x +z=>+z
  Matrix([[0, 1, 0], [-1, 0, 0], [0, 0, 1]]),  // +x=>+y +y=>-x +z=>+z
  Matrix([[-1, 0, 0], [0, -1, 0], [0, 0, 1]]), // +x=>-x +y=>-y +z=>+z
  Matrix([[0, -1, 0], [1, 0, 0], [0, 0, 1]]),  // +x=>-y +y=>+x +z=>+z
  Matrix([[0, 0, -1], [0, 1, 0], [1, 0, 0]]),  // +x=>-z +y=>+y +z=>+x
  Matrix([[0, 0, 1], [0, 1, 0], [-1, 0, 0]]),  // +x=>+z +y=>+y +z=>-x
];

// All face rotations of the 3D cube.
final List<Matrix> rotations = faceToXRotations.expand((face_to_x_rot) =>
  singleFaceRotations.map((single_face_rot) =>
    single_face_rot * face_to_x_rot
  )
).toList();

// Represents a scanner to identify and place.
class Scanner {
  final int number;
  final HashSet<Vector> beacons;

  Scanner(this.number, this.beacons);
}

// Represents an identified and placed scanner.
class PlacedScanner extends Scanner {
  final Vector origin;
  final Matrix rotation;
  final PlacedScanner? locatedUsing;

  PlacedScanner(Scanner scanner, HashSet<Vector> beacons, this.origin, this.rotation, this.locatedUsing)
    : super(scanner.number, beacons);

  PlacedScanner.origin(Scanner scanner)
    : this(scanner, scanner.beacons, Vector.column([0, 0, 0]), rotations[0], null);
}

// Data passed to the isolates that test whether the scanner to place fits
// according to the beacons of the already identified scanner.
class PlacementData {
  final PlacedScanner identifiedScanner;
  final Scanner scannerToPlace;
  final SendPort sendPort;

  PlacementData(this.identifiedScanner, this.scannerToPlace, this.sendPort);
}

// Turn the input data into a list of scanners that have to be identified.
List<Scanner> readScannerData() =>
  File('input.txt')
  .readAsLinesSync()
  .fold([], (scanners, line) {
    final scannerMatch = RegExp(r'^--- scanner (\d+) ---$').firstMatch(line);
    final beaconMatch = RegExp(r'^(-?\d+),(-?\d+),(-?\d+)$').firstMatch(line);
    if (scannerMatch != null)
      scanners.add(Scanner(int.parse(scannerMatch.group(1)!), createVectorSet()));
    if (beaconMatch != null)
      scanners[scanners.length - 1].beacons.add(Vector.column([
        for (final i in [1, 2, 3]) double.parse(beaconMatch.group(i)!)
      ]));
    return scanners;
  });

// Consider each of the beacons of the identified scanner as a possible overlap of any
// beacon in the scanner to place using the given scanner rotation. This way, all possible
// origins of the scanner will be located.
Iterable<Vector> getPossibleOrigins(Scanner identifiedScanner, Scanner scannerToPlace, Matrix rotation) sync* {
  for (final identifiedBeacon in identifiedScanner.beacons) {
    for (final beaconToPlace in scannerToPlace.beacons.skip(beaconsThatHaveToOverlap - 1)) {
      yield identifiedBeacon - (rotation * beaconToPlace).toVector();
    }
  }
}

// Isolate function that attempts to place a scanner next to an already identified scanner
// by trying all possible scanner origins to find one where at least 12 beacons overlap.
// If such a scanner origin is found, it is returned, if not, null is returned so the calling
// code can determine when all isolate threads have failed to place the scanner.
void tryPlaceScanner(PlacementData data) {
  for (final rotation in rotations) {
    for (final possibleOrigin in getPossibleOrigins(data.identifiedScanner, data.scannerToPlace, rotation)) {
      final alignedBeacons = createVectorSet(data.scannerToPlace.beacons.map((beacon) => (rotation * beacon).toVector() + possibleOrigin));
      final overlappingBeacons = data.identifiedScanner.beacons.intersection(alignedBeacons);
      if (overlappingBeacons.length >= beaconsThatHaveToOverlap) {
        return data.sendPort.send(PlacedScanner(data.scannerToPlace, alignedBeacons, possibleOrigin, rotation, data.identifiedScanner));
      }
    }
  }
  data.sendPort.send(null);
}

Future<void> main() async {
  final remainingScanners = readScannerData();
  final totalBeacons = createVectorSet();

  // Create the identified list containing the first scanner.
  // The first scanner determines the origin of the coordinate system.
  final identifiedScanners = [PlacedScanner.origin(remainingScanners.removeAt(0))];
  totalBeacons.addAll(identifiedScanners[0].beacons);

  // Each remaining scanner has to be fitted according to the
  // already identified scanners.
  while (remainingScanners.isNotEmpty) {
    for (final scannerToPlace in remainingScanners) {
      // Try each remaining scanner separately and test it agains all other
      // identified scanners on a separate isolate thread.
      final receivePort = ReceivePort();
      final completer = Completer<PlacedScanner?>();
      final placedScannerIsolates = await Future.wait(
        identifiedScanners.reversed.map((identifiedScanner) => Isolate.spawn(
          tryPlaceScanner,
          PlacementData(identifiedScanner, scannerToPlace, receivePort.sendPort)
        ))
      );
      // Wait for the isolate thread results. If all computations failed to identify the
      // scanner, the completer is completed with a null.
      var noResultCount = 0;
      receivePort.listen((placedScanner) {
        if (placedScanner == null && ++noResultCount < identifiedScanners.length) return;
        if (!completer.isCompleted) completer.complete(placedScanner);
      });
      final placedScanner = await completer.future;
      // Kill all remaining isolate threads, if any.
      placedScannerIsolates.forEach((placedScannerIsolate) =>
        placedScannerIsolate.kill(priority: Isolate.immediate)
      );
      // If the scanner could be identified and placed, move it
      // to the other collection and repeat the process.
      if (placedScanner != null) {
          remainingScanners.remove(scannerToPlace);
          identifiedScanners.add(placedScanner);
          totalBeacons.addAll(placedScanner.beacons);
          print(
            'Placed scanner ${placedScanner.number.toString().padLeft(2)} relative to scanner '
            '${placedScanner.locatedUsing!.number.toString().padLeft(2)} '
            '(${remainingScanners.length.toString().padLeft(2)} remaining)...'
          );
          break;
      }
    }
  }

  // Compute the maximum manhattan distance between each pair of identified scanners.
  final maximumDistance = identifiedScanners.fold<double>(0.0, (maximumDistance, scanner1) =>
    identifiedScanners
    .skip(identifiedScanners.indexOf(scanner1) + 1)
    .fold<double>(maximumDistance, (maximumDistance, scanner2) =>
      max(maximumDistance, (scanner1.origin - scanner2.origin).manhattanNorm())
    )
  ).toInt();

  print('2021-12-19 Part 1: ${totalBeacons.length}');
  print('2021-12-19 Part 2: $maximumDistance');
  exit(0);
}