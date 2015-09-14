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

  // Invoke class
  Texturesynthesis ts = new Texturesynthesis();

  // Read image
  ts.inputImage = decodeImage(new Io.File(inputImage).readAsBytesSync());

  // Output image
  Image output = null;

  // Select method
  switch(method) {
    case 0:
      ts.methodStarter(2, patchSize, patchSize >> 1);
      break;
    case 1:
      output = ts.methodNonParametricSampling(ts.inputImage, ts.synImage, 2, patchSize, true);
      break;
    case 2:
      output = ts.methodMultiresolution(2, patchSize);
      break;
  }

  // Write file
  new Io.File(outputImage)
    ..writeAsBytesSync(encodePng(output));
}