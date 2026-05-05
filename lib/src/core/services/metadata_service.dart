import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:kiyoshi/src/features/canvas/domain/repositories/i_block_repository.dart';

/// Service responsible for asynchronous data enrichment.
class MetadataService {
  final IBlockRepository _repository;

  MetadataService(this._repository);

  /// Analyzes a block and enriches it if necessary (e.g. fetching link metadata).
  /// Should be called asynchronously without blocking the UI.
  Future<void> enrichBlockIfNeeded(String blockId) async {
    final block = await _repository.getBlockById(blockId);
    if (block == null) return;

    if (block.type == 'link') {
      final metadata = Map<String, dynamic>.from(block.metadata);
      
      // If metadata is pending, fetch it
      if (metadata['status'] == 'pending_metadata') {
        try {
          final data = await MetadataFetch.extract(block.content);
          metadata['title'] = data?.title;
          metadata['favicon'] = data?.image;
          metadata.remove('status'); // Mark as resolved

          await _repository.updateBlock(block.copyWith(
            metadata: metadata,
          ));
        } catch (e) {
          // In case of error, just remove the pending status so we don't retry endlessly
          metadata.remove('status');
          await _repository.updateBlock(block.copyWith(
            metadata: metadata,
          ));
        }
      }
    }
  }
}
