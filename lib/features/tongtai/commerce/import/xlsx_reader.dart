import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

/// Đọc `.xlsx` — WTM-326 (C2 · Epic WTM-324).
///
/// ## Vì sao tự viết thay vì dùng gói `excel`
///
/// `excel` kéo theo `archive ^3` và `xml <7`, mà `flutter_native_splash` đã
/// giữ `image ^4.5.4` → `archive ^4` + `xml ^7`. Dart biên dịch nguồn của mọi
/// nền tảng kể cả khi chỉ build Android, nên xung đột này làm **cả app không
/// build được**, chứ không phải chỉ hỏng phần Excel.
///
/// Đổi lại: một lớp chỉ **đọc**, khoảng 150 dòng, dựa trên hai gói đã có sẵn
/// trong cây phụ thuộc. Không ghi, không công thức, không định dạng — đúng
/// những gì cần và không hơn.
///
/// ## `.xlsx` thật ra là gì
///
/// Một file ZIP chứa XML:
///
/// - `xl/workbook.xml` — tên các sheet, theo thứ tự
/// - `xl/sharedStrings.xml` — bảng chuỗi dùng chung; ô kiểu `s` trỏ vào đây
/// - `xl/worksheets/sheetN.xml` — ô, mỗi ô có địa chỉ kiểu `B7`
///
/// Ba chỗ dễ sai, và cả ba đều làm mất dữ liệu **im lặng**:
///
/// 1. **Ô rỗng không có phần tử `<c>`.** Đọc tuần tự sẽ làm mọi cột sau đó
///    lệch sang trái. Nên phải đọc theo **địa chỉ cột**, không theo thứ tự.
/// 2. **Chuỗi dùng chung** — ô kiểu `s` chứa một **số**, và số đó là chỉ mục.
///    Đọc thẳng sẽ ra "42" thay vì "Áo thun".
/// 3. **Chuỗi nội tuyến** (`t="inlineStr"`) — một số công cụ xuất kiểu này
///    thay vì dùng bảng chung.
class XlsxReader {
  const XlsxReader();

  /// Đọc toàn bộ workbook thành `{tên sheet: các dòng}`.
  ///
  /// Ném [XlsxException] khi file không phải `.xlsx` đọc được — chỗ gọi biến
  /// nó thành một câu tiếng Việt, không phải một stack trace.
  Map<String, List<List<String>>> read(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object catch (e) {
      throw XlsxException(XlsxProblem.notAZipFile, '$e');
    }

    final files = {
      for (final f in archive.files)
        if (f.isFile) f.name: f,
    };

    // `ZipDecoder` không ném cho một file văn bản — nó trả về một archive
    // **rỗng**. Không chặn ở đây thì người dùng chọn nhầm file .txt sẽ nhận
    // câu "file mở được nhưng không có bảng nào", tức là app nói nó đã mở được
    // một thứ nó chưa hề mở.
    if (files.isEmpty) {
      throw const XlsxException(
        XlsxProblem.notAZipFile,
        'không phải file nén hợp lệ',
      );
    }

    final workbookXml = files['xl/workbook.xml'];
    if (workbookXml == null) {
      throw const XlsxException(
        XlsxProblem.notASpreadsheet,
        'thiếu xl/workbook.xml',
      );
    }

    final sharedStrings = _readSharedStrings(files['xl/sharedStrings.xml']);
    final sheetNames = _readSheetNames(workbookXml);

    final out = <String, List<List<String>>>{};
    for (var i = 0; i < sheetNames.length; i++) {
      // `sheet1.xml` là sheet **thứ nhất theo thứ tự trong workbook.xml**.
      // Ánh xạ qua `r:id` chính xác hơn nhưng cần đọc thêm `_rels`; thứ tự
      // đúng cho mọi file do Excel/openpyxl/LibreOffice sinh ra.
      final sheetFile = files['xl/worksheets/sheet${i + 1}.xml'];
      if (sheetFile == null) continue;
      out[sheetNames[i]] = _readSheet(sheetFile, sharedStrings);
    }

    if (out.isEmpty) {
      throw const XlsxException(
        XlsxProblem.notASpreadsheet,
        'không có sheet nào đọc được',
      );
    }
    return out;
  }

  List<String> _readSharedStrings(ArchiveFile? file) {
    if (file == null) return const [];
    final document = XmlDocument.parse(_content(file));
    return [
      for (final si in document.findAllElements('si'))
        // Một `si` có thể gồm nhiều đoạn `<t>` (khi một ô có nhiều định dạng
        // chữ). Nối lại — lấy đoạn đầu sẽ cắt cụt tên sản phẩm.
        si.findAllElements('t').map((t) => t.innerText).join(),
    ];
  }

  List<String> _readSheetNames(ArchiveFile file) {
    final document = XmlDocument.parse(_content(file));
    return [
      for (final sheet in document.findAllElements('sheet'))
        sheet.getAttribute('name') ?? '',
    ];
  }

  List<List<String>> _readSheet(ArchiveFile file, List<String> shared) {
    final document = XmlDocument.parse(_content(file));
    final rows = <List<String>>[];

    for (final row in document.findAllElements('row')) {
      final cells = <int, String>{};
      var widest = -1;

      for (final cell in row.findElements('c')) {
        final reference = cell.getAttribute('r');
        final columnIndex = reference == null
            ? cells.length
            : _columnIndexOf(reference);
        if (columnIndex > widest) widest = columnIndex;
        cells[columnIndex] = _cellValue(cell, shared);
      }

      if (widest < 0) {
        rows.add(const []);
        continue;
      }
      // Điền ô rỗng bằng chuỗi rỗng để mọi dòng cùng chiều rộng — chỗ gọi ánh
      // xạ theo **chỉ mục cột của tiêu đề**, nên một dòng ngắn hơn sẽ đọc lệch.
      rows.add([for (var i = 0; i <= widest; i++) cells[i] ?? '']);
    }
    return rows;
  }

