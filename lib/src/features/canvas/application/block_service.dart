import 'package:flutter/foundation.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/features/canvas/domain/repositories/i_block_repository.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/core/services/metadata_service.dart';
import 'package:kiyoshi/src/core/services/vault_service.dart';

class BlockService {
  final IBlockRepository _repository;
  final MetadataService _metadataService;
  final VaultService _vaultService;

  BlockService(this._repository, this._metadataService, this._vaultService);

  Future<String> addBlock(String projectId, ParsedBlock parsedBlock) async {
    ParsedBlock finalBlock = parsedBlock;

    // Invisible Management: Copy images/files to Vault
    if (parsedBlock.type == 'image' || parsedBlock.type == 'file') {
      try {
        final vaultPath = await _vaultService.copyToVault(parsedBlock.content);
        finalBlock = ParsedBlock(
          type: parsedBlock.type,
          content: vaultPath,
          metadata: parsedBlock.metadata,
        );
      } catch (e) {
        debugPrint('Vault copy failed: $e');
      }
    }

    final id = await _repository.addBlock(projectId, finalBlock);

    if (finalBlock.type == 'link') {
      _metadataService.enrichBlockIfNeeded(id);
    }

    return id;
  }

  Future<void> deleteBlock(ZenBlock block) async {
    // Cleanup: Remove physical file if it's in the vault
    if (block.type == 'image' || block.type == 'file') {
      await _vaultService.deleteFromVault(block.content);
    }
    return _repository.deleteBlock(block);
  }

  Future<void> updateBlock(ZenBlock block) => _repository.updateBlock(block);

  Future<void> reorderBlocks(String projectId, int oldIndex, int newIndex) =>
      _repository.reorderBlocks(projectId, oldIndex, newIndex);

  Stream<List<ZenBlock>> watchBlocks(String projectId) =>
      _repository.watchBlocksForProject(projectId);
}
