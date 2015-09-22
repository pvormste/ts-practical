library texturesynthesis.optimized;

import 'package:image/image.dart';
import 'kdtree/kdtree.dart';
import 'methods.dart';

Image optimizedExampleBased(Image inputImg, Image synImg, int scaler, int patchSize) {

  // Settings
  int numIter = 20;
  int overlap = 4;

  // Setup Dimensions
  DIMENSIONS = patchSize * patchSize * 3;

  // Single and  Multiresolution
  if(synImg == null) {
    // Resizing synImage, noising
    synImg = copyResize(inputImg, inputImg.width * scaler, inputImg.height * scaler);
    //synImg = noise(synImg, 100.0);
  }
  else {
    synImg = copyResize(synImg, inputImg.width * scaler, inputImg.height * scaler);
  }

  // Input vars
  int yMaxInp = inputImg.height - patchSize +1;
  int xMaxInp = inputImg.width - patchSize +1;
  int patchNumInp = yMaxInp * xMaxInp;

  // Syn Vars
  int yMaxSyn = synImg.height - patchSize +1;
  int xMaxSyn = synImg.width - patchSize +1;
  int patchNumSyn = yMaxSyn * xMaxSyn;

  // Now set up everything for kd tree
  List<VecMultiDimensionInt> patchList = new List(xMaxInp * yMaxInp);
  List<Vector2> posList = new List(xMaxInp * yMaxInp);

  int j = 0;
  for(int y = 0; y < yMaxInp; ++y) {
    for(int x = 0; x < xMaxInp; ++x) {
      int currPatch = y * xMaxInp + x;

      print('KDTREE-PHASE: Building patch ${currPatch+1} of ${patchNumInp}');

      VecMultiDimensionInt patchVec = new VecMultiDimensionInt(DIMENSIONS);
      int i = 0;

      for(int patchY = y; patchY < y + patchSize; ++patchY) {
        for(int patchX = x; patchX < x + patchSize; ++patchX) {
          int color = inputImg.getPixel(patchX, patchY);

          patchVec[i] = getRed(color);
          patchVec[i+1] = getGreen(color);
          patchVec[i+2] = getBlue(color);

          i += 3;
        }
      }

      // Add vector to list
      patchList[j] = patchVec;
      posList[j] = new Vector2(x, y);

      ++j;
    }
  }

  // BUILD KD TREE!!!
  KdTree tree = new KdTree.fromList(patchList, posList);
  print("========== END PHASE 1: KDTREE =========");

  // Matrices
  Matrix<Vector2> bestMatchingPatches = new Matrix(xMaxSyn, yMaxSyn);
  Matrix<RGB> colorMatrix = new Matrix(synImg.width, synImg.height);
  Matrix<int> countMatrix = new Matrix.fillOnCreate(synImg.width, synImg.height, 1);

  // Start iterations
  int iter = numIter;
  int iterI = 1;

  while(iter > 0) {

    print('ITERATION PHASE: ${iterI} of ${numIter}');

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


    // Time to compare
    for(int y = 0; y < yMaxSyn; y = y + overlap) {
      for(int x = 0; x < xMaxSyn; x = x + overlap) {
        VecMultiDimensionInt patchVec = new VecMultiDimensionInt(DIMENSIONS);

        int i = 0;

        for(int patchY = y; patchY < y + patchSize; ++patchY) {
          for(int patchX = x; patchX < x + patchSize; ++patchX) {
            int color = synImg.getPixel(patchX, patchY);

            patchVec[i] = getRed(color);
            patchVec[i+1] = getGreen(color);
            patchVec[i+2] = getBlue(color);

            // Add to count Matrix
            //int newCount = countMatrix.getValue(patchX, patchY) + 1;
            //countMatrix.insert(patchX, patchY, newCount);

            i += 3;
          }
        }

        KdNodeData nodeData = tree.nearest(patchVec);
        //bestMatchingPatches.insert(x, y, nodeData.tag);
        Vector2 bestMatch = nodeData.tag;
        //print('${bestMatch.x}:${bestMatch.y}');

        for(int patchY = 0; patchY < patchSize; ++patchY) {
          for(int patchX = 0; patchX < patchSize; ++patchX) {
            RGB colorMat = colorMatrix.getValue(x + patchX, y + patchY);
            int colorInp = inputImg.getPixel(bestMatch.x + patchX, bestMatch.y + patchY);
            //int colorSyn = synImg.getPixel(x + patchX, y + patchY);

            int redInp = getRed(colorInp);
            int greenInp = getGreen(colorInp);
            int blueInp =  getBlue(colorInp);

            //int redSyn = getRed(colorSyn);
            //int greenSyn = getGreen(colorSyn);
            //int blueSyn = getBlue(colorSyn);

            int redSyn = colorMat.red;
            int greenSyn = colorMat.green;
            int blueSyn = colorMat.blue;

            int newRed = (redInp + redSyn);
            int newGreen = (greenInp + greenSyn);
            int newBlue = (blueInp + blueSyn);

            colorMatrix.insert(x + patchX, y + patchY, new RGB(newRed, newGreen, newBlue));


            // Add to count Matrix
            int newCount = countMatrix.getValue(x + patchX, y +patchY) + 1;
            countMatrix.insert(x + patchX, y + patchY, newCount);

          }
        }
      }
    }

    // Copy colors
    for(int y = 0; y < synImg.height; ++y) {
      for(int x = 0; x < synImg.width; ++x) {
        RGB color = colorMatrix.getValue(x, y);
        int divider = countMatrix.getValue(x, y);

        int newRed = color.red ~/ divider;
        int newGreen = color.green ~/ divider;
        int newBlue = color.blue ~/ divider;

        int newColor = getColor(newRed, newGreen, newBlue);

        synImg.setPixel(x, y, newColor);
      }
    }

    countMatrix.resetMatrix(1);

    --iter;
    ++iterI;
  }

  print('========== END PHASE 2: ITERATION =========');



  return synImg;
}

Image optimizedMultiResolution(Image inputImg, int scaler, int patchSize, int maxShift) {

  bool  firstShift = true;
  Image newSynImg = null;

  for(int shift = maxShift; shift >= 0; --shift) {
    // Shrink input image
    Image inputImage_small = copyResize(inputImg, inputImg.width >> shift, inputImg.height >> shift);

    // Calculate synImage /4
    print("==:  Calculate image shifted by ${shift}");

    newSynImg = optimizedExampleBased(inputImage_small, newSynImg, scaler, patchSize);


    if(firstShift)
    {
      firstShift = false;
    }


  }

  return newSynImg;
}