// Copyright 2013 Park "segfault" Joon Kyu <segfault87@gmail.com>
// Source: https://gist.github.com/segfault87/6259952
// Changed Vec4 to multi dimensional vector
library texturesynthesis.kdtree;

//import 'dart:typed_data';
import 'dart:math';

const num EPSILON = 0.1;
int DIMENSIONS = 3;

class VecMultiDimensionInt implements Comparable {
  List<int> val;
  int dimension;

  VecMultiDimensionInt(int dimension) {
    this.dimension = dimension;
    val = new List(this.dimension);

    for(int i = 0; i < this.dimension; ++i) {
      val[i] = 0;
    }
  }

  VecMultiDimensionInt.fromList(List<int> source) {
    this.dimension = source.length;
    val = new List(this.dimension);

    for(int i = 0; i < this.dimension; ++i) {
      val[i] = source[i];
    }
  }

  // TODO COPY

  int operator [] (int index) => val[index];
  void operator []= (int index, num v) {
    val[index] = v;
  }

  num length() {
    int sum = 0;

    for(int i = 0; i < this.dimension; ++i) {
      int square = val[i] * val[i];

      sum += square;
    }

    return sqrt(sum);
  }

  int compareTo(VecMultiDimensionInt other) {
    print(length());
    return length().compareTo(other.length());
  }

  // TODO NORMALIZE

  String toString() {
    String str = '(';

    for(int i = 0; i < this.dimension; ++i) {
      if(i < this.dimension - 1)
        str += '${val[i]}, ';
      else
        str += '${val[i]})';
    }

    return str;
  }

  // TODO toDat

  VecMultiDimensionInt operator + (VecMultiDimensionInt rhs) {
    List<int> newVec = [];

    for(int i = 0; i < this.dimension; ++i) {
      int sum = val[i] + rhs.val[i];

      newVec.add(sum);
    }


    return new VecMultiDimensionInt.fromList(newVec);
  }

  VecMultiDimensionInt operator - (VecMultiDimensionInt rhs) {
    List<int> newVec = [];

    for(int i = 0; i < this.dimension; ++i) {
      int diff = val[i] - rhs.val[i];

      newVec.add(diff);
    }


    return new VecMultiDimensionInt.fromList(newVec);
  }

  VecMultiDimensionInt operator - () {
    List<int> newVec = [];

    for(int i = 0; i < this.dimension; ++i) {
      int newVal = val[i] * -1;

      newVec.add(newVal);
    }


    return new VecMultiDimensionInt.fromList(newVec);
  }

  VecMultiDimensionInt operator * (num s) {
    List<int> newVec = [];

    for(int i = 0; i < this.dimension; ++i) {
      int prod = val[i] * s;

      newVec.add(prod);
    }


    return new VecMultiDimensionInt.fromList(newVec);
  }

  bool operator == (VecMultiDimensionInt other) {
    return equals(this, other);
  }

  static num distance(VecMultiDimensionInt a, VecMultiDimensionInt b) {

    int sum = 0;

    for(int i = 0; i < DIMENSIONS; ++i) {
      int diff = a.val[i] - b.val[i];
      diff = diff*diff;

      sum += diff;
    }

    return sqrt(sum);
  }

  // TODO angle

  // TODO cross

  static bool equals(VecMultiDimensionInt a, VecMultiDimensionInt b) {

    for(int i = 0; i < DIMENSIONS; ++i) {
      int diff = a.val[i] - b.val[i];

      if(diff < 0)
        diff *= -1;

      if(diff >= EPSILON)
        return false;
    }

    return true;
  }
}

class KdNodeData<T> {
  VecMultiDimensionInt vec;
  T tag;

  KdNodeData(this.vec, this.tag);

  String toString() => '$tag at $vec';
}

class KdNode<T> {
  KdNodeData<T> data;
  KdNode left;
  KdNode right;
  KdNode parent;
  int dimension;

  KdNode(this.data, this.dimension, this.parent);
}

class BestMatch<T> {
  KdNode<T> node;
  num distance;

  BestMatch(this.node, this.distance);
}

class KdTree<T> {
  KdNode<T> root;

  KdNode buildTree(List<KdNodeData<T>> data, int depth, KdNode parent) {
    int dim = depth % DIMENSIONS;

    if (data.length == 0)
      return null;
    if (data.length == 1) {
      return new KdNode(data[0], dim, parent);
    }

    data.sort((KdNodeData a, KdNodeData b) => a.vec[dim] - b.vec[dim]);

    int median = (data.length / 2.0).floor();
    KdNode<T> node = new KdNode<T>(data[median], dim, parent);
    node.left = buildTree(data.sublist(0, median), depth + 1, node);
    node.right = buildTree(data.sublist(median + 1), depth + 1, node);

    return node;
  }

