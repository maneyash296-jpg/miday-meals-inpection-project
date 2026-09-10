import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../data/network/meal_service.dart';

class MealCaptureScreen extends StatefulWidget {
  const MealCaptureScreen({super.key});

  @override
  State<MealCaptureScreen> createState() => _MealCaptureScreenState();
}

class _MealCaptureScreenState extends State<MealCaptureScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final MealService _mealService = MealService();
  bool _isAnalyzing = false;
  int _studentsServed = 0; // Updated by user before analysis

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  Future<void> _analyzeMeal() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    // Step 1: Create a meal session
    final meal = await _mealService.recordMealSession(
      studentsPresent: _studentsServed, // Assuming all present are served for demo
      studentsServed: _studentsServed,
    );

    if (meal == null) {
      if (!mounted) return;
      setState(() { _isAnalyzing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record meal session. Check backend connection.')),
      );
      return;
    }

    // Step 2: Analyze the image
    final analysis = await _mealService.analyzeMealImage(meal.id, _imageFile!.path);

    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
    });

    if (analysis != null) {
      // Pass the real analysis result to the analysis screen via route extra
      context.go('/teacher/analysis', extra: analysis);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to analyze meal image. Check backend connection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Camera preview
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              image: _imageFile != null
                  ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _imageFile == null
                ? const Center(
                    child: Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera),
                label: const Text('CAMERA'),
              ),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('GALLERY'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Metadata', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _metadataRow('School', 'PM POSHAN School'),
          _metadataRow('Date', DateTime.now().toLocal().toString().split(' ')[0]),
          _metadataRow('Time', TimeOfDay.now().format(context)),
          _metadataRow('GPS', 'Auto-detected on capture'),
          _metadataRow('Meal Session', 'Lunch'),
          const SizedBox(height: 24),
          const Text('Students Served', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: AppColors.danger),
                onPressed: () => setState(() => _studentsServed--),
              ),
              Text('$_studentsServed', style: const TextStyle(fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primaryGreen),
                onPressed: () => setState(() => _studentsServed++),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _analyzeMeal,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.analytics),
            label: Text(_isAnalyzing ? 'ANALYZING...' : 'ANALYZE MEAL'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          if (_imageFile != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => _imageFile = null),
              child: const Text('REMOVE PHOTO'),
            ),
          ]
        ],
      ),
    );
  }

  static Widget _metadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
