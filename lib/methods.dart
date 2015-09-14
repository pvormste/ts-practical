library texturesynthesis.methods;

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

  // ==== Non Parametric Sampling
  Image methodNonParametricSampling(Image inputImg, Image synImg, int scaler, int patchSize) {
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

    // Now fill every new pixel in the upper part
    for(int x = patchSize; x < synImage.width; ++x) {
      print("Calculating col ${x - patchSize +1} of ${synImage.width - patchSize}");

      for(int y = 0; y < patchSize; ++y) {

        // Create the comparison Mask for this pixel
        List<ComparisonMaskElement> comparisonMask = getComparisonMask(new Vector2(x, y), patchSize, halfPatchSize, NON_PARAMETRIC_UGLY);

        // Find the patch with most similarity
        Vector2 mostSimilarPatchPosition = findCoherentPatch(comparisonMask, patchSize, halfPatchSize);
        synImage.setPixel(x, y, inputImage.getPixel(mostSimilarPatchPosition.x + halfPatchSize, mostSimilarPatchPosition.y + halfPatchSize));

        //synImage.setPixelRGBA(x, y, 0, 0, 255);
      }
    }

    //now fill every pixel i the lower part
    for(int y = patchSize; y < synImage.height; ++y) {
      print("Calculating row ${y - patchSize +1} of ${synImage.height - patchSize}");

      for(int x = 0; x < synImage.width; ++x) {
        // Create the comparison Mask for this pixel
        List<ComparisonMaskElement> comparisonMask = getComparisonMask(new Vector2(x, y), patchSize, halfPatchSize, NON_PARAMETRIC_UGLY);

        // Find the patch with most similarity
        Vector2 mostSimilarPatchPosition = findCoherentPatch(comparisonMask, patchSize, halfPatchSize);
        synImage.setPixel(x, y, inputImage.getPixel(mostSimilarPatchPosition.x + halfPatchSize, mostSimilarPatchPosition.y + halfPatchSize));
      }
    }

    return synImg;
  }

  // ==== Multiresolution
  void methodMultiresolution(int scaler, int patchSize) {

    // Shrink input image
    inputImage = copyResize(inputImage, inputImage.width >> 2, inputImage.height >> 2);

    // Calculate synImage /4
    print("==:  Calculate 1/4 of image");
    methodNonParametricSampling(scaler, patchSize);

    synImage = copyResize(synImage, synImage.width << 2, synImage.height << 2);
  }

  //##########################
  // Helper functions
  //##########################

  List<ComparisonMaskElement> getComparisonMask(Vector2 pixelPosition, int patchSize, int halfPatchSize, int bgColor) {
    // Mask contains patchSize * patchSize comparable pixels
    List<ComparisonMaskElement> comparisonMask = new List<ComparisonMaskElement>(patchSize * patchSize);

    int i = 0;

    // Mark the known pixels
    for(int x = pixelPosition.x - halfPatchSize; x < pixelPosition.x + halfPatchSize; ++x) {
      for(int y = pixelPosition.y - halfPatchSize; y < pixelPosition.y + halfPatchSize; ++y) {

        int pixelColor = synImage.getPixel(x, y);

        // pixel is outside image or has color of background
        if( pixelColor == 0 || pixelColor == bgColor) {
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
    int bestPatchError = 600000000000;

    int patchError = 0;
    int i = 0;

    // Check every possible patch
    for(int y = 0; y < inputImage.height - patchSize; ++y) {
      for(int x = 0; x < inputImage.width - patchSize; ++x) {

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


  // ==== Starter function
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

}

