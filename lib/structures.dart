part of texturesynthesis.methods;

class RGB {
  static int difference(RGB valueA, RGB valueB) {
    int diffRed = (valueA.red - valueB.red).abs();
    int diffGreen =  (valueA.green - valueB.green).abs();
    int diffBlue = (valueA.blue - valueB.blue).abs();

    return ((diffRed*diffRed) + (diffGreen*diffGreen) + (diffBlue*diffBlue));
  }

  int red;
  int green;
  int blue;

  RGB(int r, int g, int b) {
    red = r;
    green = g;
    blue = b;
  }

}

class Vector2 {
  int x;
  int y;

  Vector2(int x, int y) {
    this.x = x;
    this.y = y;
  }

  Vector2.Zero() {
    this.x = 0;
    this.y = 0;
  }
}

class Vector3 {
  int x;
  int y;
  int rotation;

  Vector3(int x, int y, int rot) {
    this.x = x;
    this.y = y;
    this.rotation = rot;
  }

  Vector3.fromVector2(Vector2 pos, int rot) {
    this.x = pos.x;
    this.y = pos.y;
    this.rotation = rot;
  }
}

class Matrix<T>{
  List<T> _data;
  int _col;
  int _row;

  Matrix(int col, int row) {
    this._col = col;
    this._row = row;
    this._data = new List<T>(this._col * this._row);
  }

  void insert(int x, int y, T value){
    this._data[y * this._col +x]= value;
  }

  T getValue(int x, int y){
    return this._data[y * this._col +x];
  }
}

class ComparisonMaskElement {
  bool isComparable;
  int color;

  ComparisonMaskElement.isAllowed(int color) {
    this.isComparable = true;
    this.color = color;
  }

  ComparisonMaskElement.notAllowed() {
    this.isComparable = false;
    this.color = -1;
  }
}