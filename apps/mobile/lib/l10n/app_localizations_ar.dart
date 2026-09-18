// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'حسابلي';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navTransactions => 'المعاملات';

  @override
  String get navReports => 'التقارير';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get placeholderTitle => 'قيد التطوير';

  @override
  String get placeholderMessage => 'هذه الشاشة ستُبنى في مرحلة تطوير الميزات.';

  @override
  String get commonLoading => 'جارٍ التحميل…';

  @override
  String get commonError => 'حدث خطأ غير متوقع.';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonEmpty => 'لا توجد بيانات بعد.';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonConfirm => 'تأكيد';

  @override
  String get commonDelete => 'حذف';

  @override
  String get egpSymbol => 'ج.م';
}
