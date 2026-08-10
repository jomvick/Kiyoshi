/// AI Settings Dialog — configure provider, model, and API keys.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/features/ai_agent/domain/entities/ai_config.dart';
import 'package:kiyoshi/src/features/ai_agent/presentation/ai_agent_providers.dart';

class AiSettingsDialog extends ConsumerStatefulWidget {
  const AiSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => const AiSettingsDialog(),
    );
  }

  @override
  ConsumerState<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends ConsumerState<AiSettingsDialog> {
  late AiProvider _selectedProvider;
  late Map<AiProvider, _ProviderFormState> _forms;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(aiSettingsProvider);
    _selectedProvider = settings.activeProvider;
    _forms = {
      for (final p in AiProvider.values)
        p: _ProviderFormState.from(
          settings.configs[p] ??
              AiProviderConfig(
                provider: p,
                model: AiProviderConfig.defaultModelFor(p),
              ),
        ),
    };
  }

  @override
  void dispose() {
    for (final f in _forms.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(aiSettingsProvider.notifier);
    await notifier.setActiveProvider(_selectedProvider);
    for (final entry in _forms.entries) {
      await notifier.updateProviderConfig(entry.value.toConfig(entry.key));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 680),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[900]!.withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(scheme),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProviderSelector(scheme),
                        const SizedBox(height: 20),
                        _buildActiveProviderForm(scheme),
                      ],
                    ),
                  ),
                ),
                _buildFooter(scheme),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(duration: 200.ms).scaleXY(begin: 0.96, end: 1.0);
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: scheme.primary.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2A9D84), Color(0xFF5C8DAE)],
              ),
            ),
            child: const Icon(LucideIcons.sparkles,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            'Configuration IA',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(LucideIcons.x, size: 18, color: scheme.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'FOURNISSEUR ACTIF',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.2,
          children: AiProvider.values
              .map((p) => _ProviderCard(
                    provider: p,
                    isSelected: _selectedProvider == p,
                    onTap: () => setState(() => _selectedProvider = p),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActiveProviderForm(ColorScheme scheme) {
    final form = _forms[_selectedProvider]!;
    final provider = _selectedProvider;
    final models = AiProviderConfig.modelsFor(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONFIGURATION — ${provider.displayName.toUpperCase()}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        // API Key field (hidden for Ollama)
        if (!provider.isLocal) ...[
          _SettingsTextField(
            controller: form.apiKeyController,
            label: 'Clé API',
            hint: 'sk-... / AIza... / sk-ant-...',
            isObscured: true,
            prefixIcon: LucideIcons.key,
          ),
          const SizedBox(height: 12),
        ],
        // Base URL
        _SettingsTextField(
          controller: form.baseUrlController,
          label: provider.isLocal ? 'URL Ollama (localhost)' : 'Base URL',
          hint: provider.defaultBaseUrl,
          prefixIcon: LucideIcons.link,
        ),
        const SizedBox(height: 12),
        // Model selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modèle',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: models.contains(form.modelController.text)
                  ? form.modelController.text
                  : null,
              decoration: InputDecoration(
                prefixIcon: Icon(LucideIcons.cpu,
                    size: 16, color: scheme.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                filled: true,
                fillColor:
                    scheme.surfaceContainerLow.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.15)),
                ),
              ),
              hint: Text(form.modelController.text.isNotEmpty
                  ? form.modelController.text
                  : 'Choisir un modèle'),
              items: models
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) form.modelController.text = v;
              },
            ),
            // Custom model input
            const SizedBox(height: 8),
            _SettingsTextField(
              controller: form.modelController,
              label: 'Ou saisir un modèle personnalisé',
              hint: provider.isLocal ? 'llama3.2:latest' : 'gpt-4o',
              prefixIcon: LucideIcons.pencil,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: scheme.primary.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedProvider.isLocal
                  ? '🔒 Ollama fonctionne localement — aucune donnée envoyée sur le cloud.'
                  : '🔑 Votre clé API est stockée localement uniquement.',
              style: TextStyle(
                  fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(LucideIcons.save, size: 16),
            label: const Text('Enregistrer'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2A9D84),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Provider Card ────────────────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  final AiProvider provider;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (emoji, color) = switch (provider) {
      AiProvider.openAI => ('🤖', const Color(0xFF10A37F)),
      AiProvider.gemini => ('✨', const Color(0xFF4285F4)),
      AiProvider.anthropic => ('🧠', const Color(0xFFD4A017)),
      AiProvider.ollama => ('🔒', const Color(0xFF6366F1)),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : scheme.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : scheme.outline.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? color : scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Settings Text Field ──────────────────────────────────────────────────

class _SettingsTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isObscured;

  const _SettingsTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.isObscured = false,
  });

  @override
  State<_SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<_SettingsTextField> {
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.isObscured;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          style: TextStyle(fontSize: 13, color: scheme.onSurface),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                fontSize: 13),
            prefixIcon: Icon(widget.prefixIcon,
                size: 16, color: scheme.onSurfaceVariant),
            suffixIcon: widget.isObscured
                ? IconButton(
                    icon: Icon(
                      _hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
            filled: true,
            fillColor: scheme.surfaceContainerLow.withValues(alpha: 0.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.outline.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Form State Helper ────────────────────────────────────────────────────

class _ProviderFormState {
  final TextEditingController apiKeyController;
  final TextEditingController baseUrlController;
  final TextEditingController modelController;

  _ProviderFormState({
    required this.apiKeyController,
    required this.baseUrlController,
    required this.modelController,
  });

  factory _ProviderFormState.from(AiProviderConfig config) {
    return _ProviderFormState(
      apiKeyController: TextEditingController(text: config.apiKey),
      baseUrlController: TextEditingController(text: config.baseUrl),
      modelController: TextEditingController(text: config.model),
    );
  }

  AiProviderConfig toConfig(AiProvider provider) {
    return AiProviderConfig(
      provider: provider,
      apiKey: apiKeyController.text.trim(),
      baseUrl: baseUrlController.text.trim().isNotEmpty
          ? baseUrlController.text.trim()
          : provider.defaultBaseUrl,
      model: modelController.text.trim().isNotEmpty
          ? modelController.text.trim()
          : AiProviderConfig.defaultModelFor(provider),
      isEnabled: true,
    );
  }

  void dispose() {
    apiKeyController.dispose();
    baseUrlController.dispose();
    modelController.dispose();
  }
}
