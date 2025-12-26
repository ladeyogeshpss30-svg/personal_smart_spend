import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/theme/app_theme.dart';

// Screens
import 'screens/dashboard_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/expense_list_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/budget_list_screen.dart';
import 'screens/custom_category_screen.dart';

// 🆕 INCOME SCREENS
import 'screens/add_income_screen.dart';
import 'screens/income_list_screen.dart';
import 'screens/income_analytics_screen.dart';

// 🆕 SAVINGS TREND SCREEN
import 'screens/savings_trend_screen.dart';

// 🆕 INCOME VS EXPENSE BAR SCREEN
import 'screens/income_vs_expense_bar_screen.dart';

// Reports (✅ CORRECT ENTRY FLOW)
import 'reports/report_entry_screen.dart';

// Services
import 'services/alert_service.dart';
import 'database/db_helper.dart';
import 'services/category_service.dart';

/// 🌍 Global navigator key
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ads only on mobile
  if (Platform.isAndroid || Platform.isIOS) {
    await MobileAds.instance.initialize();
  }

  // Core initializations
  await DBHelper().database;
  await CategoryService().insertDefaultCategoriesIfNeeded();
  await AlertService().init();

  runApp(const PersonalSmartSpendApp());
}

class PersonalSmartSpendApp extends StatelessWidget {
  const PersonalSmartSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Personal Smart Spend',
      theme: AppTheme.lightTheme,

      // =====================================================
      // 📱 GLOBAL SAFE AREA (FINAL)
      // =====================================================
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            padding: EdgeInsets.only(
              top: media.padding.top,
              bottom: media.padding.bottom,
            ),
          ),
          child: SafeArea(
            top: true,
            bottom: true,
            child: child!,
          ),
        );
      },

      // 🏠 HOME
      home: const DashboardScreen(),

      // =====================================================
      // 🔥 ROUTES (UPDATED WITH INCOME VS EXPENSE)
      // =====================================================
      routes: {
        // Expenses
        '/expenses': (_) => const ExpenseListScreen(),
        '/add-expense': (_) => const AddExpenseScreen(),

        // Income
        '/income': (_) => IncomeListScreen(),
        '/add-income': (_) => const AddIncomeScreen(),
        '/income-analytics': (_) => const IncomeAnalyticsScreen(),

        // 🆕 Savings Trend
        '/savings-trend': (_) => const SavingsTrendScreen(),

        // 🆕 Income vs Expense (Bar Chart)
        '/income-vs-expense': (_) =>
            const IncomeVsExpenseBarScreen(),

        // Analytics & Budgets
        '/analytics': (_) => const AnalyticsScreen(),
        '/budgets': (_) => const BudgetListScreen(),

        // Categories
        '/categories': (_) => const CustomCategoryScreen(),

        // Reports (ENTRY → PREVIEW FLOW)
        '/reports': (_) => const ReportEntryScreen(),
      },
    );
  }
}
