import 'dart:io' as Io;
import 'package:image/image.dart';
import 'package:texturesynthesis/methods.dart';
import 'package:args/args.dart';


void main(List<String> args) {
  // Init Arg Parser
  final parser = new ArgParser();
  ArgResults argResults = parser.parse(args);

  // Extract commands
  int method = int.parse(argResults.arguments[0]);
  String inputImage = "web/images/${argResults.arguments[1]}";
  int patchSize = int.parse(argResults.arguments[2]);
  String outputImage = "web/images/${argResults.arguments[3]}";
  String guidanceImage = "";

  if(argResults.arguments.length > 4) {
    guidanceImage = "web/images/${argResults.arguments[4]}";
  }


  // Invoke class
  Texturesynthesis ts = new Texturesynthesis();

  // Read image
  ts.inputImage = decodeImage(new Io.File(inputImage).readAsBytesSync());

  Image guidance = null;
  if(argResults.arguments.length > 4) {
    guidance = decodeImage(new Io.File(guidanceImage).readAsBytesSync());
  }

  // Output image
  Image output = null;

  // save current time
  DateTime now = new DateTime.now();

  // Select method
  switch(method) {
    case 0:
      ts.methodStarter(2, patchSize, patchSize >> 1);
      break;
    case 1:
      output = ts.methodNonParametricSampling(ts.inputImage, ts.synImage, 2, patchSize, true);
      break;
    case 2:
      output = ts.methodMultiresolution(2, patchSize, 2, MultiResMethod.nonParametric);
      break;
    case 3:
      output = ts.methodExampleBased(ts.inputImage, ts.synImage, 2, patchSize, true);
      break;
    case 4:
      output = ts.methodMultiresolution(2, patchSize, 3, MultiResMethod.exampleBased);
      break;
    case 5:
      output = ts.methodExampleBasedWithGuidance(ts.inputImage, guidance, ts.synImage, 2, patchSize, true);
      break;
    case 6:
      output = ts.methodBidirectional(ts.inputImage, ts.synImage, 5, patchSize);
      break;
  }
  //print
  DateTime finishTime = new DateTime.now();
  print("Start: ${now} | End: ${finishTime} | Execution Time: ${finishTime.difference(now).inMinutes}");

  // Write file
  new Io.File(outputImage)
    ..writeAsBytesSync(encodePng(output));
}