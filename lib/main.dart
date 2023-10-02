import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PickedFile? _image;
  String resultMessage = ''; // To display the result message

  List<String> labels = [];

  @override
  void initState() {
    super.initState();
    // Load your TensorFlow Lite model and labels in the initState method
    loadModelAndLabels();
  }

  Future<void> loadModelAndLabels() async {
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
    );

    // Load labels from the labels.txt file
    final labelData = await rootBundle.loadString('assets/labels.txt');
    labels = labelData.split('\n');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Perform inference on the selected image
      runInference(pickedFile.path);
    }

    setState(() {
      _image = pickedFile != null ? PickedFile(pickedFile.path) : null;
    });
  }

  Future<void> runInference(String imagePath) async {
    final List<dynamic>? recognitions = await Tflite.runModelOnImage(
      path: imagePath,
      numResults: labels.length,
    );

    // Check if a house or part of a house is detected
    bool houseDetected = false;

    if (recognitions != null && recognitions.isNotEmpty) {
      for (final recognition in recognitions) {
        final int labelIndex = recognition['index'];
        final double confidence = recognition['confidence'];

        // Check if the label corresponds to "House" or "Part of House"
        if (labelIndex >= 0 && labelIndex < labels.length) {
          final String label =
              labels[labelIndex].split(' ')[1]; // Extract the label text

          if ((label == 'House' || label == 'Part of House') &&
              confidence >= 0.5) {
            houseDetected = true;
            break; // No need to continue checking if a house is detected
          }
        }
      }
    }

    // Set the result message based on the detection
    setState(() {
      if (houseDetected) {
        resultMessage = 'House or Part of House is detected.';
      } else {
        resultMessage = 'No house or part of a house detected.';
      }
    });
  }

  @override
  void dispose() {
    // Release the model resources when the widget is disposed
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('House Detection App'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _image == null
                  ? Text('No image selected.')
                  : Image.file(File(_image!.path)),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Select an Image'),
              ),
              SizedBox(height: 20), // Add spacing
              Text(resultMessage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
