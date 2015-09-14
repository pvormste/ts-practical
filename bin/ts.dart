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

  // Select method
  switch(method) {
    case 0:
      ts.methodStarter(2, patchSize, patchSize >> 1);
      break;
    case 1:
      ts.methodNonParametricSampling(2, patchSize);
  }

  // Write file
  new Io.File(outputImage)
    ..writeAsBytesSync(encodePng(ts.synImage));
}