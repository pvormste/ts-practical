part of texturesynthesis.kdtree;


//import 'dart:math';

class HPoint {

  // Statics
  static num sqrDist(HPoint x, HPoint y) {
    num dist = 0;

    for  (int i = 0; i < x.coord.length; ++i) {
      num diff = (x.coord[i] - y.coord[i]);
      dist += (diff * diff);
    }

    return dist;
  }

  static num eucDist(HPoint x, HPoint y) {
    return sqrt(sqrDist(x, y));
  }


  //  Class
  List<num> coord;

  HPoint(int n) {
    coord = new List<num>(n);
  }

  HPoint.fromList(List<num> x) {
    coord = new List<num>(x.length);
    for(int i = 0; i < x.length; ++i) {
      coord[i] = x[i];
    }
  }

  HPoint clone() {
    return new  HPoint.fromList(coord);
  }

  bool equals(HPoint p) {
    for(int i = 0; i < coord.length; ++i) {
      if(coord[i] != p.coord[i])
        return false;
    }

    return true;
  }

  String toString() {
    String s = "";

    for(int i = 0; i < coord.length; ++i) {
      s = s + coord[i] + " ";
    }

    return s;
  }

}