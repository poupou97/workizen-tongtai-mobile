/// Tổng Tài feature module — AI-powered business assistant app.
/// Exports all public APIs for navigation, screens, and providers.
library;

// Navigation & UI Shell
export 'ui/tongtai_app_shell.dart';
export 'ui/tongtai_bottom_nav.dart';
export 'ui/tongtai_root_gate.dart';
export 'navigation/tongtai_design_tokens.dart';

// Onboarding tutorial (WTM-59)
export 'onboarding/tongtai_onboarding_content.dart';
export 'onboarding/tongtai_onboarding_store.dart';
export 'providers/tongtai_onboarding_provider.dart';
export 'ui/screens/tongtai_onboarding_screen.dart';

// Deep linking (WTM-57)
export 'navigation/deeplink/tongtai_deep_link.dart';
export 'navigation/deeplink/tongtai_deep_link_parser.dart';
export 'navigation/deeplink/tongtai_deep_link_provider.dart';

// Persistent tab-state widgets (WTM-56)
export 'ui/widgets/tongtai_persistent_scroll_view.dart';
export 'ui/widgets/tongtai_persistent_text_field.dart';
export 'ui/widgets/tongtai_fox_mascot.dart';

// State models & store (WTM-56)
export 'state/tongtai_tab_state.dart';
export 'state/tongtai_tab_state_store.dart';

// Providers
export 'providers/tongtai_navigation_provider.dart';
export 'providers/tongtai_tab_state_provider.dart';

// Offline-first sync queue & conflict resolution (WTM-54)
export 'sync/sync_operation.dart';
export 'sync/sync_queue_repository.dart';

// Producer — supplier search (WTM-63)
export 'producer/supplier.dart';
export 'producer/supplier_search_service.dart';

// Producer — supplier detail (WTM-64)
export 'producer/supplier_profile.dart';

// Producer — supplier favorites (WTM-65)
export 'producer/supplier_favorite.dart';
export 'producer/supplier_favorites_store.dart';
export 'producer/supplier_favorites_controller.dart';

// Inventory — product list (WTM-68)
export 'inventory/product.dart';
export 'inventory/product_inventory_service.dart';

// Inventory — add/edit product (WTM-69)
export 'inventory/product_history.dart';
export 'inventory/product_form.dart';
export 'inventory/product_image_source.dart';
export 'inventory/product_catalog_controller.dart';
export 'inventory/product_repository.dart';
export 'providers/tongtai_inventory_provider.dart';
export 'ui/screens/tongtai_product_form_screen.dart';

// Inventory — stock level alerts (WTM-70)
export 'inventory/stock_alert.dart';
export 'inventory/stock_alert_service.dart';
export 'ui/screens/tongtai_stock_alerts_screen.dart';

// Consumer — customer list (WTM-75)
export 'consumer/customer.dart';
export 'consumer/customer_directory_service.dart';

// Chat — AI Copilot chat UI (WTM-80)
export 'chat/chat_message.dart';
export 'chat/chat_controller.dart';
export 'ui/screens/tongtai_chat_screen.dart';

// Chat — message persistence, local-only per ADR-TON-004 (WTM-81)
export 'chat/chat_message_store.dart';

// Chat — search & history (WTM-84)
export 'ui/screens/tongtai_chat_search_screen.dart';

// Consumer — add/edit customer (WTM-76)
export 'consumer/customer_history.dart';
export 'consumer/customer_form.dart';
export 'consumer/customer_directory_controller.dart';
export 'ui/screens/tongtai_customer_form_screen.dart';

// Consumer — purchase history (WTM-77)
export 'consumer/customer_order.dart';
export 'consumer/customer_order_history_service.dart';
export 'ui/screens/tongtai_customer_history_screen.dart';

// Reports & Analytics — sales dashboard (WTM-95/96)
export 'reports/business_report.dart';
export 'ui/screens/tongtai_reports_screen.dart';

// Finance — income/expense dashboard (WTM-27) + transaction entry (WTM-113)
//        + Drift persistence, User Data First (WTM-120)
export 'core/local_workspace.dart';
export 'finance/finance_transaction.dart';
export 'finance/finance_summary.dart';
export 'finance/finance_repository.dart';
export 'finance/finance_controller.dart';
export 'finance/transaction_form.dart';
export 'providers/tongtai_finance_provider.dart';
export 'ui/screens/tongtai_finance_screen.dart';
export 'ui/screens/tongtai_transaction_form_screen.dart';

// Opportunity — detail & action plan (WTM-92) + pipeline summary (WTM-98)
export 'opportunity/opportunity_action_plan.dart';
export 'opportunity/opportunity_pipeline.dart';
export 'opportunity/opportunity_theme.dart';
export 'ui/screens/tongtai_opportunity_detail_screen.dart';

// Timeline — event-driven business feed (WTM-114)
export 'timeline/business_event.dart';
export 'timeline/business_event_sources.dart';
export 'timeline/timeline_service.dart';
export 'timeline/timeline_theme.dart';
export 'ui/screens/tongtai_timeline_screen.dart';

// Journey — business goals (WTM-87) + goal detail & action plan (WTM-88)
export 'journey/business_goal.dart';
export 'journey/business_goal_form.dart';
export 'journey/business_goal_controller.dart';
export 'journey/goal_action_plan.dart';
export 'journey/goal_theme.dart';
export 'ui/screens/tongtai_goal_form_screen.dart';
export 'ui/screens/tongtai_goals_screen.dart';
export 'ui/screens/tongtai_goal_detail_screen.dart';

// Opportunity — feed (WTM-91)
export 'opportunity/opportunity.dart';
export 'opportunity/opportunity_feed_controller.dart';
export 'ui/screens/tongtai_opportunity_feed_screen.dart';

// Workizen AI Router — multi-provider routing + context injection (WTM-82,
// ADR-TON-006)
export 'ai/workizen_ai_context.dart';
export 'ai/workizen_ai_router.dart';

// Export — CSV data export (WTM-99, D-10 Phase 2)
export 'export/csv_exporter.dart';
export 'export/csv_delivery.dart';
export 'export/export_history_store.dart';
export 'ui/screens/tongtai_export_screen.dart';

// AI client — xAI Grok BYOK integration (WTM-61)
export 'ai/tongtai_ai_provider_kind.dart';
export 'ai/tongtai_ai_key_store.dart';
export 'ai/tongtai_ai_key_validator.dart';
export 'ai/tongtai_ai_errors.dart';
export 'ai/tongtai_ai_models.dart';
export 'ai/tongtai_ai_client.dart';
export 'ai/tongtai_ai_service.dart';
export 'providers/tongtai_ai_provider.dart';
export 'ui/screens/tongtai_ai_key_screen.dart';

// Screens (for testing and custom routing)
export 'ui/screens/tongtai_home_screen.dart';
export 'ui/screens/tongtai_producer_screen.dart';
export 'ui/screens/tongtai_inventory_screen.dart';
export 'ui/screens/tongtai_consumer_screen.dart';
export 'ui/screens/tongtai_more_screen.dart';
export 'ui/screens/tongtai_component_showcase_screen.dart';
export 'ui/screens/tongtai_supplier_search_screen.dart';
export 'ui/screens/tongtai_supplier_detail_screen.dart';
export 'ui/screens/tongtai_supplier_favorites_screen.dart';
export 'ui/screens/tongtai_customer_list_screen.dart';
