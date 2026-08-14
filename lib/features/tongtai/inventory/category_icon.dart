import 'package:flutter/material.dart';

import 'product_category.dart';

/// **Danh mục → biểu tượng** — WTM-414.
///
/// Đây là ánh xạ **trình bày của miền**, nên nó sống cạnh miền chứ không trong
/// tệp màn (cùng khuôn `inventory_tone.dart` — DS-2/WTM-415).
///
/// ⚠️ Trả `IconData`, **không** trả `Color`. Biểu tượng là kênh phân biệt duy
/// nhất của ô ảnh; màu ở đó trung tính, vì màu trong app này đã có chủ (luật
/// màu Founder: cam = hành động, tím = AI, xanh lá = tích cực…). Mượn chúng cho
/// 13 danh mục là dạy mắt một nghĩa thứ hai cho cùng một màu.
///
/// Danh mục lạ (người bán tự đặt) ⇒ biểu tượng chung, không đoán.
IconData tongtaiCategoryIcon(String category) =>
    switch (ProductCategory.parse(category)) {
      ProductCategory.electronics => Icons.devices_other_outlined,
      ProductCategory.homeAppliances => Icons.chair_outlined,
      ProductCategory.fashion => Icons.checkroom_outlined,
      ProductCategory.cosmetics => Icons.brush_outlined,
      ProductCategory.motherBaby => Icons.child_friendly_outlined,
      ProductCategory.sports => Icons.sports_soccer_outlined,
      ProductCategory.stationery => Icons.edit_outlined,
      ProductCategory.toys => Icons.toys_outlined,
      ProductCategory.accessories => Icons.watch_outlined,
      ProductCategory.beverages => Icons.local_cafe_outlined,
      ProductCategory.food => Icons.restaurant_outlined,
      ProductCategory.combo => Icons.inventory_2_outlined,
      ProductCategory.dessert => Icons.cake_outlined,
      null => Icons.category_outlined,
    };
