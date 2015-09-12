library texturesynthesis.methods;

import 'dart:html';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart';

part 'structures.dart';

class Texturesynthesis {
  // Statics
  static final int NON_PARAMETRIC_UGLY = 4294620397;

  // Input image
  Image inputImage;
  Image synImage;

  void methodNonParametricSampling(int scaler, int patchSize) {
    // HalfPatch
    int halfPatchSize = patchSize ~/ 2;

    // Patches
    int usableInputHeight = inputImage.height - patchSize + 1;
    int usableInputWidth = inputImage.width - patchSize + 1;
    int numInputPatches  = usableInputHeight * usableInputWidth;

    // Syn Image
    synImage = copyResize(inputImage, inputImage.width * scaler, inputImage.height * scaler);
    int rowsSynPatch = (((synImage.height - patchSize) / halfPatchSize).floor() + 1).toInt();
    int colsSynPatch = (((synImage.width - patchSize) / halfPatchSize).floor() + 1).toInt();
    synImage = copyResize(synImage, (colsSynPatch - 1) * halfPatchSize + patchSize, (rowsSynPatch - 1) * halfPatchSize + patchSize);

    // Make SynImage ugly
    for(int i = 0; i < synImage.data.length; ++i) {
      synImage.data[i] = NON_PARAMETRIC_UGLY;
    }

    // Initial copy of a random patch (starting point)
    Random rand = new Random();
    //print("${synImage.getPixel(-1,-5)}");
    //copyPatch(new Vector2(rand.nextInt(usableInputWidth), rand.nextInt(usableInputHeight)), new Vector2.Zero(), patchSize, usableInputHeight);
    copyInto(synImage, inputImage, dstX: 0, dstY: 0, srcX: rand.nextInt(usableInputWidth), srcY: rand.nextInt(usableInputHeight), srcW: patchSize, srcH: patchSize);

    // Now fill every new pixel
    for(int x = patchSize; x < synImage.width; ++x) {
      for(int y = 0; y < patchSize; ++y) {

        // Create the comparison Mask for this pixel
        List<ComparisonMaskElement> comparisonMask = getComparisonMask(new Vector2(x, y), patchSize, halfPatchSize, NON_PARAMETRIC_UGLY);

        // Find the patch with most similarity
        Vector2 mostSimilarPatchPosition = findCoherentPatch(comparisonMask, patchSize, halfPatchSize);
        synImage.setPixel(x, y, inputImage.getPixel(mostSimilarPatchPosition.x + halfPatchSize, mostSimilarPatchPosition.y + halfPatchSize));

        //synImage.setPixelRGBA(x, y, 0, 0, 255);
      }
    }

    //getComparisonMask(new Vector2(patchSize, 0), patchSize, halfPatchSize, NON_PARAMETRIC_UGLY);
  }

  List<ComparisonMaskElement> getComparisonMask(Vector2 pixelPosition, int patchSize, int halfPatchSize, int bgColor) {
    // Mask contains patchSize * patchSize comparable pixels
    List<ComparisonMaskElement> comparisonMask = new List<ComparisonMaskElement>(patchSize * patchSize);

    int i = 0;

    // Mark the known pixels
    for(int y = pixelPosition.y - halfPatchSize; y < pixelPosition.y + halfPatchSize; ++y) {
      for(int x = pixelPosition.x - halfPatchSize; x < pixelPosition.x + halfPatchSize; ++x) {
        int pixelColor = synImage.getPixel(x, y);

        // pixel is outside image or has color of background
        if(pixelColor == 0 || pixelColor == bgColor) {
          comparisonMask[i] = new ComparisonMaskElement.notAllowed();
        }
        // pixel
        else {
          comparisonMask[i] = new ComparisonMaskElement.isAllowed(pixelColor);
        }

        //print("Position: ${x} x ${y} : Color: ${synImage.getPixel(x, y)} || ${comparisonMask[i]}");
        ++i;
      }
    }

    return comparisonMask;
  }

  Vector2 findCoherentPatch(List<ComparisonMaskElement> comparisonMask, int patchSize, int halfPatchSize) {
    Vector2 bestPatchPosition = new Vector2.Zero();
    int bestPatchError = 1000;

    int patchError = 0;
    int i = 0;

    // Check every possible patch
    for(int y = 0; y < inputImage.height - halfPatchSize; ++y) {
      for(int x = 0; x < inputImage.width- halfPatchSize; ++x) {

        // Patch error for this patch
        patchError = 0;
        i = 0;

        // Check every pixel in this patch
        for(int patchPixelY = y; patchPixelY < y + patchSize; ++patchPixelY) {

          // Dont go outside the image
          if(patchPixelY >= inputImage.height)
            continue;

          for(int patchPixelX = x; patchPixelX < x + patchSize; ++patchPixelX) {

            // Dont go outside the image
            if(patchPixelX >= inputImage.width)
              continue;

            // Check if the mask allow comparison for this pixel
            if(comparisonMask[i].isComparable && comparisonMask[i].color != -1) {
              int tempColor = inputImage.getPixel(patchPixelX, patchPixelY);
              RGB inputPixelColor = new RGB(getRed(tempColor), getGreen(tempColor), getBlue(tempColor));

              tempColor = comparisonMask[i].color;
              RGB synPixelColor = new RGB(getRed(tempColor), getGreen(tempColor), getBlue(tempColor));

              int difference = RGB.difference(inputPixelColor, synPixelColor);
              patchError += difference;


            }

            ++i;
          }
        }

        // Now check if this patch is better than the best one
        if(patchError < bestPatchError) {
          bestPatchError = patchError;
          bestPatchPosition = new Vector2(x, y);
        }



      }
    }

    return bestPatchPosition;

  }