  String _cellValue(XmlElement cell, List<String> shared) {
    final type = cell.getAttribute('t');

    if (type == 'inlineStr') {
      return cell.findAllElements('t').map((t) => t.innerText).join();
    }

    final v = cell.getElement('v');
    if (v == null) return '';
    final raw = v.innerText;

    if (type == 's') {
      final index = int.tryParse(raw);
      if (index == null || index < 0 || index >= shared.length) return '';
      return shared[index];
    }
    return raw;
  }

  /// `B7` → `1`. Chữ cái là cơ số 26 **không có số 0**: `A`=1 … `Z`=26,
  /// `AA`=27. Trừ 1 ở cuối để ra chỉ mục từ 0.
  static int _columnIndexOf(String reference) {
    var value = 0;
    for (final unit in reference.codeUnits) {
      if (unit < 65 || unit > 90) break; // hết phần chữ cái
      value = value * 26 + (unit - 64);
    }
    return value - 1;
  }

  String _content(ArchiveFile file) =>
      utf8.decode(file.content as List<int>, allowMalformed: true);
}

/// Vì sao một file không đọc được — **mã**, để giao diện nói một câu tiếng
/// Việt thay vì hiện lỗi kỹ thuật (ADR-TON-017).
enum XlsxProblem {
  /// Người dùng chọn nhầm file (ảnh, PDF, `.xls` đời cũ…).
  notAZipFile('not_a_zip'),

  /// Là ZIP nhưng không phải bảng tính.
  notASpreadsheet('not_a_spreadsheet'),

  /// XML hỏng.
  corrupt('corrupt');

  const XlsxProblem(this.code);

  final String code;
}

@immutable
class XlsxException implements Exception {
  const XlsxException(this.problem, [this.detail]);

  final XlsxProblem problem;

  /// Chỉ hiện trên máy người dùng; telemetry nhận `problem`.
  final String? detail;

  @override
  String toString() => 'XlsxException(${problem.code})';
}

/// Một sheet đã đọc, tra ô theo **tên cột** thay vì theo chỉ mục.
///
/// Vì sao: file thật của người bán có cột thừa, thiếu, và đảo thứ tự. Đọc theo
/// chỉ mục sẽ im lặng lấy nhầm cột — `cost_price` đọc thành `selling_price` là
/// một lỗi không ai nhìn thấy cho tới lúc báo cáo lợi nhuận sai.
class SheetTable {
  SheetTable(this.name, List<List<String>> rows)
    : headers = rows.isEmpty
          ? const []
          : rows.first.map((h) => h.trim()).toList(),
      dataRows = rows.length <= 1 ? const [] : rows.sublist(1);

  final String name;

  /// Tiêu đề **giữ nguyên như trong file**.
  ///
  /// Không viết thường sẵn: khi app phải kể lại *"các cột đọc được là…"* thì
  /// nó phải kể đúng tên thật. Một câu báo lỗi ghi `mã vận đơn` trong khi file
  /// ghi `Mã vận đơn` biến chính thứ đang cần đối chiếu thành thứ không đối
  /// chiếu được.
  ///
  /// Việc so khớp bỏ qua hoa/thường nằm ở [_indexOf], không nằm ở dữ liệu.
  final List<String> headers;

  final List<List<String>> dataRows;

  bool get isEmpty => dataRows.isEmpty;

  bool hasColumn(String column) => _indexOf(column) >= 0;

  int _indexOf(String column) {
    final wanted = column.trim().toLowerCase();
    for (var i = 0; i < headers.length; i++) {
      if (headers[i].toLowerCase() == wanted) return i;
    }
    return -1;
  }

  /// Các cột bắt buộc còn thiếu — để báo **một lần, đủ cả danh sách**, thay vì
  /// bắt người bán sửa từng cột rồi thử lại năm lần.
  List<String> missingColumns(Iterable<String> required) => [
    for (final c in required)
      if (!hasColumn(c)) c,
  ];

  /// Giá trị ô, `''` khi cột không tồn tại hoặc dòng ngắn hơn.
  String cell(List<String> row, String column) {
    final index = _indexOf(column);
    if (index < 0 || index >= row.length) return '';
    return row[index].trim();
  }

  /// `null` khi ô rỗng — **không** rơi về 0. Ô trống nghĩa là *chưa nhập*, và
  /// đó là thứ phải đi tới tận cột `NULL` trong cơ sở dữ liệu (ADR-TON-023).
  double? number(List<String> row, String column) {
    final raw = cell(row, column);
    if (raw.isEmpty) return null;
    // File người Việt xuất ra hay có dấu phân cách nghìn.
    final cleaned = raw
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '');
    return double.tryParse(cleaned);
  }

  int? integer(List<String> row, String column) => number(row, column)?.round();

  DateTime? date(List<String> row, String column) {
    final raw = cell(row, column);
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;

    // Excel lưu ngày thành số ngày kể từ 1899-12-30 khi ô có định dạng ngày.
    final serial = double.tryParse(raw);
    if (serial == null) return null;
    return DateTime(1899, 12, 30).add(Duration(days: serial.round()));
  }
}
