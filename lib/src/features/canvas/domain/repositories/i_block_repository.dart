import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';

abstract class IBlockRepository {
  Future<ZenBlock?> getBlockById(String id);
  Stream<List<ZenBlock>> watchBlocksForProject(String projectId);
  Future<String> addBlock(String projectId, ParsedBlock parsedBlock);
  Future<void> updateBlock(ZenBlock block);
  Future<void> deleteBlock(ZenBlock block);
  Future<void> reorderBlocks(String projectId, int oldIndex, int newIndex);
}
