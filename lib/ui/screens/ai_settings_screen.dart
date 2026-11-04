import 'package:flutter/material.dart';

import '../../services/ai_settings.dart';
import '../../services/note_processor.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  AiSettings? _s;
  final _key = TextEditingController();
  final _model = TextEditingController();
  final _url = TextEditingController();
  final _ollamaModel = TextEditingController();
  bool _obscure = true;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    AiSettingsStore.load().then((s) {
      if (!mounted) return;
      _key.text = s.geminiKey;
      _model.text = s.geminiModel;
      _url.text = s.ollamaUrl;
      _ollamaModel.text = s.ollamaModel;
      setState(() => _s = s);
    });
  }

  @override
  void dispose() {
    for (final c in [_key, _model, _url, _ollamaModel]) {
      c.dispose();
    }
    super.dispose();
  }

  AiSettings get _current => _s!.copyWith(
        geminiKey: _key.text.trim(),
        geminiModel: _model.text.trim().isEmpty ? AiSettings.defaultGeminiModel : _model.text.trim(),
        ollamaUrl: _url.text.trim(),
        ollamaModel: _ollamaModel.text.trim(),
      );

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    await AiSettingsStore.save(_current);
    messenger.showSnackBar(const SnackBar(content: Text('AI settings saved')));
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final r = await NoteProcessor(_current).process(
      'Photosynthesis converts light energy into chemical energy stored in glucose. It happens in the chloroplasts of plant cells.',
      notebooks: const ['General', 'Science', 'History'],
      defaultNotebook: 'General',
      autoRoute: true,
      summarize: true,
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = r.aiError != null
          ? '❌ ${r.aiError}'
          : r.usedAi
              ? '✅ Routed to ${r.notebook} (${(r.confidence * 100).round()}%): "${r.title}"'
              : 'Offline sorting: ${r.notebook}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: const Text('AI note processing')),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Captured text is routed to a notebook and turned into headings, key terms and a summary. '
                    'Without AI, keyword sorting is used and you may be asked to pick the notebook.'),
                const SizedBox(height: 16),
                SegmentedButton<AiProvider>(
                  segments: const [
                    ButtonSegment(value: AiProvider.none, label: Text('Offline')),
                    ButtonSegment(value: AiProvider.gemini, label: Text('Gemini')),
                    ButtonSegment(value: AiProvider.ollama, label: Text('Ollama')),
                  ],
                  selected: {s.provider},
                  onSelectionChanged: (v) => setState(() => _s = s.copyWith(provider: v.first)),
                ),
                const SizedBox(height: 16),
                if (s.provider == AiProvider.gemini) ...[
                  TextField(
                    controller: _key,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Gemini API key',
                      helperText: 'From aistudio.google.com. Stored encrypted on this device only.',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _model,
                    decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                  ),
                ],
                if (s.provider == AiProvider.ollama) ...[
                  TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Ollama URL',
                      helperText: 'Your computer\'s LAN address, e.g. http://192.168.1.20:11434 (10.0.2.2 on the emulator)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ollamaModel,
                    decoration: const InputDecoration(labelText: 'Model', helperText: 'e.g. qwen3', border: OutlineInputBorder()),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: FilledButton(onPressed: _save, child: const Text('Save'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _testing ? null : _test,
                        child: _testing
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Test'),
                      ),
                    ),
                  ],
                ),
                if (_testResult != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_testResult!)),
              ],
            ),
    );
  }
}
