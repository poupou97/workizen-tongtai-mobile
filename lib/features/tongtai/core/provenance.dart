import 'package:flutter/foundation.dart';

/// Nguồn gốc của một bản ghi — **mã canonical**, không phải nhãn hiển thị
/// (ADR-TON-018).
///
/// Hôm nay app phân biệt ba loại dữ liệu bằng **tiền tố trong id**: `sample-`
/// cho dữ liệu mẫu (ADR-TON-014), `gen-` cho thứ rule engine sinh ra, và không
/// gì cả cho dữ liệu người bán tự nhập. Tức là **quy ước đặt tên đang đóng vai
/// trò dữ liệu** — thứ không truy vấn được, không mang ý nghĩa trong `.ttbk`,
/// và vỡ ngay khi có nguồn thứ tư.
///
/// Nó đã gây một lỗi thật: Founder nhầm màn demo với dashboard thật (WTM-143).
/// Bản vá lúc đó là một banner; nguyên nhân gốc là ranh giới nguồn gốc **không
/// tồn tại trong model**.
/// Tiền tố id của mọi bản ghi mẫu (ADR-TON-014).
///
/// Sống ở đây chứ không ở lớp gieo dữ liệu vì **ba** tầng cần nó: lớp gieo,
/// [Provenance.inferFromId], và các kho của tầng agentic khi đặt lại demo.
/// Trước WTM-307 nó được viết tay ở hai chỗ — đúng hình dạng lỗi mà chính
/// `Provenance` sinh ra để dọn.
const String kSampleIdPrefix = 'sample-';

enum ProvenanceSource {
  /// Người bán tự nhập. Đây là dữ liệu có thẩm quyền cao nhất — mọi thứ khác
  /// nhường nó khi xung đột (bài học FK 787: user data thắng).
  manual('manual'),

  /// Dữ liệu mẫu gieo vào chính repository production (ADR-TON-014), để mọi
  /// màn dùng chung một đường đọc thay vì có một "chế độ demo" song song.
  sample('sample'),

  /// Hệ thống suy ra từ dữ liệu khác — cơ hội do rule engine sinh, mục tiêu
  /// tạo từ một cơ hội. **Không phải** con số do Rule Twin tính: Provenance
  /// nói bản ghi *từ đâu tới*, không nói *ai tính ra con số trong đó*
  /// (ADR-TON-016 vẫn giữ nguyên).
  derived('derived'),

  /// Về từ một nền tảng ngoài qua connector. Khớp `provenance.source` trong
  /// canonical event envelope (`docs/08-PLATFORM/09-MOBILE-BACKEND-CONTRACT.md`).
  connector('connector');

  const ProvenanceSource(this.code);

  /// Mã lưu xuống DB và `.ttbk`. **Không bao giờ là nhãn hiển thị.**
  final String code;

  /// Mã lạ ⇒ `null`, **không** rơi về `manual`.
  ///
  /// ADR-TON-018: mã không nhận ra là **bản ghi hỏng**, không phải giá trị mặc
  /// định. Rơi về `manual` sẽ biến một bản ghi mẫu hoặc bản ghi từ sàn thành
  /// "người bán tự nhập" — tức là nói dối đúng theo hướng nguy hiểm nhất.
  static ProvenanceSource? fromCode(String? code) {
    for (final s in ProvenanceSource.values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// Nguồn gốc của một bản ghi, kèm việc **ta có chắc hay không**.
///
/// ## Vì sao có `inferred`
///
/// Bản ghi tạo trước schema v17 không khai nguồn gốc. Ta vẫn đoán được khá
/// chắc từ tiền tố id — nhưng *đoán được* và *bản ghi tự khai* là hai chuyện
/// khác nhau, và gộp chúng lại là đúng cái lỗi `null` ≠ `0` mà repo này đã
/// sửa nhiều lần.
///
/// Cụ thể: một bản ghi `inferred` có thể sai nếu người bán từng tự đặt id bắt
/// đầu bằng `sample-`. Hiếm, nhưng không phải không thể — và khi nó xảy ra,
/// thứ giúp ta phát hiện là chính cờ này.
@immutable
class Provenance {
  const Provenance({required this.source, this.inferred = false});

  /// Bản ghi tự khai nguồn gốc — đường đi bình thường từ v17 trở đi.
  const Provenance.declared(ProvenanceSource source)
    : this(source: source, inferred: false);

  /// Suy ra từ dấu vết cũ (tiền tố id), vì bản ghi không khai.
  const Provenance.inferred(ProvenanceSource source)
    : this(source: source, inferred: true);

  /// Mặc định cho bản ghi mới do người bán tạo.
  static const Provenance manual = Provenance.declared(ProvenanceSource.manual);

  final ProvenanceSource source;

  /// `true` ⇒ giá trị này là **suy đoán**, không phải lời khai của bản ghi.
  final bool inferred;

  /// Suy nguồn gốc từ id của bản ghi — dùng cho dữ liệu có TRƯỚC v17.
  ///
  /// Chỉ có hai tiền tố từng được dùng làm dấu hiệu nguồn gốc; mọi id khác là
  /// người bán tự tạo (UUID, theo ADR-TON-014 nên không đụng hai tiền tố này).
  static Provenance inferFromId(String id) {
    if (id.startsWith(kSampleIdPrefix)) {
      return const Provenance.inferred(ProvenanceSource.sample);
    }
    if (id.startsWith('gen-')) {
      return const Provenance.inferred(ProvenanceSource.derived);
    }
    return const Provenance.inferred(ProvenanceSource.manual);
  }

  /// Đọc từ cột đã lưu; `null` hoặc mã lạ ⇒ quay về suy đoán từ id.
  ///
  /// Gộp hai đường vào một chỗ để không nơi nào tự chế quy tắc riêng — đúng
  /// bài học P-27/P-28 (một luật dẫn xuất, một chỗ).
  static Provenance fromStored({required String? code, required String id}) {
    final declared = ProvenanceSource.fromCode(code);
    if (declared != null) return Provenance.declared(declared);
    return inferFromId(id);
  }

  /// Giá trị ghi xuống cột. `null` cho bản ghi suy đoán — **không** đông cứng
  /// một suy đoán thành lời khai bằng cách ghi nó xuống đĩa.
  String? get storedCode => inferred ? null : source.code;

  @override
  bool operator ==(Object other) =>
      other is Provenance &&
      other.source == source &&
      other.inferred == inferred;

  @override
  int get hashCode => Object.hash(source, inferred);

  @override
  String toString() =>
      'Provenance(${source.code}${inferred ? ', inferred' : ''})';
}