  KdTree.fromList(List<VecMultiDimensionInt> points, List<T> tags) {
    List<KdNodeData<T>> interweaved = new List<KdNodeData<T>>();
    for (int i = 0; i < points.length; ++i) {
      T tag;
      if (tags != null && i >= tags.length)
        tag = null;
      else
        tag = tags[i];
      interweaved.add(new KdNodeData<T>(points[i], tag));
    }

    root = buildTree(interweaved, 0, null);
  }

  bool insert(VecMultiDimensionInt point, T tag, {bool overwrite: false}) {
    KdNodeData<T> existing = exact(point);
    if (existing != null) {
      print ('multiple occurrence found');
      if (overwrite) {
        existing.tag = tag;
        return true;
      } else {
        return false;
      }
    }

    KdNode<T> innerSearch(KdNode node, KdNode parent) {
      if (node == null)
        return parent;

      int dimension = node.dimension;
      if (point[dimension] < node.data.vec[dimension])
        return innerSearch(node.left, node);
      else
        return innerSearch(node.right, node);
    }

    KdNodeData<T> nodeData = new KdNodeData<T>(point, tag);
    KdNode<T> insertPosition = innerSearch(root, null);
    if (insertPosition == null) {
      root = new KdNode<T>(nodeData, 0, null);
      return false;
    }

    KdNode<T> newNode = new KdNode<T>(nodeData,
    (insertPosition.dimension + 1) % DIMENSIONS,
    insertPosition);
    int dimension = insertPosition.dimension;

    if (point[dimension] < insertPosition.data.vec[dimension])
      insertPosition.left = newNode;
    else
      insertPosition.right = newNode;

    return true;
  }

  void remove(VecMultiDimensionInt point) {
    KdNode<T> nodeSearch(KdNode<T> node) {
      if (node == null)
        return null;

      if (VecMultiDimensionInt.equals(node.data.vec, point))
        return node;

      int dimension = node.dimension;

      if (point[dimension] < node.data.vec[dimension])
        return nodeSearch(node.left);
      else
        return nodeSearch(node.right);
    }

    void removeNode(KdNode<T> node) {
      KdNode<T> findMax(KdNode<T> node, int dim) {
        if (node == null)
          return null;

        if (node.dimension == dim) {
          if (node.right != null)
            return findMax(node.right, dim);
          return node;
        }

        KdNode<T> left = findMax(node.left, dim);
        KdNode<T> right = findMax(node.right, dim);
        KdNode<T> max = node;

        if (left != null && left.data.vec[dim] > node.data.vec[dim])
          max = left;
        if (right != null && right.data.vec[dim] > max.data.vec[dim])
          max = right;

        return max;
      }

      KdNode<T> findMin(KdNode<T> node, int dim) {
        if (node == null)
          return null;

        if (node.dimension == dim) {
          if (node.left != null)
            return findMin(node.left, dim);
          return node;
        }

        KdNode<T> left = findMin(node.left, dim);
        KdNode<T> right = findMin(node.right, dim);
        KdNode<T> min = node;

        if (left != null && left.data.vec[dim] < node.data.vec[dim])
          min = left;
        if (right != null && right.data.vec[dim] < min.data.vec[dim])
          min = right;

        return min;
      }

      if (node.left == null && node.right == null) {
        if (node.parent == null) {
          root = null;
          return;
        }

        int pdim = node.parent.dimension;

        if (node.data.vec[pdim] < node.parent.data.vec[pdim])
          node.parent.left = null;
        else
          node.parent.right = null;

        return;
      }

      KdNode<T> nextNode;
      KdNodeData<T> nextData;
      if (node.left != null)
        nextNode = findMax(node.left, node.dimension);
      else
        nextNode = findMin(node.right, node.dimension);
      nextData = nextNode.data;
      removeNode(nextNode);
      node.data = nextData;
    }

    KdNode<T> node = nodeSearch(root);

    if (node == null)
      return;

    removeNode(node);
  }

  KdNodeData<T> exact(VecMultiDimensionInt point) {
    KdNodeData<T> result = nearest(point);

    if (result == null)
      return null;

    if (result.vec == point)
      return result;
    else
      return null;
  }

