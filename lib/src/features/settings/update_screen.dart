import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/core/services/update_service.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

final updateAvailableProvider = StateProvider<UpdateInfo?>((ref) => null);

class UpdateScreen extends ConsumerStatefulWidget {
  const UpdateScreen({super.key});

  @override
  ConsumerState<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends ConsumerState<UpdateScreen> {
  bool _checking = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _checking = true;
      _status = 'Checking for updates...';
    });

    final update = await UpdateService().checkForUpdate();

    setState(() {
      _checking = false;
      _status = update != null
          ? 'Version ${update.version} available!'
          : 'You have the latest version.';
    });

    if (update != null) {
      ref.read(updateAvailableProvider.notifier).state = update;
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = ref.watch(updateAvailableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiyoshi Update'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _checkUpdate,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.download,
                size: 64,
                color: AppTheme.primary,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              Text(
                'Version ${UpdateService().currentVersion}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              if (_checking)
                const CircularProgressIndicator()
              else
                Text(
                  _status ?? 'Tap refresh to check',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              if (update != null) ...[
                const SizedBox(height: AppTheme.spaceXLarge),
                ZenGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New: ${update.version}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Text(update.releaseNotes),
                        const SizedBox(height: AppTheme.spaceMedium),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _downloadUpdate(update),
                            icon: const Icon(LucideIcons.download),
                            label: const Text('Download Update'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadUpdate(UpdateInfo update) async {
    final success = await UpdateService().downloadAndInstall(update);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Download complete! Restart to apply.'
              : 'Download failed. Please try manually.'),
        ),
      );
    }
  }
}