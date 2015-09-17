library texturesynthesis.kdtree;

import 'dart:math';

part 'kdnode.dart';
part 'hpoint.dart';

// *****************************
// Based on http://home.wlu.edu/~levys/software/kd/
// *****************************

class KDTree {
  // Number of dimensions
  int _dimension;

  // Root node  of  k-d tree
  KDNode _rootNode;

  // count of nodes
  int _count;

  // Constructor
  KDTree(int dimension) {
    _dimension = dimension;
    _rootNode =  null;
  }

  void insert(List<num> key, num value) {
    if(key.length != dimension) {
      throw new  WrongDimensionException();
    }
    else {
      try {
        _rootNode =
      }
    }
  }

  // Getter
  int get dimension => _dimension;
  int get count => _count;
}

class WrongDimensionException implements Exception {
  /**
   * A message describing the format error.
   */
  final String message = "There was an error regarding the dimensions.";

  /**
   * Creates a new FormatException with an optional error [message].
   */
  const WrongDimensionException();

  String toString() => "WrongDimensionException: $message";
}

class KeyDuplicateException implements Exception {
  /**
   * A message describing the format error.
   */
  final String message = "There exists already this key.";

  /**
   * Creates a new FormatException with an optional error [message].
   */
  const KeyDuplicateException();

  String toString() => "KeyDuplicateException: $message";
}