  KdNodeData<T> nearest(VecMultiDimensionInt point) {
    if (root == null)
      return null;

    KdNode<T> min = root;

    KdNode<T> findNearest(KdNode<T> node, int depth) {
      if (node == null)
        return min;

      int dimension = depth % DIMENSIONS;
      num dist = point[dimension] - min.data.vec[dimension];

      KdNode<T> near, far;
      if (dist <= 0.0) {
        near = node.left;
        far = node.right;
      } else {
        near = node.right;
        far = node.left;
      }

      min = findNearest(near, depth + 1);
      if (dist * dist < VecMultiDimensionInt.distance(point, min.data.vec))
        min = findNearest(far, depth + 1);
      if (VecMultiDimensionInt.distance(point, node.data.vec) < VecMultiDimensionInt.distance(point, min.data.vec))
        min = node;

      return min;
    }

    findNearest(root, 0);

    return min.data;
  }

  List<KdNodeData<T>> nearestMultiple(VecMultiDimensionInt point, int maxNodes) {
    BinaryHeap<BestMatch<T>> bestNodes = new BinaryHeap<BestMatch<T>>((BestMatch i) => -i.distance);

    void nearestSearch(KdNode<T> node) {
      KdNode<T> bestChild, otherChild;
      int dimension = node.dimension;
      num ownDistance = VecMultiDimensionInt.distance(point, node.data.vec);
      VecMultiDimensionInt linearPoint = new VecMultiDimensionInt(DIMENSIONS);
      num linearDistance;

      void saveNode(KdNode<T> item, num distance) {
        bestNodes.push(new BestMatch<T>(item, distance));
        if (bestNodes.size() > maxNodes)
          bestNodes.pop();
      }

      for (int i = 0; i < DIMENSIONS; ++i) {
        if (i == node.dimension)
          linearPoint[i] = point[i];
        else
          linearPoint[i] = node.data.vec[i];
      }

      linearDistance = VecMultiDimensionInt.distance(linearPoint, node.data.vec);

      if (node.right == null && node.left == null) {
        if (bestNodes.size() < maxNodes || ownDistance < bestNodes.peek().distance)
          saveNode(node, ownDistance);
        return;
      }

      if (node.right == null) {
        bestChild = node.left;
      } else if (node.left == null) {
        bestChild = node.right;
      } else {
        if (point[dimension] < node.data.vec[dimension])
          bestChild = node.left;
        else
          bestChild = node.right;
      }

      nearestSearch(bestChild);

      if (bestNodes.size() < maxNodes || ownDistance < bestNodes.peek().distance)
        saveNode(node, ownDistance);

      if (bestNodes.size() < maxNodes || linearDistance.abs() < bestNodes.peek().distance) {
        if (bestChild == node.left)
          otherChild = node.right;
        else
          otherChild = node.left;

        if (otherChild != null)
          nearestSearch(otherChild);
      }
    }

    nearestSearch(root);

    List<KdNodeData<T>> result = new List<KdNodeData<T>>();

    for (int i = 0; i < maxNodes; ++i) {
      if (i < bestNodes.size() && bestNodes.content[i].node != null)
        result.add(bestNodes.content[i].node.data);
    }

    return result;
  }

}

class BinaryHeap<T> {
  List<T> content;
  Function scoreFunction;

  BinaryHeap(Function scoreFunction) {
    content = new List<T>();
    this.scoreFunction = scoreFunction;
  }

  void push(T elem) {
    content.add(elem);
    bubbleUp(content.length - 1);
  }

  T pop() {
    if (content.length == 0)
      return null;

    T result = content[0];
    T end = content.removeLast();

    if (content.length > 0) {
      content[0] = end;
      sinkDown(0);
    }

    return result;
  }

  T peek() {
    if (content.length == 0)
      return null;

    return content[0];
  }

  void remove(T val) {
    int len = content.length;
    for (int i = 0; i < len; ++i) {
      if (content[i] == val) {
        T end = content.removeLast();
        if (i != len - 1) {
          content[i] = end;
          if (scoreFunction(end) < scoreFunction(val))
            bubbleUp(i);
          else
            sinkDown(i);
        }
        return;
      }
    }
  }

  int size() {
    return content.length;
  }

  void bubbleUp(int n) {
    T element = content[n];

    while (n > 0) {
      int parentN = (((n + 1) / 2) - 1).floor();
      T parent = content[parentN];

      if (scoreFunction(element) < scoreFunction(parent)) {
        content[parentN] = element;
        content[n] = parent;
        n = parentN;
      } else {
        break;
      }
    }
  }

