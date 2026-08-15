/// SKU của bộ demo **thật sự có ảnh trong bundle** — WTM-414.
///
/// ⚠️ Sinh bằng `tool/fetch_demo_product_images.py` từ chính thư mục
/// `assets/demo/products/`, **không viết tay**: một danh sách viết tay sẽ lệch
/// với thư mục đúng vào ngày ai đó thêm hoặc loại một ảnh, và lúc ấy app hỏi
/// một asset không tồn tại — ô ảnh vỡ, tệ hơn ô ảnh trống.
///
/// Sản phẩm không có tên trong đây dùng **ô ảnh mặc định**. Thiếu ảnh là một
/// trạng thái hợp lệ (Founder: *"45 ảnh đúng + 69 placeholder TỐT HƠN 114 ảnh
/// trong đó nhiều ảnh sai"*).
const Set<String> kDemoProductImageSkus = {
  'DC-015',
  'DC-031',
  'DC-039',
  'DC-071',
  'DT-001',
  'DT-009',
  'DT-033',
  'DT-041',
  'DT-057',
  'DT-065',
  'DT-089',
  'GD-018',
  'GD-042',
  'GD-090',
  'MB-012',
  'MP-019',
  'MP-035',
  'MP-059',
  'TH-005',
  'TH-013',
  'TH-037',
  'TH-077',
  'TH-085',
  'TH-093',
  'TT-016',
  'TT-024',
  'TT-040',
  'TT-048',
  'TT-056',
  'TT-064',
  'VP-006',
  'VP-022',
  'VP-030',
  'VP-038',
  'VP-046',
  'VP-078',
  'VP-086',
};
