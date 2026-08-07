import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';

/// WTM-282 (N0.1) — **Provenance**, và điều nó từ chối làm.
///
/// Trước story này, nguồn gốc một bản ghi được suy từ **tiền tố id**:
/// `sample-` (ADR-TON-014), `gen-` (rule engine), không gì cả (người bán).
/// Quy ước đặt tên đóng vai trò dữ liệu — không truy vấn được, không mang ý
/// nghĩa trong `.ttbk`, và vỡ khi có nguồn thứ tư.
///
/// Hai tính chất suite này khoá, và cả hai đều là **từ chối**, không phải khả
/// năng:
///
/// * **mã lạ ⇒ `null`, không rơi về `manual`** — rơi về `manual` sẽ biến một
///   bản ghi mẫu hoặc bản ghi từ sàn thành "người bán tự nhập", tức nói dối
///   đúng theo hướng nguy hiểm nhất (ADR-TON-018);
/// * **suy đoán không được ghi xuống đĩa** — `storedCode` trả `null` cho bản
///   ghi `inferred`, nên một phỏng đoán không bao giờ đông cứng thành lời khai.
void main() {
  group('mã canonical', () {
    test('bốn mã, và chúng là mã chứ không phải nhãn hiển thị', () {
      expect(ProvenanceSource.values.map((s) => s.code).toList(), [
        'manual',
        'sample',
        'derived',
        'connector',
      ]);
      // Nhãn hiển thị có dấu tiếng Việt hoặc khoảng trắng; mã thì không.
      for (final s in ProvenanceSource.values) {
        expect(
          RegExp(r'^[a-z_]+$').hasMatch(s.code),
          isTrue,
          reason: '${s.code} phải là mã canonical, không phải nhãn',
        );
      }
    });

    test('mã lạ ⇒ null, KHÔNG rơi về manual', () {
      for (final bad in [null, '', 'Manual', 'thủ công', 'shopee', 'unknown']) {
        expect(
          ProvenanceSource.fromCode(bad),
          isNull,
          reason: '$bad không được ngầm thành một nguồn hợp lệ',
        );
      }
    });
  });

  group('suy đoán từ id — dữ liệu có trước v17', () {
    test('tiền tố sample- ⇒ sample, và được đánh dấu là suy đoán', () {
      final p = Provenance.inferFromId('sample-order-1');
      expect(p.source, ProvenanceSource.sample);
      expect(p.inferred, isTrue);
    });

    test('tiền tố gen- ⇒ derived', () {
      expect(
        Provenance.inferFromId('gen-restock-42').source,
        ProvenanceSource.derived,
      );
    });

    test('id thường (UUID người bán) ⇒ manual', () {
      final p = Provenance.inferFromId('9f1c2b7a-4d3e-4f21-9c8b-1a2b3c4d5e6f');
      expect(p.source, ProvenanceSource.manual);
      expect(
        p.inferred,
        isTrue,
        reason: 'vẫn là suy đoán, không phải lời khai',
      );
    });
  });

  group('đọc từ cột đã lưu', () {
    test('có mã hợp lệ ⇒ lời khai, KHÔNG phải suy đoán', () {
      final p = Provenance.fromStored(code: 'connector', id: 'anything');
      expect(p.source, ProvenanceSource.connector);
      expect(p.inferred, isFalse);
    });

    test('cột null ⇒ quay về suy đoán từ id', () {
      final p = Provenance.fromStored(code: null, id: 'sample-x');
      expect(p.source, ProvenanceSource.sample);
      expect(p.inferred, isTrue);
    });

    test('mã lạ ⇒ cũng quay về suy đoán, không tin mã hỏng', () {
      final p = Provenance.fromStored(code: 'garbage', id: 'gen-x');
      expect(p.source, ProvenanceSource.derived);
      expect(p.inferred, isTrue);
    });
  });

  group('ghi xuống đĩa', () {
    test('lời khai được ghi', () {
      expect(
        const Provenance.declared(ProvenanceSource.sample).storedCode,
        'sample',
      );
    });

    test('SUY ĐOÁN KHÔNG được ghi — đây là tính chất chính của story', () {
      for (final s in ProvenanceSource.values) {
        expect(
          Provenance.inferred(s).storedCode,
          isNull,
          reason:
              'ghi một suy đoán xuống đĩa là biến nó thành lời khai; '
              'lần đọc sau sẽ không còn biết đó từng là phỏng đoán',
        );
      }
    });

    test('vòng ghi–đọc giữ nguyên lời khai', () {
      for (final s in ProvenanceSource.values) {
        final original = Provenance.declared(s);
        final back = Provenance.fromStored(
          code: original.storedCode,
          id: 'irrelevant',
        );
        expect(back, original);
      }
    });
  });

  test('mặc định cho bản ghi mới là manual, và là lời khai', () {
    expect(Provenance.manual.source, ProvenanceSource.manual);
    expect(Provenance.manual.inferred, isFalse);
    expect(Provenance.manual.storedCode, 'manual');
  });
}
