import 'package:flutter_test/flutter_test.dart';
import 'package:salonscale_poc/features/assistant/services/mock_inventory_assistant_service.dart';
import 'package:salonscale_poc/features/inventory/models/inventory_record.dart';

void main() {
  test('mock assistant answers low stock questions from inventory context',
      () async {
    const service = MockInventoryAssistantService();
    final answer = await service.answerQuestion(
      question: 'Which products are running low?',
      scans: const [],
      inventory: [
        InventoryRecord(
          productId: 'product_001',
          productName: 'Professional Colour Cream 5N',
          brand: 'Sample Brand',
          category: 'Hair Colour',
          packagingType: 'tube',
          shadeCode: '5N',
          quantity: 2,
          latestScanDate: DateTime(2026, 7, 10),
        ),
      ],
    );

    expect(answer, contains('Professional Colour Cream 5N'));
    expect(answer, contains('2'));
  });
}
