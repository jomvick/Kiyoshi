import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';

abstract class IBlockRepository {
  Future<ZenBlock?> getBlockById(String id);
  Stream<List<ZenBlock>> watchBlocksForProject(String projectId);
  Future<String> addBlock(String projectId, ParsedBlock parsedBlock);
  /// Inserts a block positioned right after [afterBlockId] (fractional
  /// position between it and the next block), instead of always appending
  /// at the end like [addBlock]. Falls back to appending at the end if
  /// [afterBlockId] can't be found.
  Future<String> addBlockAfter(String projectId, String afterBlockId, ParsedBlock parsedBlock);
  /// Moves an existing block into a different project (or into the 'global'
  /// inbox), placing it at the end of the target project's block list.
  /// Backs "attach this idea to a project" from the Notes inbox.
  Future<void> moveBlockToProject(String blockId, String targetProjectId);
  Future<void> updateBlock(ZenBlock block);
  Future<void> deleteBlock(ZenBlock block);
  Future<void> reorderBlocks(String projectId, int oldIndex, int newIndex);
}
