import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiEndpointController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedEndpoint();
  }

  Future<void> _loadSavedEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEndpoint = prefs.getString('api_endpoint') ?? '';
    setState(() {
      _apiEndpointController.text = savedEndpoint;
    });
  }

  Future<void> _saveEndpoint() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_endpoint', _apiEndpointController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API endpoint saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _apiEndpointController,
                decoration: const InputDecoration(
                  labelText: 'API Endpoint',
                  hintText: 'Enter the API endpoint URL',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an API endpoint';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEndpoint,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiEndpointController.dispose();
    super.dispose();
  }
}
