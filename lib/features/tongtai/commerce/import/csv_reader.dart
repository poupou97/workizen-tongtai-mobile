import 'dart:convert';
import 'dart:typed_data';

import 'xlsx_reader.dart' show TabularReader;

/// Đọc `.csv` thành một "sheet" — WTM-463.
///
/// ## Vì sao tự viết thay vì thêm gói `csv`
///
/// Cùng lý do [XlsxReader] tự viết: cây phụ thuộc đã căng vì
/// `flutter_native_splash` ghim `image ^4.5.4` → `archive ^4` + `xml ^7`. Thêm
/// một gói chỉ để tách chuỗi bằng dấu phẩy là rủi ro không cân xứng với ~40
/// dòng. Lớp này chỉ **đọc**, và chỉ đủ đúng cho một file người bán xuất ra.
///
/// ## Ba chỗ một bộ tách "split(',')" ngây thơ làm mất dữ liệu **im lặng**
///
/// Bản xuất **products của Shopify** dính cả ba, nên đây không phải phòng xa:
///
/// 1. **Dấu phẩy trong ô có ngoặc kép** — `"Ghế gỗ, tay vịn"` là MỘT ô. Tách
///    thô sẽ đẩy mọi cột sau đó lệch một nấc.
/// 2. **Xuống dòng trong ô có ngoặc kép** — cột `Body (HTML)` của Shopify chứa
///    nhiều đoạn `<p>`, mỗi đoạn một dòng. Đọc theo dòng vật lý sẽ cắt một bản
///    ghi thành nhiều "dòng" rác — file 211 bản ghi trông thành 517 dòng.
/// 3. **Ngoặc kép thoát** — `""` bên trong một ô có ngoặc kép là **một** dấu
///    `"` thật, không phải mở/đóng ô.
///
/// Vì thế phải tách theo **máy trạng thái**, không theo `split`. Kết quả trả về
/// cùng hình dạng [XlsxReader] cho: một sheet duy nhất, các dòng đã gộp đúng.
class CsvReader implements TabularReader {
  const CsvReader({this.sheetName = 'CSV'});

  /// Tên "sheet" tổng hợp. **Không bao giờ là `PRODUCTS`**: cổng định tuyến
  /// coi một sheet tên `PRODUCTS` là file danh mục XLSX, mà một `.csv` products
  /// của Shopify phải đi đường `MarketplaceExportSource`, không phải bộ đọc
  /// danh mục.
  final String sheetName;

  @override
  Map<String, List<List<String>>> read(Uint8List bytes) {
    // `allowMalformed`: một byte hỏng ở giữa file không đáng làm cả lần nhập
    // chết — cùng thái độ `XlsxReader._content`.
    var text = utf8.decode(bytes, allowMalformed: true);
    // Bỏ BOM UTF-8 nếu có: nhiều công cụ (kể cả Excel) chèn nó vào đầu file, và
    // nếu để lại thì tiêu đề cột đầu tiên thành "﻿Handle" và nhận dạng
    // trượt.
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }

    final rows = _parse(text);
    return {sheetName: rows};
  }

  /// Máy trạng thái RFC 4180 (nới lỏng): dấu phẩy ngăn ô, xuống dòng ngăn dòng,
  /// nhưng **chỉ khi đang ở ngoài ngoặc kép**.
  static List<List<String>> _parse(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    var sawAnyChar = false; // để không sinh một dòng rỗng ở cuối file

    void endField() {
      row.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      rows.add(row);
      row = <String>[];
    }

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      sawAnyChar = true;

      if (inQuotes) {
        if (ch == '"') {
          // `""` = một dấu " thật; ngược lại là đóng ô.
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
        continue;
      }

      switch (ch) {
        case '"':
          inQuotes = true;
        case ',':
          endField();
        case '\r':
          // `\r\n`: nuốt `\n` đi kèm để không sinh một dòng rỗng.
          if (i + 1 < text.length && text[i + 1] == '\n') i++;
          endRow();
          sawAnyChar = false;
        case '\n':
          endRow();
          sawAnyChar = false;
        default:
          field.write(ch);
      }
    }

    // Ô/dòng cuối chưa có ký tự kết thúc dòng — chốt lại, trừ khi file kết thúc
    // đúng ở một dấu xuống dòng (không có bản ghi treo).
    if (sawAnyChar || field.isNotEmpty || row.isNotEmpty) {
      endRow();
    }
    return rows;
  }
}
