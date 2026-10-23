
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(const AlRaaiApp());

class AlRaaiApp extends StatelessWidget {
  const AlRaaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'الراعي',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Arial',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC97A2B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Animal {
  String name;
  String type;
  String gender;
  String color;
  DateTime? birthDate;
  String age;
  String weight;
  String price;
  String pen;
  String purpose;

  Animal({
    this.name = '',
    this.type = 'ضأن',
    this.gender = 'أنثى',
    this.color = 'أبيض',
    this.birthDate,
    this.age = '',
    this.weight = '',
    this.price = '',
    this.pen = '',
    this.purpose = 'تربية',
  });
}

final List<Animal> animals = [];

/// يحوّل الأرقام العربية (٠-٩) إلى إنجليزية عشان التحقق من الرقم يشتغل.
String normalizeDigits(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  var out = input.trim().replaceAll('٫', '.').replaceAll('،', '.');
  for (var i = 0; i < arabic.length; i++) {
    out = out.replaceAll(arabic[i], '$i');
  }
  return out;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;

  final sections = const [
    ('السجل المرضي', Icons.medical_services_outlined),
    ('التحصين', Icons.vaccines_outlined),
    ('البهـم', Icons.pets_outlined),
    ('قريب الولادة', Icons.child_friendly_outlined),
    ('الذكور', Icons.male),
    ('الإناث', Icons.female),
    ('الصحة الوقائية', Icons.health_and_safety_outlined),
    ('غير دافع', Icons.money_off_outlined),
    ('الدافع', Icons.paid_outlined),
    ('المقرعات', Icons.pets_outlined),
    ('غير منتجة', Icons.groups_outlined),
    ('المقاومة', Icons.groups_2_outlined),
    ('إنتاج الحليب', Icons.local_drink_outlined),
    ('المراضعات', Icons.family_restroom_outlined),
    ('التسمين', Icons.restaurant_outlined),
    ('الفحوصات', Icons.biotech_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 20,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('أهلاً بك ...',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              Text('غنم الوالده',
                  style: TextStyle(fontSize: 17, color: Colors.black87)),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFC97A2B),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                children: [
                  Icon(Icons.note_alt_outlined, color: Colors.white),
                  SizedBox(width: 8),
                  Text('ملاحظات المربي',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFC97A2B),
          foregroundColor: Colors.white,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAnimalPage()),
            );
            setState(() => tab = 2);
          },
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
            NavigationDestination(
                icon: Icon(Icons.storefront_outlined), label: 'سوق الراعي'),
            NavigationDestination(
                icon: Icon(Icons.pets_outlined), label: 'الحلال'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
          ],
        ),
    );
  }

  Widget _buildBody() {
    switch (tab) {
      case 0:
        return _sectionsGrid();
      case 2:
        return _animalsList();
      default:
        return const Center(child: Text('قيد التجهيز'));
    }
  }

  Widget _sectionsGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sections.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: .93,
        ),
        itemBuilder: (context, i) {
          final item = sections[i];
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('قسم ${item.$1} قيد التجهيز')),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4EF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$2, size: 43, color: const Color(0xFFC97A2B)),
                  const SizedBox(height: 12),
                  Text(item.$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _animalsList() {
    if (animals.isEmpty) {
      return const Center(
        child: Text('ما أضفت أي رأس للحين\nاضغط + عشان تضيف',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      itemCount: animals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = animals[i];
        final title = a.name.isEmpty ? '${a.type} - ${a.gender}' : a.name;
        final details = [
          '${a.type} • ${a.gender} • ${a.color}',
          if (a.age.isNotEmpty) a.age,
          if (a.weight.isNotEmpty) '${a.weight} كجم',
          if (a.price.isNotEmpty) '${a.price} ريال',
          if (a.pen.isNotEmpty) 'حظيرة ${a.pen}',
          a.purpose,
        ].join('  |  ');
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4EF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(details),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => animals.removeAt(i)),
            ),
          ),
        );
      },
    );
  }
}

class AddAnimalPage extends StatefulWidget {
  const AddAnimalPage({super.key});

  @override
  State<AddAnimalPage> createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends State<AddAnimalPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final weight = TextEditingController();
  final price = TextEditingController();
  final pen = TextEditingController();

  String type = 'ضأن';
  String gender = 'أنثى';
  String color = 'أبيض';
  String purpose = 'تربية';
  String? age;

  @override
  void dispose() {
    name.dispose();
    weight.dispose();
    price.dispose();
    pen.dispose();
    super.dispose();
  }

  String? numberValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null; // اختياري
    final n = double.tryParse(normalizeDigits(v));
    if (n == null || n < 0) return 'أدخل رقم صحيح';
    return null;
  }

  InputDecoration field(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('إضافة رأس',
              style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8EBDD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('البيانات الأساسية',
                        style: TextStyle(
                            color: Color(0xFFC97A2B),
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text('أضف البيانات الأساسية للرأس ...'),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: type,
                      decoration: field('النوع'),
                      items: ['ضأن', 'ماعز', 'إبل'].map((v) =>
                        DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() => type = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      decoration: field('الجنس'),
                      items: ['أنثى', 'ذكر'].map((v) =>
                        DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() => gender = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: color,
                decoration: field('اختر اللون'),
                items: ['أبيض', 'أسود', 'أشقر', 'بني', 'أحمر', 'متعدد']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => color = v!),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: name,
                decoration: field('اسم الرأس (اختياري)'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: weight,
                      validator: numberValidator,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: field('وزن الرأس - كجم'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: price,
                      validator: numberValidator,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: field('السعر - ريال'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: pen,
                decoration: field('رقم الحظيرة (اختياري)'),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: age,
                decoration: field('العمر'),
                items: ['أقل من سنة', 'سنة', 'سنتان', '3 سنوات', '4 سنوات فأكثر']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => age = v),
              ),
              const SizedBox(height: 18),
              const Text('الغرض',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'تربية', label: Text('تربية')),
                  ButtonSegment(value: 'تسمين', label: Text('تسمين')),
                ],
                selected: {purpose},
                onSelectionChanged: (v) =>
                    setState(() => purpose = v.first),
              ),
              const SizedBox(height: 26),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9DCC00),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  animals.add(Animal(
                    name: name.text.trim(),
                    type: type,
                    gender: gender,
                    color: color,
                    age: age ?? '',
                    weight: normalizeDigits(weight.text),
                    price: normalizeDigits(price.text),
                    pen: normalizeDigits(pen.text),
                    purpose: purpose,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('إضافة', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
    );
  }
}