  /*void copyPatch(Vector2 inputPosition, Vector2 synPosition, int patchSize, int usableInputHeight) {
    int offsetX = 0;
    int offsetY = 0;
    int i = 0;

    for(int y = synPosition.y; y < synPosition.y + patchSize; ++y) {
      for(int x = synPosition.x; x < synPosition.x + patchSize; ++x) {


        synImage.setPixel(x, y, inputImage.getPixel(inputPosition.x + offsetX, inputPosition.y + offsetY));

        ++i;
        offsetX = i % patchSize;
        offsetY = ((i - x) / patchSize).floor().toInt();
      }
    }
  }*/

  /*void methodNonParametricSampling(int scaler, int patchSize, int patchStride) {
    // Init patches
    int rowsInputPatch = inputImage.height - patchSize + 1;
    int colsInputPatch = inputImage.width - patchSize + 1;
    int numInputPatch = rowsInputPatch * colsInputPatch;

    // Init syn image
    synImage = copyResize(inputImage, inputImage.width * scaler, inputImage.height * scaler);
    int rowsSynPatch = (((synImage.height - patchSize) / patchStride).floor() + 1).toInt();
    int colsSynPatch = (((synImage.width - patchSize) / patchStride).floor() + 1).toInt();
    synImage = copyResize(synImage, (colsSynPatch - 1) * patchStride + patchSize, (rowsSynPatch - 1) * patchStride + patchSize);

    // Extract all patches of input image


    // Make SynImage ugly
    for(int i = 0; i < synImage.data.length; ++i) {
      synImage.data[i] = NON_PARAMETRIC_UGLY;
    }

    // Synthesis
    Random rand = new Random();
    for(int row = 0; row < rowsSynPatch; ++row) {
      for(int col = 0; col < colsSynPatch; ++col) {

        // Index of patch
        int idxInput = -1;
        int rowSyn = row * patchStride;
        int colSyn = col * patchStride;
        List<dynamic> halfPatchPixels = null;

        if(row == 0 && col == 0) {
          // First Patch
          idxInput  = rand.nextInt(numInputPatch);
          halfPatchPixels = copyPatch(synImage.width, patchSize, rowSyn, colSyn, idxInput, colsInputPatch);
        } else if(col > patchSize && row <= patchSize) {
          //idxInput =
        }









        // Current patch in output image
        /*int rowSyn = row * patchStride;
        int colSyn = col * patchStride;

        // Pich up a random patch from the input image
        int idxInput = rand.nextInt(numInputPatch);
        int rowInput = ((idxInput / colsInputPatch).floor()).toInt();
        int colInput = idxInput % colsInputPatch;
*/

      }
    }
  }

  List<dynamic> copyPatch(int width, int patchSize, int rowSyn, int colSyn, int idxInput, int colsInputPatch) {
    int rowInput = ((idxInput / colsInputPatch).floor()).toInt();
    int colInput = idxInput % colsInputPatch;
    List<dynamic> colors =  new List<dynamic>();

    // Padding by directly copying pixels
    for(int row_ = 0; row_ <  patchSize; ++row_) {
      for(int col_ = 0; col_ < patchSize; ++col_) {
        synImage.setPixel(colSyn + col_, rowSyn + row_, inputImage.getPixel(colInput + col_, rowInput + row_));

        // Save RGB values
        if(col_ >= patchSize / 2) {
          Vector2 pos = new Vector2(colSyn + col_, rowSyn + row_);
          print("${pos.x} | ${pos.y} : " + (pos.y * (width) + pos.x).toString());
          RGB color = new RGB(synImage.data[pos.y * (width) + pos.x]);

         colors.add(new Pixel(pos, color));
        }
      }
    }

    return colors;
  }

  List<dynamic> extractInputRGB(int width, int height, int patchSize) {
    List<dynamic> patchList = new List<dynamic>();
    for(int row = 0; row < height - patchSize; ++row) {
      for(int col = 0; col < width - patchSize; ++col) {
        // Now for every pixel in  this patch
        Vector2 pos = new Vector2(col, row);
        List<dynamic> pixelList =  new List<dynamic>();

        for(int pixelY = pos.y; pixelY < pos.y + patchSize; ++pixelY) {
          for(int pixelX  =  pos.x; pixelX < pixelX + patchSize; ++pixelX) {
            Vector2 pixelPos = new Vector2(pixelX, pixelY);
            RGB pixelRGB =  new RGB(inputImage.data[pixelY * width + pixelX]);

            pixelList.add(new Pixel(pixelPos, pixelRGB));
          }
        }

        patchList.add(new Patch(pos, pixelList));
      }
    }

    return patchList;
  }*/

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



  void readImage(String name, ImageElement loader, ImageElement inputImageElement) {
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

        // Set input element
        inputImageElement.src = 'images/${name}';
        inputImageElement.width = inputImage.width;
        inputImageElement.height = inputImage.height;
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
    imgElement.width = synImage.width;
    imgElement.height = synImage.height;
  }
}

