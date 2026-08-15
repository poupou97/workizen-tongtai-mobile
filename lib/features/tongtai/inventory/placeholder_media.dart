/// **URL ảnh giữ chỗ — không bao giờ là ảnh sản phẩm** (WTM-418).
///
/// ## Vì sao cần một danh sách host, không phải một cờ trong dữ liệu
///
/// Bộ dữ liệu demo có cột `image_url` điền `picsum.photos/seed/…`. Nhìn vào một
/// hàng thì nó **giống hệt** một URL ảnh thật: đúng lược đồ, đúng đuôi, tải về
/// được, ra một tấm ảnh 400×400. Không có gì trong bản ghi nói rằng tấm ảnh ấy
/// là **ngẫu nhiên**.
///
/// Cái sai nằm ở *nguồn*, không ở *định dạng*: những host này trả ảnh theo
/// seed hoặc theo kích thước, hoàn toàn không liên quan tới thứ hàng đang bán.
/// Nên chỗ duy nhất kiểm được là danh sách host — và nó phải nằm ở một chỗ, để
/// đường nhập và đường đọc dùng chung một định nghĩa.
///
/// ## Vì sao chặn cả file của người dùng thật, không chỉ file demo
///
/// Nếu file người bán tự nhập có một URL picsum, đó vẫn không phải ảnh hàng của
/// họ — nhiều khả năng là dữ liệu mẫu họ copy từ đâu đó. Hiển thị nó là để một
/// tấm ảnh ngẫu nhiên tự xưng là hàng của họ. Bỏ trống trung thực hơn: app đã
/// có ô ảnh mặc định cho đúng trạng thái *"chưa có ảnh"*.
library;

/// Host chuyên phát ảnh ngẫu nhiên / ảnh giữ chỗ.
const _placeholderHosts = <String>{
  'picsum.photos',
  'loremflickr.com',
  'placeimg.com',
  'placehold.co',
  'placeholder.com',
  'via.placeholder.com',
  'dummyimage.com',
  'baconmockup.com',
  'placekitten.com',
};

/// `true` nếu [url] trỏ tới một dịch vụ ảnh giữ chỗ.
///
/// So theo **host**, không phải `contains` trên cả chuỗi: một đường dẫn thật
/// hoàn toàn có thể chứa chữ "placeholder" trong tên tệp mà vẫn là ảnh thật.
bool isPlaceholderMediaUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final host = Uri.tryParse(url)?.host.toLowerCase();
  if (host == null || host.isEmpty) return false;
  return _placeholderHosts.contains(host) ||
      _placeholderHosts.any((h) => host.endsWith('.$h'));
}
