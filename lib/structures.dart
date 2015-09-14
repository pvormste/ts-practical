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

class Pixel {
  Pixel(Vector2 position, RGB rgb);
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