library texturesynthesis.methods;

import 'dart:html';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart';

class Texturesynthesis {
  // Input image
  Image inputImage;
  Image synImage;

  void methodStarter(int scaler, int patchSize, int patchStride) {
    // Init patches
    int rowsInputPatch = inputImage.height - patchSize + 1;
    int colsInputPatch = inputImage.width - patchSize + 1;
    int numInputPatch = rowsInputPatch * colsInputPatch;

    // Init syn image
    synImage = copyResize(inputImage, inputImage.width * scaler, inputImage.height * scaler);
    int rowsSynPatch = (((synImage.height - patchSize) / patchStride).floor() + 1).toInt();
    int colsSynPatch = (((synImage.width - patchSize) / patchStride).floor() + 1).toInt();
    synImage = copyResize(synImage, (colsSynPatch - 1) * patchStride + patchSize, (rowsSynPatch - 1) * patchStride + patchSize);

    // Synthesis
    Random rand = new Random();
    for(int row = 0; row < rowsSynPatch; ++row) {
      for(int col = 0; col < colsSynPatch; ++col) {
        // Current patch in output image
        int rowSyn = row * patchStride;
        int colSyn = col * patchStride;

        // Pich up a random patch from the input image
        int idxInput = rand.nextInt(numInputPatch);
        int rowInput = ((idxInput / colsInputPatch).floor()).toInt();
        int colInput = idxInput % colsInputPatch;

        // Padding by directly copying pixels
        for(int row_ = 0; row_ <  patchSize; ++row_) {
          for(int col_ = 0; col_ < patchSize; ++col_) {
            synImage.setPixel(colSyn + col_, rowSyn + row_, inputImage.getPixel(colInput + col_, rowInput + row_));
          }
        }
      }
    }
}

  void readImage(String name, ImageElement loader) {
    HttpRequest request = new HttpRequest();
    request.open('GET', 'images/${name}');
    request.overrideMimeType('text\/plain; charset=x-user-defined');
    request.onLoadEnd.listen((e) {
      if(request.status == 200){
        // Convert the responseText to a byte list.
        var bytes = request.responseText.split('').map((e){
          return new String.fromCharCode(e.codeUnitAt(0) & 0xff);
        }).join('').codeUnits;

        // Save image
        inputImage = decodeImage(bytes);

        // Visual feedback
        loader.src = 'images/success.png';
      }
      else{
        loader.src = 'images/fail.png';
        print('${name} was NOT found');
      }
    });

    request.send('');
  }

  void showOutputImage(ImageElement imgElement) {
    var png = encodePng(synImage);
    var png64 = CryptoUtils.bytesToBase64(png);
    imgElement.src = 'data:image/png;base64,${png64}';
  }
}

