/// **Danh mục sản phẩm** — WTM-393.
///
/// ## Vì sao thứ này phải tồn tại
///
/// `Product.category` là `String` **tự do**, và nó có **hai chủ** cùng ghi vào:
/// bộ nhập XLSX (`assets/demo/TongTai-Commerce-Demo-100-Products.xlsx`) ghi
/// **nhãn tiếng Việt** ("Điện tử", "Gia dụng"…), còn bộ sinh dữ liệu lịch sử
/// (`historical_data_generator.dart`) ghi **nhãn tiếng Anh** ('Electronics',
/// 'Home', 'Textiles', 'Fashion', 'Accessories'). Màn Kho in ra nguyên xi thứ
/// nó nhận được.
///
/// Trên máy thật (Nokia 6.1, audit WTM-392) người bán nhìn thấy chip "Accessories"
/// và "Electronics" đứng ngay cạnh "Điện tử", "Thời trang" — và sản phẩm mang
/// nhãn "Home". Cùng một khái niệm, hai hệ đặt tên, hai bộ chip. Đó là **Business
/// Truth mâu thuẫn trên một màn hình**, đúng hình dạng P-27/P-28 quen thuộc: một
/// khái niệm, hai chủ — và cũng là **bài học `114 products`** tái diễn.
///
/// ## Cách chữa: một bộ từ vựng ĐÓNG (đúng khuôn [CustomerSegment], WTM-381)
///
/// Mã canonical để **lưu** (ADR-TON-018: enum lưu bằng mã, cấm nhãn hiển thị),
/// nhãn để **hiện** (ADR-TON-007: UI một locale, chuỗi đi qua một chỗ). Đây
/// **không** phải taxonomy thứ hai — nó là *chủ sở hữu duy nhất* mà cả hai nguồn
/// quy về.
///
/// [ProductCategory.parse] cố ý nhận **cả nhãn tiếng Anh cũ lẫn nhãn tiếng Việt**:
/// dữ liệu đã seed trên máy người dùng đang mang nhãn hiển thị, và bắt họ nạp lại
/// chỉ để sửa một cái tên là đổi giá phải trả sang phía sai người. Dữ liệu cũ
/// **tự lành lúc đọc**, không cần migration (Founder 2026-08-13: "cấm migration
/// lớn ngoài scope").
///
/// ⛔ Chuỗi **không** phân giải được thì vẫn hiện nguyên văn — đó là danh mục
/// người bán tự đặt (một lần nhập Shopee "Đặc sản quê"), và im lặng nuốt nó đi
/// còn tệ hơn in ra một mã máy.
library;

enum ProductCategory {
  electronics('electronics'),
  homeAppliances('home_appliances'),
  fashion('fashion'),
  cosmetics('cosmetics'),
  motherBaby('mother_baby'),
  sports('sports'),
  stationery('stationery'),
  toys('toys'),
  accessories('accessories'),
  beverages('beverages'),
  food('food'),
  combo('combo'),
  dessert('dessert');

  const ProductCategory(this.code);

  /// Mã canonical — thứ **được lưu**, và thứ mọi nguồn dữ liệu quy về.
  final String code;

  String get labelVi => switch (this) {
    ProductCategory.electronics => 'Điện tử',
    ProductCategory.homeAppliances => 'Gia dụng',
    ProductCategory.fashion => 'Thời trang',
    ProductCategory.cosmetics => 'Mỹ phẩm',
    ProductCategory.motherBaby => 'Mẹ & Bé',
    ProductCategory.sports => 'Thể thao',
    ProductCategory.stationery => 'Văn phòng phẩm',
    ProductCategory.toys => 'Đồ chơi',
    ProductCategory.accessories => 'Phụ kiện',
    ProductCategory.beverages => 'Đồ uống',
    ProductCategory.food => 'Đồ ăn',
    ProductCategory.combo => 'Combo',
    ProductCategory.dessert => 'Tráng miệng',
  };

  String get labelEn => switch (this) {
    ProductCategory.electronics => 'Electronics',
    ProductCategory.homeAppliances => 'Home appliances',
    ProductCategory.fashion => 'Fashion',
    ProductCategory.cosmetics => 'Cosmetics',
    ProductCategory.motherBaby => 'Mother & baby',
    ProductCategory.sports => 'Sports',
    ProductCategory.stationery => 'Stationery',
    ProductCategory.toys => 'Toys',
    ProductCategory.accessories => 'Accessories',
    ProductCategory.beverages => 'Beverages',
    ProductCategory.food => 'Food',
    ProductCategory.combo => 'Combo',
    ProductCategory.dessert => 'Dessert',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;

  /// Phân giải một chuỗi bất kỳ về danh mục canonical, hoặc `null` khi đó là
  /// chữ của chính người bán.
  ///
  /// Nhận bốn dạng, và **phải** nhận cả bốn:
  ///
  /// * mã canonical (`electronics`, `home_appliances`) — thứ nay được ghi xuống;
  /// * nhãn tiếng Việt (`Điện tử`) — thứ bộ nhập XLSX đã ghi;
  /// * nhãn tiếng Anh (`Electronics`) — thứ bộ sinh lịch sử đã ghi;
  /// * vài biến thể tiếng Anh cũ đã thật sự nằm trong dữ liệu đã seed
  ///   (`Home`, `Textiles`, `Smart Home`…).
  static ProductCategory? parse(String raw) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final c in ProductCategory.values) {
      if (key == c.code ||
          key == c.labelVi.toLowerCase() ||
          key == c.labelEn.toLowerCase()) {
        return c;
      }
    }
    return switch (key) {
      // Mỗi dòng là một thứ đã thấy trong dữ liệu thật (generator/XLSX/marketplace),
      // không phải phỏng đoán cho đẹp danh sách.
      'home' ||
      'home goods' ||
      'smart home' ||
      'household' ||
      'đồ gia dụng' => ProductCategory.homeAppliances,
      'textiles' ||
      'apparel' ||
      'clothing' ||
      'quần áo' => ProductCategory.fashion,
      'beauty' || 'làm đẹp' => ProductCategory.cosmetics,
      'mother & baby' ||
      'mom & baby' ||
      'mẹ và bé' ||
      'mẹ&bé' ||
      'baby' => ProductCategory.motherBaby,
      'sport' => ProductCategory.sports,
      'office supplies' ||
      'office' ||
      'stationary' => ProductCategory.stationery,
      'toy' => ProductCategory.toys,
      'accessory' => ProductCategory.accessories,
      'drinks' || 'drink' || 'beverage' => ProductCategory.beverages,
      'foods' || 'thực phẩm' => ProductCategory.food,
      'combos' => ProductCategory.combo,
      'desserts' => ProductCategory.dessert,
      _ => null,
    };
  }

  /// Chuẩn hoá một chuỗi để **lưu**: mã canonical nếu nhận ra, còn không thì
  /// giữ nguyên văn của người bán (đã cắt khoảng trắng thừa).
  static String normalise(String raw) => parse(raw)?.code ?? raw.trim();

  /// Nhãn để **hiện**: nhãn canonical nếu nhận ra, còn không thì nguyên văn.
  static String display(String raw, String languageCode) =>
      parse(raw)?.label(languageCode) ?? raw.trim();
}
