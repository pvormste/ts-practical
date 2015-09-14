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
  Image methodNonParametricSampling(Image inputImg, Image synImg, int scaler, int patchSize, bool singleResolution) {
    // Keep rotations saved
    List<Image> inputImagesRotated = new List<Image>();
    inputImagesRotated.add(inputImg);
    inputImagesRotated.add(copyRotate(inputImg, 90));
    inputImagesRotated.add(copyRotate(inputImg, 180));
    inputImagesRotated.add(copyRotate(inputImg, 270));

    // HalfPatch
    int halfPatchSize = patchSize ~/ 2;

    // Patches
    int usableInputHeight = inputImg.height - patchSize + 1;
    int usableInputWidth = inputImg.width - patchSize + 1;
    //int numInputPatches  = usableInputHeight * usableInputWidth;

    // Syn Image
    if(singleResolution) {
      synImg = copyResize(inputImg, inputImg.width * scaler, inputImg.height * scaler);
    }
    else {
      synImg = copyResize(synImg, inputImg.width * scaler, inputImg.height * scaler);
    }

    int rowsSynPatch = (((synImg.height - patchSize) / halfPatchSize).floor() + 1).toInt();
    int colsSynPatch = (((synImg.width - patchSize) / halfPatchSize).floor() + 1).toInt();
    synImg = copyResize(synImg, (colsSynPatch - 1) * halfPatchSize + patchSize, (rowsSynPatch - 1) * halfPatchSize + patchSize);

    // Make SynImage ugly if ther is no valuable pixel data
    if(singleResolution) {
      for(int i = 0; i < synImg.data.length; ++i) {
        synImg.data[i] = NON_PARAMETRIC_UGLY;
      }
    }

    int x_start = 0;
    int y_start = 0;

    // Initial copy of a random patch (starting point) if single resolution
    if(singleResolution){
      Random rand = new Random();
      copyInto(synImg, inputImg, dstX: 0, dstY: 0, srcX: rand.nextInt(usableInputWidth), srcY: rand.nextInt(usableInputHeight), srcW: patchSize, srcH: patchSize);
      x_start = patchSize;
      y_start = patchSize;
    }



    // Now fill every new pixel in the upper part
    for(int x = x_start; x < synImg.width; ++x) {
      print("Calculating col ${x - x_start +1} of ${synImg.width - x_start}");

      for(int y = 0; y < patchSize; ++y) {
        // Create the comparison Mask for this pixel
        List<ComparisonMaskElement> comparisonMask = getComparisonMask(synImg, new Vector2(x, y), patchSize, halfPatchSize, NON_PARAMETRIC_UGLY);

        // Find the patch with most similarity
        Vector3 mostSimilarPatchPosition = findCoherentPatch(inputImagesRotated, comparisonMask, patchSize, halfPatchSize);
        synImg.setPixel(x, y, inputImagesRotated[mostSimilarPatchPosition.rotation].getPixel(mostSimilarPatchPosition.x + halfPatchSize, mostSimilarPatchPosition.y + halfPatchSize));

      }
    }

    //now fill every pixel i the lower part
    for(int y = y_start; y < synImg.height; ++y) {
      print("Calculating row ${y - y_start +1} of ${synImg.height - y_start}");

      for(int x = 0; x < synImg.width; ++x) {
        // Create the comparison Mask for this pixel
        List<ComparisonMaskElement> comparisonMask = getComparisonMask(synImg, new Vector2(x, y), patchSize, halfPatchSize, NON_PARAMETRIC_UGLY);

        // Find the patch with most similarity
        Vector3 mostSimilarPatchPosition = findCoherentPatch(inputImagesRotated, comparisonMask, patchSize, halfPatchSize);
        synImg.setPixel(x, y, inputImagesRotated[mostSimilarPatchPosition.rotation].getPixel(mostSimilarPatchPosition.x + halfPatchSize, mostSimilarPatchPosition.y + halfPatchSize));
      }
    }

    return synImg;
  }

  // ==== Multiresolution
  Image methodMultiresolution(int scaler, int patchSize, int maxShift) {

    bool  firstShift = true;
    Image newSynImg = null;

    for(int shift = maxShift; shift >= 0; --shift) {
      // Shrink input image
      Image inputImage_small = copyResize(inputImage, inputImage.width >> shift, inputImage.height >> shift);

      // Calculate synImage /4
      print("==:  Calculate image shifted by ${shift}");

      newSynImg = methodNonParametricSampling(inputImage_small, newSynImg, scaler, patchSize, firstShift);

      if(firstShift)
      {
        firstShift = false;
      }


    }

    return newSynImg;

  }

  //##########################
  // Helper functions
  //##########################

  List<ComparisonMaskElement> getComparisonMask(Image synImg,Vector2 pixelPosition, int patchSize, int halfPatchSize, int bgColor) {
    // Mask contains patchSize * patchSize comparable pixels
    List<ComparisonMaskElement> comparisonMask = new List<ComparisonMaskElement>(patchSize * patchSize);

    int i = 0;

    // Mark the known pixels
    for(int x = pixelPosition.x - halfPatchSize; x < pixelPosition.x + halfPatchSize; ++x) {
      for(int y = pixelPosition.y - halfPatchSize; y < pixelPosition.y + halfPatchSize; ++y) {

        int pixelColor = synImg.getPixel(x, y);

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

  Vector3 findCoherentPatch(List<Image> rotatedImages, List<ComparisonMaskElement> comparisonMask, int patchSize, int halfPatchSize) {
    Vector3 bestPatchPosition = new Vector3.fromVector2(new Vector2.Zero(), 0);
    int bestPatchError = 600000000000;

    int patchError = 0;
    int i = 0;


    for(int rot = 0; rot < rotatedImages.length; ++rot) {
      // Check every possible patch
      for(int y = 0; y < rotatedImages[rot].height - patchSize; ++y) {
        for(int x = 0; x < rotatedImages[rot].width - patchSize; ++x) {

          // Patch error for this patch
          patchError = 0;
          i = 0;

          // Check every pixel in this patch
          for(int patchPixelY = y; patchPixelY < y + patchSize; ++patchPixelY) {

            // Dont go outside the image
            if(patchPixelY >= rotatedImages[rot].height)
              continue;

            for(int patchPixelX = x; patchPixelX < x + patchSize; ++patchPixelX) {

              // Dont go outside the image
              if(patchPixelX >= rotatedImages[rot].width)
                continue;

              // Check if the mask allow comparison for this pixel
              if(comparisonMask[i].isComparable && comparisonMask[i].color != -1) {
                int tempColor = rotatedImages[rot].getPixel(patchPixelX, patchPixelY);
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
            bestPatchPosition = new Vector3(x, y, rot);
          }

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

