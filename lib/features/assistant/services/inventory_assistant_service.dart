import '../../inventory/models/inventory_record.dart';
import '../../scanning/models/inventory_scan.dart';

abstract class InventoryAssistantService {
  Future<String> answerQuestion({
    required String question,
    required List<InventoryRecord> inventory,
    required List<InventoryScan> scans,
  });
}
