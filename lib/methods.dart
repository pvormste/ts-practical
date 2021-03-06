library texturesynthesis.methods;

import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart';

part 'structures.dart';

enum MultiResMethod{
  nonParametric,
  exampleBased
}

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
  Image methodMultiresolution(int scaler, int patchSize, int maxShift, MultiResMethod method) {

    bool  firstShift = true;
    Image newSynImg = null;

    for(int shift = maxShift; shift >= 0; --shift) {
      // Shrink input image
      Image inputImage_small = copyResize(inputImage, inputImage.width >> shift, inputImage.height >> shift);

      // Calculate synImage /4
      print("==:  Calculate image shifted by ${shift}");

      switch (method){
        case MultiResMethod.nonParametric:
          newSynImg = methodNonParametricSampling(inputImage_small, newSynImg, scaler, patchSize, firstShift);
          break;
        case MultiResMethod.exampleBased:
          newSynImg = methodExampleBased(inputImage_small, newSynImg, scaler, patchSize, firstShift);
          break;
      }

      if(firstShift)
      {
        firstShift = false;
      }


    }

    return newSynImg;

  }

  // ==== Example Based
  Image methodExampleBased(Image inputImg, Image synImg, int scaler, int patchSize, [bool singleResolution = false]) {

    if(singleResolution) {
      // Resizing synImage, noising
      synImg = copyResize(inputImg, inputImg.width * scaler, inputImg.height * scaler);
      synImg = noise(synImg, 5000.0);
    }
    else {
      synImg = copyResize(synImg, inputImg.width * scaler, inputImg.height * scaler);
    }

    // .
    int yMax = synImg.height - patchSize +1;
    int xMax = synImg.width - patchSize +1;
    int patchNum = yMax * xMax;

    // Iterations
    int iter = 0;
    int numIter = 15;

    //Matrix for saving best matching patches
    Matrix <Vector3> bestMatch = new Matrix<Vector3>(xMax, yMax);

    // Matrix for saving the color values
    Matrix <RGB> colorMatrix = new Matrix(synImg.width, synImg.height);


    // Matrix for counting the overlap
    Matrix <int> countMatrix = new Matrix.fillOnCreate(synImg.width, synImg.height, 1);

    // List for the input image for the coherent method
    List<Image> input = new List<Image>()
      ..add(inputImg);

    // Creating the Mask for comparison
    List<ComparisonMaskElement> mask = new List<ComparisonMaskElement>(patchSize*patchSize);

    // overlap
    int overlap = 3;

    while(iter < numIter) {
      // Setup Color Matrix
      for(int y = 0; y < synImg.height; ++y) {
        for(int x = 0; x < synImg.width; ++x) {
          int color = synImg.getPixel(x, y);
          int red = getRed(color);
          int green = getGreen(color);
          int blue = getBlue(color);

          colorMatrix.insert(x, y, new RGB(red, green, blue));
        }
      }

      // Going through the synImage finding every patch
      for (int y = 0; y < yMax; y = y + overlap) {
        for (int x = 0; x < xMax; x = x + overlap) {
          int currPatch = y * xMax + x;

          if (currPatch % 100 == 0)
            print("Iteration: ${iter+1}/${numIter} - Calculating patch ${(currPatch/overlap).truncate()} of ${(patchNum/overlap).truncate()}");

          // Creating ComparisonMask
          int i = 0;
          for (int patchY = y; patchY < y + patchSize; ++patchY) {
            for (int patchX = x; patchX < x + patchSize; ++patchX) {
              mask[i] = new ComparisonMaskElement.isAllowed(synImg.getPixel(patchX, patchY));
              ++i;
            }
          }
          bestMatch.insert(x, y, findCoherentPatch(input, mask, patchSize, patchSize >> 1, withRotation:false));
        }
      }

      for (int y = 0; y < yMax; y = y + overlap) {
        for (int x = 0; x < xMax; x = x + overlap) {
          Vector3 posPatchInInput = bestMatch.getValue(x, y);

          for(int patchY = 0; patchY < patchSize; ++patchY){
            for(int patchX = 0; patchX < patchSize; ++patchX){

              int color = inputImg.getPixel(posPatchInInput.x + patchX, posPatchInInput.y + patchY);

              int red = getRed(color);
              int green = getGreen(color);
              int blue = getBlue(color);


              int newRed = colorMatrix.getValue(x + patchX, y + patchY).red + red;
              int newGreen = colorMatrix.getValue(x + patchX, y + patchY).green + green;
              int newBlue = colorMatrix.getValue(x + patchX, y + patchY).blue + blue;

              int newCount = countMatrix.getValue(x + patchX, y + patchY) + 1;

             // print("${x+patchX}:${y+patchY} ${newCount}");

              colorMatrix.insert(x + patchX, y + patchY, new RGB(newRed, newGreen, newBlue));
              countMatrix.insert(x + patchX, y + patchY, newCount);
            }
          }
        }
      }

      for(int i = 0; i < colorMatrix.size; ++i) {

        RGB currentColor = colorMatrix.getDataValue(i);
        int divider = countMatrix.getDataValue(i);
        //print("${i}: ${divider}");
        //if(divider ==  0) {
         // print("${i}: ${divider}");
          currentColor.red ~/= divider;
          currentColor.green ~/= divider;
          currentColor.blue ~/= divider;
        //}


        colorMatrix.setDataValue(i,  currentColor);
      }

      for (int y = 0; y < synImg.height; ++y) {
        for (int x = 0; x < synImg.width; ++x) {
          synImg.setPixelRGBA(x, y, colorMatrix.getValue(x, y).red, colorMatrix.getValue(x, y).green, colorMatrix.getValue(x, y).blue);
        }
      }



      //colorMatrix.resetMatrix(new RGB(0, 0, 0));
      countMatrix.resetMatrix(1);
      print("####  Iteration ${iter +1} finished!  ####################################");
      ++iter;
    }

    return synImg;
  }

  // ==== Example-based with guidance
  Image methodExampleBasedWithGuidance(Image inputImg, Image guidance, Image synImg, int scaler, int patchSize, [bool singleResolution = false]) {

    if(singleResolution) {
      // Resizing synImage, noising
      synImg = copyResize(inputImg, inputImg.width * scaler, inputImg.height * scaler);
      synImg = noise(synImg, 5000.0);
    }
    else {
      synImg = copyResize(synImg, inputImg.width * scaler, inputImg.height * scaler);
    }

    // Syn Vars
    int yMaxSyn = synImg.height - patchSize +1;
    int xMaxSyn = synImg.width - patchSize +1;
    int patchNumSyn = yMaxSyn * xMaxSyn;

    // Guidance Vars
    int yMaxGuid = guidance.height - patchSize +1;
    int xMaxGuid = guidance.width - patchSize +1;
    int patchNumGuid = yMaxGuid * xMaxGuid;

    // Iterations
    int iter = 0;
    int numIter = 15;

    // overlap
    int overlap = 1;

    //Matrix for saving best matching patches
    Matrix <Vector3> bestMatch = new Matrix<Vector3>(xMaxSyn, yMaxSyn);

    // Matrix for saving the color values
    Matrix <RGB> colorMatrix = new Matrix(synImg.width, synImg.height);


    // Matrix for counting the overlap
    Matrix <int> countMatrix = new Matrix.fillOnCreate(synImg.width, synImg.height, 1);

    // Guidance Matrix
    Matrix<Vector3> guidanceMatches = new Matrix(guidance.width, guidance.height);

    // Creating the Mask for comparison
    List<ComparisonMaskElement> mask = new List<ComparisonMaskElement>(patchSize*patchSize);
    List<ComparisonMaskElement> guidanceMask = new List<ComparisonMaskElement>(patchSize*patchSize);

    // List for the input image for the coherent method
    List<Image> guidanceList = new List<Image>()
      ..add(guidance);

    // List for the input image for the coherent method
    List<Image> input = new List<Image>()
      ..add(inputImg);


    // Find b est matches for guidance (only once!!!!)
    for (int y = 0; y < yMaxGuid; y = y + overlap) {
      for (int x = 0; x < xMaxGuid; x = x + overlap) {
        int currPatch = y * xMaxGuid + x;

        if (currPatch % 100 == 0)
          print("Setting up patch ${(currPatch/overlap).truncate()} of ${(patchNumGuid/overlap).truncate()} guidance image");

        // Creating ComparisonMask
        int i = 0;
        for (int patchY = y; patchY < y + patchSize; ++patchY) {
          for (int patchX = x; patchX < x + patchSize; ++patchX) {
            guidanceMask[i] = new ComparisonMaskElement.isAllowed(guidance.getPixel(patchX, patchY));
            ++i;
          }
        }
        guidanceMatches.insert(x, y, findCoherentPatch(input, guidanceMask, patchSize, patchSize >> 1, withRotation:false));
      }
    }


    while(iter < numIter) {
      // Setup Color Matrix
      for(int y = 0; y < synImg.height; ++y) {
        for(int x = 0; x < synImg.width; ++x) {
          int color = synImg.getPixel(x, y);
          int red = getRed(color);
          int green = getGreen(color);
          int blue = getBlue(color);

          colorMatrix.insert(x, y, new RGB(red, green, blue));
        }
      }

      // Going through the synImage finding every patch
      for (int y = 0; y < yMaxSyn; y = y + overlap) {
        for (int x = 0; x < xMaxSyn; x = x + overlap) {
          int currPatch = y * xMaxSyn + x;

          if (currPatch % 100 == 0)
            print("Iteration: ${iter+1}/${numIter} - Calculating patch ${(currPatch/overlap).truncate()} of ${(patchNumSyn/overlap).truncate()}");

          // Creating ComparisonMask
          int i = 0;
          for (int patchY = y; patchY < y + patchSize; ++patchY) {
            for (int patchX = x; patchX < x + patchSize; ++patchX) {
              mask[i] = new ComparisonMaskElement.isAllowed(synImg.getPixel(patchX, patchY));
              ++i;
            }
          }
          bestMatch.insert(x, y, findCoherentPatch(input, mask, patchSize, patchSize >> 1, withRotation:false));
        }
      }

      for (int y = 0; y < yMaxSyn; y = y + overlap) {
        for (int x = 0; x < xMaxSyn; x = x + overlap) {
          Vector3 posPatchInInput = bestMatch.getValue(x, y);
          Vector3 posPatchInInputGuidance = guidanceMatches.getValue(x, y); // Guidance

          for(int patchY = 0; patchY < patchSize; ++patchY){
            for(int patchX = 0; patchX < patchSize; ++patchX){

              int color = inputImg.getPixel(posPatchInInput.x + patchX, posPatchInInput.y + patchY);
              int colorGuidance = inputImg.getPixel(posPatchInInputGuidance.x + patchX, posPatchInInputGuidance.y + patchY);// Guidance

              int red = ((getRed(color) + getRed(colorGuidance)) / 2).truncate(); // Guidance
              int green =  ((getGreen(color) + getGreen(colorGuidance)) / 2).truncate(); // Guidance
              int blue =  ((getBlue(color) + getBlue(colorGuidance)) / 2).truncate(); // Guidance


              int newRed = colorMatrix.getValue(x + patchX, y + patchY).red + red;
              int newGreen = colorMatrix.getValue(x + patchX, y + patchY).green + green;
              int newBlue = colorMatrix.getValue(x + patchX, y + patchY).blue + blue;

              int newCount = countMatrix.getValue(x + patchX, y + patchY) + 1;

              // print("${x+patchX}:${y+patchY} ${newCount}");

              colorMatrix.insert(x + patchX, y + patchY, new RGB(newRed, newGreen, newBlue));
              countMatrix.insert(x + patchX, y + patchY, newCount);
            }
          }
        }
      }

      for(int i = 0; i < colorMatrix.size; ++i) {

        RGB currentColor = colorMatrix.getDataValue(i);
        int divider = countMatrix.getDataValue(i);
        //print("${i}: ${divider}");
        //if(divider ==  0) {
        // print("${i}: ${divider}");
        currentColor.red ~/= divider;
        currentColor.green ~/= divider;
        currentColor.blue ~/= divider;
        //}


        colorMatrix.setDataValue(i,  currentColor);
      }

      for (int y = 0; y < synImg.height; ++y) {
        for (int x = 0; x < synImg.width; ++x) {
          synImg.setPixelRGBA(x, y, colorMatrix.getValue(x, y).red, colorMatrix.getValue(x, y).green, colorMatrix.getValue(x, y).blue);
        }
      }



      //colorMatrix.resetMatrix(new RGB(0, 0, 0));
      countMatrix.resetMatrix(1);
      print("####  Iteration ${iter +1} finished!  ####################################");
      ++iter;
    }

    return synImg;
  }

  // ==== Bidirectional Similarity
  Image methodBidirectional(Image inputImg, Image synImg, int iterations, int patchSize) {

    Image tempImg = copyResize(inputImg, inputImg.width, inputImg.height);

    int yMaxInput = inputImg.height - patchSize +1;
    int xMaxInput = inputImg.width - patchSize +1;
    int inputPatchNum = yMaxInput * xMaxInput;

    for(int i = 0; i < iterations; ++i) {
      print("Iteration ${i + 1} of ${iterations}");

      int yMaxSyn = synImg.height - patchSize +1;
      int xMaxSyn = synImg.width - patchSize +1;
      int synPatchNum = yMaxSyn * xMaxSyn;

      // Resize to a size of 90%
      synImg = copyResize(inputImg, (tempImg.width * 0.9).truncate(), (tempImg.height * 0.9).truncate());

      for (int y = 0; y < yMaxSyn; ++y){
        for (int x = 0; x < xMaxSyn; ++x){

        }
      }


      // inputImg is now the synImg
      tempImg = synImg;
    }

    return synImg;
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

  Vector3 findCoherentPatch(List<Image> rotatedImages, List<ComparisonMaskElement> comparisonMask, int patchSize, int halfPatchSize, {withRotation: true}) {
    Vector3 bestPatchPosition = new Vector3.fromVector2(new Vector2.Zero(), 0);
    int bestPatchError = 600000000000;

    int patchError = 0;
    int i = 0;

    int rotMax = 1;

    if(withRotation) {
      rotMax = rotatedImages.length;
    }

    for(int rot = 0; rot < rotMax; ++rot) {
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
  Image methodStarter(Image inputImg, int scaler, int patchSize, int patchStride) {
    Image synImg = null;

    // Init patches
    int rowsInputPatch = inputImg.height - patchSize + 1;
    int colsInputPatch = inputImg.width - patchSize + 1;
    int numInputPatch = rowsInputPatch * colsInputPatch;

    // Init syn image
    synImg = copyResize(inputImg, inputImg.width * scaler, inputImg.height * scaler);
    int rowsSynPatch = (((synImg.height - patchSize) / patchStride).floor() + 1).toInt();
    int colsSynPatch = (((synImg.width - patchSize) / patchStride).floor() + 1).toInt();
    synImg = copyResize(synImg, (colsSynPatch - 1) * patchStride + patchSize, (rowsSynPatch - 1) * patchStride + patchSize);

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
            synImg.setPixel(colSyn + col_, rowSyn + row_, inputImg.getPixel(colInput + col_, rowInput + row_));
          }
        }
      }
    }

    return synImg;
  }

}

