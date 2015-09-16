part of texturesynthesis.methods;

class RGB {
  static int difference(RGB valueA, RGB valueB) {
    int diffRed = (valueA.red - valueB.red);
    int diffGreen =  (valueA.green - valueB.green);
    int diffBlue = (valueA.blue - valueB.blue);

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

  operator +(RGB other) {
    red += other.red;
    green += other.green;
    blue += other.blue;
  }

  operator /(int divider) {
    red ~/= divider;
    green ~/= divider;
    blue ~/= divider;
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

  Matrix.fillOnCreate(int col, int row, T value) {
    this._col = col;
    this._row = row;
    this._data = new List<T>(this._col * this._row);
    resetMatrix(value);
  }

  void resetMatrix(T value) {
    for(int i = 0; i < this._data.length; ++i) {
      this._data[i] = value;
    }
  }

  void insert(int x, int y, T value){
    this._data[y * this._col +x]= value;
  }

  T getValue(int x, int y){
    return this._data[y * this._col +x];
  }

  void addValue(int x, int y, T value) {
    insert(x, y, getValue(x, y) + value);
  }

  T getDataValue(int i) {
    return this._data[i];
  }

  void setDataValue(int i, T value) {
    this._data[i] = value;
  }

  int get size => this._data.length;
  int get cols => _col;
  int get rows => _row;
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