import 'dart:html';
import 'package:texturesynthesis/methods.dart';
import 'package:texturesynthesis/html.dart';
import 'package:image/image.dart';

// HTML elements
ImageElement inputImageElement = querySelector('#input-img');
ImageElement imageLoaded = querySelector('#img-loaded');
SelectElement fileChooser = querySelector('#input-img-name');
SelectElement methodChooser =querySelector('#method-option');
ImageElement resultImage = querySelector('#result-img');

// Texture synthesis
Texturesynthesis ts;
Image synImg;


void  main() {
  // Init the main class
  ts = new Texturesynthesis();

  // Init webpage
  initGUI();
  finishLoading();
}

void initGUI() {
  fileChooser.onChange.listen((e) {
    if(fileChooser.value != "none") {
      // Load info of image
      imageLoaded.classes.clear();
      imageLoaded.classes.add('visible');
      imageLoaded.src = 'images/image-loader.gif';
      //inputImageElement.src = "images/${fileChooser.value}";

      // Read image
      readImageHTML(ts, fileChooser.value, imageLoaded, inputImageElement);
    }
    else {
      // Reset
      imageLoaded.src = '';
      inputImageElement.src = '';
    }
  });

  methodChooser.onChange.listen((e) {
    if(methodChooser.value != "none" && ts.inputImage != null) {
      // Select method
      switch(methodChooser.value) {
        case "0":
          synImg = ts.methodStarter(ts.inputImage, 2, 32, 16);
          break;
        case "1":
          synImg = ts.methodNonParametricSampling(ts.inputImage, null, 2, 32, true);
          break;
      }

      // Show output image
      showOutputImageHTML(synImg, resultImage);
    }
  });
}

void finishLoading() {
  DivElement loader = querySelector('#loading');
  DivElement content = querySelector('#content');

  loader.remove();

  content.classes.clear();
  content.classes.add("visible");

}