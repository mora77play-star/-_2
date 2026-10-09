import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const SanterApp());
}

const bg = Color(0xFF0B1020);
const panel = Color(0xFF151D32);
const blue = Color(0xFF6385FF);
const purple = Color(0xFF9B7BFF);
const green = Color(0xFF35D6A0);
const red = Color(0xFFFF6685);

class Store {
  static late SharedPreferences _prefs;
  static List<Map<String, dynamic>> students = [];
  static List<Map<String, dynamic>> teachers = [];
  static List<Map<String, dynamic>> payments = [];
  static List<Map<String, dynamic>> recitations = [];
  static Map<String, dynamic> attendance = {};

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    students = _readList('students');
    teachers = _readList('teachers');
    payments = _readList('payments');
    recitations = _readList('recitations');
    try {
      attendance = Map<String, dynamic>.from(
        jsonDecode(_prefs.getString('attendance') ?? '{}') as Map,
      );
    } catch (_) {
      attendance = {};
    }
  }

  static List<Map<String, dynamic>> _readList(String key) {
    try {
      final decoded = jsonDecode(_prefs.getString(key) ?? '[]') as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveList(String key, List data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  static Future<void> saveAttendance() async {
    await _prefs.setString('attendance', jsonEncode(attendance));
  }

  static String get password =>
      _prefs.getString('admin_password') ?? '123456';

  static Future<void> setPassword(String value) async {
    await _prefs.setString('admin_password', value);
  }

  static double sum(List<Map<String, dynamic>> list, String key) =>
      list.fold<double>(
        0,
        (total, item) => total + ((item[key] as num?)?.toDouble() ?? 0),
      );
}

class SanterApp extends StatelessWidget {
  const SanterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SANTER PRO',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(color: panel, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final passwordController = TextEditingController();
  String error = '';

  Future<void> login() async {
    if (passwordController.text != Store.password) {
      setState(() => error = 'كلمة المرور غير صحيحة');
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [blue, purple]),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(Icons.school_rounded, size: 55),
                  ),
                  const SizedBox(height: 25),
                  const Text('SANTER PRO',
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('نظام إدارة السنتر التعليمي'),
                  const SizedBox(height: 35),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    onSubmitted: (_) => login(),
                    decoration: const InputDecoration(
                      labelText: 'كلمة مرور الإدارة',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(error, style: const TextStyle(color: red)),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 53,
                    child: FilledButton(
                      onPressed: login,
                      child: const Text('تسجيل الدخول'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('كلمة المرور الأولية: 123456',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
        ),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int page = 0;

  final titles = const [
    'الرئيسية',
    'الطلاب',
    'المدرسون',
    'الحضور والغياب',
    'التسميع',
    'المصروفات',
    'الإعدادات',
  ];

  final icons = const [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.cast_for_education_rounded,
    Icons.fact_check_rounded,
    Icons.menu_book_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.settings_rounded,
  ];

  double get totalFees => Store.sum(Store.students, 'fees');
  double get totalPaid => Store.sum(Store.payments, 'amount');

  List<Map<String, dynamic>> listFor(int index) => switch (index) {
        1 => Store.students,
        2 => Store.teachers,
        4 => Store.recitations,
        5 => Store.payments,
        _ => [],
      };

  String keyFor(int index) => switch (index) {
        1 => 'students',
        2 => 'teachers',
        4 => 'recitations',
        5 => 'payments',
        _ => '',
      };

  void toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String?> askText(String label,
      {String initial = '', bool numeric = false}) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: panel,
          title: Text(label),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: const InputDecoration(hintText: 'اكتب هنا'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> addRecord(int index) async {
    final name = await askText(index == 2 ? 'اسم المدرس' : index == 5 ? 'اسم الطالب' : 'اسم الطالب');
    if (name == null || name.isEmpty || !mounted) return;

    final item = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': name,
      'date': DateTime.now().toIso8601String(),
    };

    if (index == 1) {
      final grade = await askText('الصف الدراسي');
      if (grade == null || !mounted) return;
      final phone = await askText('رقم ولي الأمر');
      if (phone == null || !mounted) return;
      final feesText = await askText('المصروفات المطلوبة بالجنيه', numeric: true);
      if (feesText == null || !mounted) return;
      final fees = double.tryParse(feesText);
      if (fees == null || fees < 0) {
        toast('اكتب مبلغًا صحيحًا');
        return;
      }
      item.addAll({'grade': grade, 'phone': phone, 'fees': fees});
      Store.students.add(item);
      await Store.saveList('students', Store.students);
    } else if (index == 2) {
      final subject = await askText('المادة الدراسية');
      if (subject == null || !mounted) return;
      final phone = await askText('رقم الهاتف');
      if (phone == null || !mounted) return;
      item.addAll({'subject': subject, 'phone': phone});
      Store.teachers.add(item);
      await Store.saveList('teachers', Store.teachers);
    } else if (index == 4) {
      final details = await askText('درجة التسميع والملاحظات');
      if (details == null || !mounted) return;
      item['details'] = details;
      Store.recitations.add(item);
      await Store.saveList('recitations', Store.recitations);
    } else if (index == 5) {
      final amountText = await askText('المبلغ المدفوع بالجنيه', numeric: true);
      if (amountText == null || !mounted) return;
      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        toast('اكتب مبلغًا صحيحًا');
        return;
      }
      item['amount'] = amount;
      Store.payments.add(item);
      await Store.saveList('payments', Store.payments);
    } else if (index == 3) {
      final status = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: panel,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final s in ['حاضر', 'غائب', 'متأخر'])
                  ListTile(title: Text(s), onTap: () => Navigator.pop(ctx, s)),
              ],
            ),
          ),
        ),
      );
      if (status == null || !mounted) return;
      item['status'] = status;
      Store.attendance.add(item);
      await Store.saveList('attendance', Store.attendance);
    }

    if (!mounted) return;
    setState(() {});
    toast('تم الحفظ على الجهاز تلقائيًا');
  }

  Future<void> deleteRecord(int index, int i) async {
    final list = index == 3 ? Store.attendance : listFor(index);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panel,
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا السجل؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    list.removeAt(i);
    if (index == 3) {
      await Store.saveList('attendance', Store.attendance);
    } else {
      await Store.saveList(keyFor(index), list);
    }
    setState(() {});
    toast('تم الحذف وحفظ التعديل');
  }

  Widget stat(String title, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 27),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(color: Colors.white60)),
          ],
        ),
      );

  Widget dashboard() => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('أهلاً بيك في الإدارة 👋',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('كل تفاصيل السنتر في مكان واحد',
              style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 22),
          SizedBox(
            height: 260,
            child: GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                stat('الطلاب', '${Store.students.length}', Icons.people, blue),
                stat('المدرسون', '${Store.teachers.length}', Icons.school, purple),
                stat('المطلوب', '${totalFees.toStringAsFixed(0)} ج.م', Icons.account_balance_wallet, green),
                stat('المحصل', '${totalPaid.toStringAsFixed(0)} ج.م', Icons.payments, Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('الإدارة السريعة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          for (int i = 1; i < titles.length; i++)
            Card(
              child: ListTile(
                leading: Icon(icons[i], color: blue),
                title: Text(titles[i]),
                trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                onTap: () => setState(() => page = i),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ملخص الحسابات',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('المطلوب: ${totalFees.toStringAsFixed(2)} جنيه'),
                  Text('المحصل: ${totalPaid.toStringAsFixed(2)} جنيه'),
                  Text('المتبقي: ${(totalFees - totalPaid).clamp(0, double.infinity).toStringAsFixed(2)} جنيه'),
                ],
              ),
            ),
          ),
        ],
      );

  Widget recordsPage(int index) {
    final list = index == 3 ? Store.attendance : listFor(index);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(titles[index],
                    style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
              ),
              FilledButton.icon(
                onPressed: () => addRecord(index),
                icon: const Icon(Icons.add),
                label: const Text('إضافة'),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('لا توجد بيانات حتى الآن', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final item = list[i];
                    final subtitle = index == 1
                        ? '${item['grade'] ?? ''} • ${item['phone'] ?? ''} • ${item['fees'] ?? 0} ج.م'
                        : index == 2
                            ? '${item['subject'] ?? ''} • ${item['phone'] ?? ''}'
                            : index == 3
                                ? '${item['status'] ?? ''} • ${item['date'] ?? ''}'
                                : index == 4
                                    ? '${item['details'] ?? ''}'
                                    : index == 5
                                        ? '${item['amount'] ?? 0} ج.م'
                                        : '';
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: blue.withAlpha(40),
                          child: Icon(icons[index], color: blue),
                        ),
                        title: Text(item['name']?.toString() ?? ''),
                        subtitle: Text(subtitle),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: red),
                          onPressed: () => deleteRecord(index, i),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> changePassword() async {
    final oldPass = await askText('كلمة المرور الحالية');
    if (oldPass == null || !mounted) return;
    if (oldPass != Store.password) {
      toast('كلمة المرور الحالية غير صحيحة');
      return;
    }
    final newPass = await askText('كلمة المرور الجديدة');
    if (newPass == null || !mounted) return;
    if (newPass.length < 6) {
      toast('استخدم 6 أحرف على الأقل');
      return;
    }
    await Store.setPassword(newPass);
    if (mounted) toast('تم تغيير كلمة المرور');
  }

  @override
  Widget build(BuildContext context) {
    final views = [
      dashboard(),
      recordsPage(1),
      recordsPage(2),
      recordsPage(3),
      recordsPage(4),
      recordsPage(5),
      Center(
        child: FilledButton.icon(
          onPressed: changePassword,
          icon: const Icon(Icons.lock_reset),
          label: const Text('تغيير كلمة المرور'),
        ),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: panel,
          title: const Text('SANTER PRO',
              style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: panel,
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    children: [
                      Icon(Icons.school, size: 50, color: blue),
                      SizedBox(height: 10),
                      Text('إدارة السنتر',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: titles.length,
                    itemBuilder: (ctx, i) => ListTile(
                      selected: page == i,
                      leading: Icon(icons[i]),
                      title: Text(titles[i]),
                      onTap: () {
                        setState(() => page = i);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: IndexedStack(index: page, children: views),
        bottomNavigationBar: NavigationBar(
          selectedIndex: page < 4 ? page : 0,
          onDestinationSelected: (i) => setState(() => page = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.people_outline), label: 'الطلاب'),
            NavigationDestination(icon: Icon(Icons.school_outlined), label: 'المدرسون'),
            NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'الحضور'),
          ],
        ),
      ),
    );
  }
}
