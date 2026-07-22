import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/producer/supplier.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorite.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_controller.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/producer/supplier_search_service.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_supplier_favorites_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_supplier_search_screen.dart';

/// Real widget tests for WTM-65 through the rendered UI: the one-tap heart
/// toggle + filled-icon indication (AC1/AC2), the most-recently-added ordering
/// of the Favorites list (AC3), and the favorites-only search filter (AC4).
void main() {
  Supplier byId(String id) => kSampleSuppliers.firstWhere((s) => s.id == id);

  SupplierFavoritesController seeded(List<SupplierFavorite> favorites) =>
      SupplierFavoritesController(InMemorySupplierFavoritesStore(favorites));

  group('Favorites list screen', () {
    testWidgets('shows an empty state when there are no favorites', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TongtaiSupplierFavoritesScreen(
            favorites: SupplierFavoritesController.inMemory(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No favorite suppliers yet'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('lists favorites most-recently-added first (AC3)', (
      tester,
    ) async {
      final controller = seeded([
        SupplierFavorite(supplierId: 's2', addedAt: DateTime(2026, 7, 10)),
        SupplierFavorite(supplierId: 's5', addedAt: DateTime(2026, 7, 16)),
        SupplierFavorite(supplierId: 's1', addedAt: DateTime(2026, 7, 12)),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: TongtaiSupplierFavoritesScreen(favorites: controller),
        ),
      );
      await tester.pumpAndSettle();

      final newest = tester.getTopLeft(find.text(byId('s5').name)).dy;
      final middle = tester.getTopLeft(find.text(byId('s1').name)).dy;
      final oldest = tester.getTopLeft(find.text(byId('s2').name)).dy;
      expect(newest, lessThan(middle));
      expect(middle, lessThan(oldest));
    });

    testWidgets('tapping the filled heart removes the favorite (AC1/AC2)', (
      tester,
    ) async {
      final controller = seeded([
        SupplierFavorite(supplierId: 's1', addedAt: DateTime(2026, 7, 16)),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: TongtaiSupplierFavoritesScreen(favorites: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(byId('s1').name), findsOneWidget);
      // The favorite indicator is a filled heart.
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.byTooltip('Remove from favorites'));
      await tester.pumpAndSettle();

      expect(controller.isFavorite('s1'), isFalse);
      expect(find.text(byId('s1').name), findsNothing);
      expect(find.text('No favorite suppliers yet'), findsOneWidget);
    });
  });

  group('Search screen — favorites integration', () {
    testWidgets('card heart toggles favorite state with one tap (AC1/AC2)', (
      tester,
    ) async {
      final controller = SupplierFavoritesController.inMemory();
      final service = SupplierSearchService([byId('s1')]); // single card

      await tester.pumpWidget(
        MaterialApp(
          home: TongtaiSupplierSearchScreen(
            service: service,
            favorites: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Not yet a favorite: outline heart offering to add.
      expect(find.byTooltip('Add to favorites'), findsOneWidget);
      expect(find.byTooltip('Remove from favorites'), findsNothing);

      await tester.tap(find.byTooltip('Add to favorites'));
      await tester.pumpAndSettle();

      // Now favorited: filled heart + populated app-bar badge.
      expect(controller.isFavorite('s1'), isTrue);
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('1')),
        findsOneWidget,
      );

      // Tapping again un-favorites.
      await tester.tap(find.byTooltip('Remove from favorites'));
      await tester.pumpAndSettle();
      expect(controller.isFavorite('s1'), isFalse);
      expect(find.byTooltip('Add to favorites'), findsOneWidget);
    });

    testWidgets('favorites-only filter narrows the results (AC4)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = seeded([
        SupplierFavorite(supplierId: 's2', addedAt: DateTime(2026, 7, 16)),
      ]);
      final service = SupplierSearchService([
        byId('s1'),
        byId('s2'),
        byId('s4'),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: TongtaiSupplierSearchScreen(
            service: service,
            favorites: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All three suppliers show before filtering.
      expect(find.text(byId('s1').name), findsOneWidget);
      expect(find.text(byId('s2').name), findsOneWidget);
      expect(find.text(byId('s4').name), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Favorites'));
      await tester.pumpAndSettle();

      // Only the favorited supplier remains.
      expect(find.text(byId('s2').name), findsOneWidget);
      expect(find.text(byId('s1').name), findsNothing);
      expect(find.text(byId('s4').name), findsNothing);
    });

    testWidgets(
      'favorites-only with no favorites shows a helpful empty state',
      (tester) async {
        final service = SupplierSearchService([byId('s1'), byId('s2')]);

        await tester.pumpWidget(
          MaterialApp(
            home: TongtaiSupplierSearchScreen(
              service: service,
              favorites: SupplierFavoritesController.inMemory(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilterChip, 'Favorites'));
        await tester.pumpAndSettle();

        expect(find.text('No favorite suppliers match'), findsOneWidget);
        expect(find.text(byId('s1').name), findsNothing);
      },
    );
  });
}
