library texturesynthesis.html;

import 'dart:html';
import 'package:image/image.dart';
import 'package:crypto/crypto.dart';
import 'package:texturesynthesis/methods.dart';


void readImageHTML(Texturesynthesis ts, String name, ImageElement loader, ImageElement inputImageElement) {
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
      ts.inputImage = decodeImage(bytes);

      // Visual feedback
      loader.src = 'images/success.png';

      // Set input element
      inputImageElement.src = 'images/${name}';
      inputImageElement.width = ts.inputImage.width;
      inputImageElement.height = ts.inputImage.height;
    }
    else{
      loader.src = 'images/fail.png';
      print('${name} was NOT found');
    }
  });

  request.send('');
}

void showOutputImageHTML(Image synImage, ImageElement imgElement) {
  var png = encodePng(synImage);
  var png64 = CryptoUtils.bytesToBase64(png);
  imgElement.src = 'data:image/png;base64,${png64}';
  imgElement.width = synImage.width;
  imgElement.height = synImage.height;
}