  void sinkDown(int n) {
    int length = content.length;
    T element = content[n];
    num elemScore = scoreFunction(element);

    while (true) {
      int child2N = (n + 1) * 2;
      int child1N = child2N - 1;
      num child1Score, child2Score;

      int swap = -1;
      if (child1N < length) {
        T child1 = content[child1N];
        child1Score = scoreFunction(child1);

        if (child1Score < elemScore)
          swap = child1N;
      }

      if (child2N < length) {
        T child2 = content[child2N];
        child2Score = scoreFunction(child2);

        if (child2Score < (swap == -1 ? elemScore : child1Score))
          swap = child2N;
      }

      if (swap != -1) {
        content[n] = content[swap];
        content[swap] = element;
        n = swap;
      } else {
        break;
      }
    }
  }
}

/*class Vec4 implements Comparable {
  Float32List val;

  Vec4() {
    val = new Float32List(4);
    val[0] = 0.0; val[1] = 0.0; val[2] = 0.0; val[3] = 1.0;
  }

  Vec4.xyz(num x, num y, num z) {
    val = new Float32List(4);
    val[0] = x; val[1] = y; val[2] = z; val[3] = 1.0;
  }

  Vec4.xyzw(num x, num y, num z, num w) {
    val = new Float32List(4);
    val[0] = x; val[1] = y; val[2] = z; val[3] = w;
  }

  Vec4.copy(Vec4 other) {
    val = new Float32List(4);
    val[0] = other.val[0];
    val[1] = other.val[1];
    val[2] = other.val[2];
    val[3] = other.val[3];
  }

  num x() => val[0];
  num y() => val[1];
  num z() => val[2];
  num w() => val[3];

  num operator [] (int index) => val[index];
  void operator []= (int index, num v) {
    val[index] = v;
  }

  setX(num v) => val[0] = v;
  setY(num v) => val[1] = v;
  setZ(num v) => val[2] = v;
  setW(num v) => val[3] = v;

  int compareTo(Vec4 other) {
    print(length());
    return length().compareTo(other.length());
  }

  num length() {
    return sqrt(x()*x() + y()*y() + z()*z());
  }

  Vec4 normalize() {
    num r = length();

    if (r != 0.0)
      return new Vec4.xyz(x() / r, y() / r, z() / r);
    else
      return new Vec4();
  }

  String toString() {
    return '(${x()}, ${y()}, ${z()})';
  }

  String toDat() {
    return '${x()} ${y()} ${z()}';
  }

  Vec4 operator + (Vec4 rhs) {
    return new Vec4.xyz(x()+rhs.x(), y()+rhs.y(), z()+rhs.z());
  }

  Vec4 operator - (Vec4 rhs) {
    return new Vec4.xyz(x()-rhs.x(), y()-rhs.y(), z()-rhs.z());
  }

  Vec4 operator - () {
    return new Vec4.xyz(-x(), -y(), -z());
  }

  Vec4 operator * (num s) {
    return new Vec4.xyz(x()*s, y()*s, z()*s);
  }

  bool operator == (Vec4 other) {
    return equals(this, other);
  }

  static num distance(Vec4 a, Vec4 b) {
    num x = a.x() - b.x();
    num y = a.y() - b.y();
    num z = a.z() - b.z();

    return sqrt(x*x + y*y + z*z);
  }

  static num angle(Vec4 a, Vec4 b) {
    return acos(dot(a, b) / (sqrt(a.x()*a.x() + a.y()*a.y() + a.z()*a.z()) *
    sqrt(b.x()*b.x() + b.y()*b.y() + b.z()*b.z())));
  }

  static num dot(Vec4 a, Vec4 b) {
    return a.x()*b.x() + a.y()*b.y() + a.z()*b.z();
  }

  static Vec4 cross(Vec4 a, Vec4 b) {
    return new Vec4.xyz(
        a.y()*b.z() - a.z()*b.y(),
        a.z()*b.x() - a.x()*b.z(),
        a.x()*b.y() - a.y()*b.x());
  }

  static bool equals(Vec4 a, Vec4 b) {
    num x = (a.x() - b.x()).abs();
    num y = (a.y() - b.y()).abs();
    num z = (a.z() - b.z()).abs();
    num w = (a.w() - b.w()).abs();

    if (x < EPSILON && y < EPSILON && z < EPSILON && w < EPSILON)
      return true;
    else
      return false;
  }
}*/