part of texturesynthesis.methods;

class RGB {
  static final RED_SHIFT = 16777215;
  static final GREEN_SHIFT = 65535;
  static final BLUE_SHIFT = 255;

  static int difference(RGB valueA, RGB valueB) {
    int diffRed = (valueA.red - valueB.red).abs();
    int diffGreen =  (valueA.green - valueB.green).abs();
    int diffBlue = (valueA.blue - valueB.blue).abs();

    return (diffRed + diffGreen + diffBlue);
  }

  int red;
  int green;
  int blue;

  RGB(int value) {
    red = (value & RED_SHIFT) >> 8*2;
    green = (value & GREEN_SHIFT) >> 8;
    blue = value & BLUE_SHIFT;
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

class Patch {
  Vector2 position;
  List<dynamic> pixel;

  Patch(Vector2 position, List<dynamic> pixel) {
    this.position = position;
    this.pixel = pixel;
  }
}