import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'models/prediction_response.dart';
import 'services/api_service.dart';

void main() {
  runApp(const AlzDetectApp());
}

class AlzDetectApp extends StatefulWidget {
  const AlzDetectApp({super.key});

  @override
  State<AlzDetectApp> createState() => _AlzDetectAppState();
}

class _AlzDetectAppState extends State<AlzDetectApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI-Powered Alzheimer\'s Detection',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4C73)),
        scaffoldBackgroundColor: const Color(0xFFF3F5F9),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CA3FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: DashboardScreen(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.dark
                ? ThemeMode.light
                : ThemeMode.dark;
          });
        },
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientIdController = TextEditingController(text: 'P12345');
  final _nameController = TextEditingController(text: 'John Doe');
  final _ageController = TextEditingController(text: '65');

  String _gender = 'Select';
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  bool _loading = false;
  String? _error;
  PredictionResponse? _prediction;

  @override
  void dispose() {
    _patientIdController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.bytes == null) {
      setState(() {
        _error = 'Could not read selected file bytes.';
      });
      return;
    }

    setState(() {
      _selectedBytes = file.bytes!;
      _selectedFileName = file.name;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBytes == null || _selectedFileName == null) {
      setState(() {
        _error = 'Please upload an MRI image first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _prediction = null;
    });

    try {
      final result = await ApiService.analyzeMri(
        patientId: _patientIdController.text.trim(),
        patientName: _nameController.text.trim(),
        age: _ageController.text.trim(),
        gender: _gender,
        imageBytes: _selectedBytes!,
        fileName: _selectedFileName!,
      );

      setState(() {
        _prediction = result;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'AI-Powered Alzheimer\'s Detection',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF13395F),
                              ),
                            ),
                          ),
                          IconButton.filled(
                            onPressed: widget.onToggleTheme,
                            icon: Icon(
                              widget.isDark ? Icons.light_mode : Icons.dark_mode,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionCard(
                        title: 'Patient Information',
                        icon: Icons.personal_injury,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final narrow = constraints.maxWidth < 900;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _inputField(
                                  label: 'Patient ID',
                                  controller: _patientIdController,
                                  width: narrow
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - 48) / 4,
                                ),
                                _inputField(
                                  label: 'Patient Name',
                                  controller: _nameController,
                                  width: narrow
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - 48) / 4,
                                ),
                                _inputField(
                                  label: 'Age',
                                  controller: _ageController,
                                  width: narrow
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - 48) / 4,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final age = int.tryParse(v.trim());
                                    if (age == null || age <= 0 || age > 130) {
                                      return 'Invalid age';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(
                                  width: narrow
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - 48) / 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Gender'),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _gender,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Select',
                                            child: Text('Select'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Male',
                                            child: Text('Male'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Female',
                                            child: Text('Female'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Other',
                                            child: Text('Other'),
                                          ),
                                        ],
                                        onChanged: (v) {
                                          setState(() {
                                            _gender = v ?? 'Select';
                                          });
                                        },
                                        validator: (v) {
                                          if (v == null || v == 'Select') {
                                            return 'Select gender';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionCard(
                        title: 'MRI Scan Upload',
                        icon: Icons.file_upload_outlined,
                        child: InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 240),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD2DAE3),
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.cloud_upload_rounded,
                                    size: 72,
                                    color: Color(0xFF2F8FD7),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedFileName == null
                                        ? 'Drop MRI scan here or click to browse'
                                        : 'Selected: $_selectedFileName',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF103A60),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Supported formats: JPG, JPEG, PNG',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: _loading ? null : _analyze,
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.analytics_outlined),
                            label: Text(
                              _loading ? 'Analyzing...' : 'Run Analysis',
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedBytes = null;
                                _selectedFileName = null;
                                _prediction = null;
                                _error = null;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                      if (_prediction != null) ...[
                        const SizedBox(height: 20),
                        _ResultCard(result: _prediction!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required double width,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator ??
                (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return null;
                },
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2B4867),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      color: const Color(0xFF253E56),
      child: Column(
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            color: const Color(0xFF22384D),
            child: const Row(
              children: [
                Icon(Icons.psychology_alt_outlined,
                    color: Color(0xFF35A2E4), size: 34),
                SizedBox(width: 12),
                Text(
                  'AlzDetect AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const _MenuItem(icon: Icons.upload_file, label: 'Analysis', active: true),
          const _MenuItem(icon: Icons.layers_outlined, label: 'Batch Process'),
          const _MenuItem(icon: Icons.bar_chart_outlined, label: 'Metrics'),
          const _MenuItem(icon: Icons.calculate_outlined, label: 'Risk Assessment'),
          const _MenuItem(icon: Icons.info_outline, label: 'About'),
          const Spacer(),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 10),
          const Text('© 2026', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: active ? const Color(0xFF2F4E6E) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: active ? Colors.white : Colors.white70),
        title: Text(
          label,
          style: TextStyle(color: active ? Colors.white : Colors.white70),
        ),
        onTap: () {},
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final PredictionResponse result;

  @override
  Widget build(BuildContext context) {
    final confidence = result.confidence != null
        ? '${(result.confidence! * 100).toStringAsFixed(1)}%'
        : 'N/A';
    final risk = result.riskScore != null
        ? '${(result.riskScore! * 100).toStringAsFixed(1)}%'
        : 'N/A';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prediction Result',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _pill('Diagnosis', result.diagnosis),
                _pill('Confidence', confidence),
                _pill('Risk Score', risk),
              ],
            ),
            if (result.recommendation != null) ...[
              const SizedBox(height: 12),
              Text('Recommendation: ${result.recommendation!}'),
            ],
            const SizedBox(height: 10),
            ExpansionTile(
              title: const Text('Raw JSON Response'),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                SelectableText(result.raw.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFE9F2FB),
        border: Border.all(color: const Color(0xFFC8DCF2)),
      ),
      child: Text('$title: $value'),
    );
  }
}
