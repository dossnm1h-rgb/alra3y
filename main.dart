import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kBrown = Color(0xFFC97A2B);
const kTile = Color(0xFFFBF4EF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.load();
  runApp(const AlRaaiApp());
}

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
          seedColor: kBrown,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ───────────────────────── أدوات مساعدة ─────────────────────────

String two(int n) => n.toString().padLeft(2, '0');
String fmtDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
String newId() => DateTime.now().microsecondsSinceEpoch.toString();

/// يحوّل الأرقام العربية (٠-٩) إلى إنجليزية عشان التحقق من الرقم يشتغل.
String normalizeDigits(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  var out = input.trim().replaceAll('٫', '.').replaceAll('،', '.');
  for (var i = 0; i < arabic.length; i++) {
    out = out.replaceAll(arabic[i], '$i');
  }
  return out;
}

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

// ───────────────────────── النماذج ─────────────────────────

class Animal {
  String id;
  String name;
  String type;
  String gender;
  String color;
  String age;
  String weight;
  String price;
  String pen;
  String purpose;
  String fatherId; // فاضي = غير محدد
  String motherId;
  Set<String> tags;

  Animal({
    required this.id,
    this.name = '',
    this.type = 'ضأن',
    this.gender = 'أنثى',
    this.color = 'أبيض',
    this.age = '',
    this.weight = '',
    this.price = '',
    this.pen = '',
    this.purpose = 'تربية',
    this.fatherId = '',
    this.motherId = '',
    Set<String>? tags,
  }) : tags = tags ?? <String>{};

  String get title => name.isEmpty ? '$type - $gender' : name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'gender': gender,
        'color': color,
        'age': age,
        'weight': weight,
        'price': price,
        'pen': pen,
        'purpose': purpose,
        'fatherId': fatherId,
        'motherId': motherId,
        'tags': tags.toList(),
      };

  factory Animal.fromJson(Map<String, dynamic> j) => Animal(
        id: (j['id'] ?? newId()).toString(),
        name: (j['name'] ?? '').toString(),
        type: (j['type'] ?? 'ضأن').toString(),
        gender: (j['gender'] ?? 'أنثى').toString(),
        color: (j['color'] ?? 'أبيض').toString(),
        age: (j['age'] ?? '').toString(),
        weight: (j['weight'] ?? '').toString(),
        price: (j['price'] ?? '').toString(),
        pen: (j['pen'] ?? '').toString(),
        purpose: (j['purpose'] ?? 'تربية').toString(),
        fatherId: (j['fatherId'] ?? '').toString(),
        motherId: (j['motherId'] ?? '').toString(),
        tags: ((j['tags'] as List?) ?? const [])
            .map((e) => e.toString())
            .toSet(),
      );
}

class EventRec {
  String id;
  String kind; // اسم القسم
  String animalId;
  String date;
  String note;

  EventRec({
    required this.id,
    required this.kind,
    required this.animalId,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'animalId': animalId,
        'date': date,
        'note': note,
      };

  factory EventRec.fromJson(Map<String, dynamic> j) => EventRec(
        id: (j['id'] ?? newId()).toString(),
        kind: (j['kind'] ?? '').toString(),
        animalId: (j['animalId'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
      );
}

class Birth {
  String id;
  String gender; // ذكر / أنثى / فاضي = غير محدد
  String name;
  String fatherId; // فاضي = غير محدد
  String motherId;
  String date;
  String note;

  Birth({
    required this.id,
    this.gender = '',
    this.name = '',
    this.fatherId = '',
    this.motherId = '',
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'gender': gender,
        'name': name,
        'fatherId': fatherId,
        'motherId': motherId,
        'date': date,
        'note': note,
      };

  factory Birth.fromJson(Map<String, dynamic> j) => Birth(
        id: (j['id'] ?? newId()).toString(),
        gender: (j['gender'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        fatherId: (j['fatherId'] ?? '').toString(),
        motherId: (j['motherId'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
      );
}

// ───────────────────────── التخزين الدائم ─────────────────────────

class Store {
  static final List<Animal> animals = [];
  static final List<EventRec> events = [];
  static final List<Birth> births = [];
  static String notes = '';
  static SharedPreferences? _prefs;

  // اسم قسم "البهم" القديم (فيه تطويلة)
  static const _oldBahm = 'البه\u0640م';

  static Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final a = _prefs!.getString('animals');
      if (a != null) {
        animals.addAll((jsonDecode(a) as List)
            .map((e) => Animal.fromJson(e as Map<String, dynamic>)));
      }
      final e = _prefs!.getString('events');
      if (e != null) {
        events.addAll((jsonDecode(e) as List)
            .map((x) => EventRec.fromJson(x as Map<String, dynamic>)));
      }
      final b = _prefs!.getString('births');
      if (b != null) {
        births.addAll((jsonDecode(b) as List)
            .map((x) => Birth.fromJson(x as Map<String, dynamic>)));
      }
      notes = _prefs!.getString('notes') ?? '';

      // ترحيل بيانات النسخة القديمة للأقسام الجديدة
      const tagMap = {'الدافع': 'اللقحات', 'غير منتجة': 'الضرايب'};
      for (final an in animals) {
        an.tags = an.tags
            .map((t) => tagMap[t] ?? t)
            .where((t) => t == 'اللقحات' || t == 'الضرايب')
            .toSet();
      }
      final oldBahm = events.where((x) => x.kind == _oldBahm).toList();
      for (final x in oldBahm) {
        births.add(Birth(
          id: x.id,
          motherId: x.animalId,
          date: x.date,
          note: x.note,
        ));
      }
      events.removeWhere((x) => x.kind == _oldBahm);
      await save();
    } catch (_) {
      // لو صار خطأ في القراءة نبدأ ببيانات فاضية بدل ما يتعطل التطبيق
    }
  }

  static Future<void> save() async {
    try {
      final p = _prefs ?? await SharedPreferences.getInstance();
      _prefs = p;
      await p.setString(
          'animals', jsonEncode(animals.map((x) => x.toJson()).toList()));
      await p.setString(
          'events', jsonEncode(events.map((x) => x.toJson()).toList()));
      await p.setString(
          'births', jsonEncode(births.map((x) => x.toJson()).toList()));
      await p.setString('notes', notes);
    } catch (_) {}
  }

  static Future<void> clear() async {
    animals.clear();
    events.clear();
    births.clear();
    notes = '';
    await save();
  }

  static String animalTitle(String id) =>
      animals.where((a) => a.id == id).map((a) => a.title).firstOrNull ??
      'رأس محذوف';

  static String parentTitle(String id) =>
      id.isEmpty ? 'غير محدد' : animalTitle(id);
}

// ───────────────────────── الأقسام ─────────────────────────

enum Kind { event, appointment, production, tag, males, females }

class Section {
  final String title;
  final IconData icon;
  final Kind kind;
  const Section(this.title, this.icon, this.kind);
}

const sections = [
  Section('السجل المرضي', Icons.medical_services_outlined, Kind.event),
  Section('التحصين', Icons.vaccines_outlined, Kind.event),
  Section('الإنتاج', Icons.pets_outlined, Kind.production),
  Section('مواعيد الولادة المتوقعة', Icons.event_available_outlined,
      Kind.appointment),
  Section('الذكور', Icons.male, Kind.males),
  Section('الإناث', Icons.female, Kind.females),
  Section('الصحة الوقائية', Icons.health_and_safety_outlined, Kind.event),
  Section('مواعيد الضراب', Icons.calendar_month_outlined, Kind.appointment),
  Section('اللقحات', Icons.favorite_border, Kind.tag),
  Section('الضرايب', Icons.groups_outlined, Kind.tag),
  Section('الفحوصات', Icons.biotech_outlined, Kind.event),
];

List<String> get tagTitles =>
    sections.where((s) => s.kind == Kind.tag).map((s) => s.title).toList();

List<Animal> animalsFor(Section s) {
  switch (s.kind) {
    case Kind.males:
      return Store.animals.where((a) => a.gender == 'ذكر').toList();
    case Kind.females:
      return Store.animals.where((a) => a.gender == 'أنثى').toList();
    case Kind.tag:
      return Store.animals.where((a) => a.tags.contains(s.title)).toList();
    case Kind.event:
    case Kind.appointment:
    case Kind.production:
      return [];
  }
}

int countFor(Section s) {
  switch (s.kind) {
    case Kind.event:
    case Kind.appointment:
      return Store.events.where((e) => e.kind == s.title).length;
    case Kind.production:
      return Store.births.length;
    default:
      return animalsFor(s).length;
  }
}

String details(Animal a) => [
      '${a.type} • ${a.gender} • ${a.color}',
      if (a.age.isNotEmpty) a.age,
      if (a.weight.isNotEmpty) '${a.weight} كجم',
      if (a.price.isNotEmpty) '${a.price} ريال',
      if (a.pen.isNotEmpty) 'حظيرة ${a.pen}',
      a.purpose,
    ].join('  |  ');

Widget parentDropdown({
  required String label,
  required List<Animal> options,
  required String emptyHint,
  required String? value,
  required ValueChanged<String?> onChanged,
}) {
  return DropdownButtonFormField<String?>(
    value: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      helperText: options.isEmpty ? emptyHint : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    ),
    items: [
      const DropdownMenuItem<String?>(value: null, child: Text('غير محدد')),
      ...options.map(
          (a) => DropdownMenuItem<String?>(value: a.id, child: Text(a.title))),
    ],
    onChanged: onChanged,
  );
}

Widget animalCard(Animal a, {VoidCallback? onTap, Widget? trailing}) {
  return Container(
    decoration: BoxDecoration(
      color: kTile,
      borderRadius: BorderRadius.circular(18),
    ),
    child: ListTile(
      onTap: onTap,
      title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(details(a)),
      trailing: trailing,
    ),
  );
}

// ───────────────────────── الصفحة الرئيسية ─────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;

  Future<void> open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (mounted) setState(() {});
  }

  void openSection(Section s) {
    switch (s.kind) {
      case Kind.event:
      case Kind.appointment:
        open(EventsPage(section: s));
        break;
      case Kind.production:
        open(const ProductionPage());
        break;
      default:
        open(SectionAnimalsPage(section: s));
    }
  }

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
            Text('العزبه',
                style: TextStyle(fontSize: 17, color: Colors.black87)),
          ],
        ),
        actions: [
          InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => open(const NotesPage()),
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: kBrown,
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
          ),
        ],
      ),
      body: _body(),
      floatingActionButton: (tab == 0 || tab == 2)
          ? FloatingActionButton(
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              onPressed: () async {
                final before = Store.animals.length;
                await open(const AddAnimalPage());
                if (mounted && Store.animals.length > before) {
                  setState(() => tab = 2);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
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

  Widget _body() {
    switch (tab) {
      case 0:
        return _grid();
      case 1:
        return const Center(
          child: Text('سوق الراعي قيد التجهيز',
              style: TextStyle(fontSize: 16)),
        );
      case 2:
        return _allAnimals();
      default:
        return SettingsView(onChanged: () => setState(() {}));
    }
  }

  Widget _grid() {
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
          final count = countFor(item);
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => openSection(item),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kTile,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: 40, color: kBrown),
                        const SizedBox(height: 10),
                        Text(item.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kBrown,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('$count',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _allAnimals() {
    if (Store.animals.isEmpty) {
      return const Center(
        child: Text('ما أضفت أي رأس للحين\nاضغط + عشان تضيف',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      itemCount: Store.animals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = Store.animals[i];
        return animalCard(a, onTap: () => open(AnimalDetailPage(animal: a)));
      },
    );
  }
}

// ───────────────────────── صفحة قسم فيه رؤوس ─────────────────────────

class SectionAnimalsPage extends StatefulWidget {
  final Section section;
  const SectionAnimalsPage({super.key, required this.section});

  @override
  State<SectionAnimalsPage> createState() => _SectionAnimalsPageState();
}

class _SectionAnimalsPageState extends State<SectionAnimalsPage> {
  Section get s => widget.section;

  Future<void> addToSection() async {
    final candidates =
        Store.animals.where((a) => !a.tags.contains(s.title)).toList();
    if (Store.animals.isEmpty) {
      snack(context, 'أضف رأس أول من الصفحة الرئيسية');
      return;
    }
    if (candidates.isEmpty) {
      snack(context, 'كل الرؤوس مضافة لهذا القسم');
      return;
    }
    final picked = await showDialog<Animal>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('اختر رأس لقسم ${s.title}'),
        children: candidates
            .map((a) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, a),
                  child: Text(a.title, style: const TextStyle(fontSize: 16)),
                ))
            .toList(),
      ),
    );
    if (picked != null) {
      setState(() => picked.tags.add(s.title));
      await Store.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = animalsFor(s);
    final isTag = s.kind == Kind.tag;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: list.isEmpty
          ? Center(
              child: Text(
                isTag
                    ? 'ما فيه رؤوس بهذا القسم\nاضغط + عشان تضيف'
                    : 'ما فيه رؤوس بهذا القسم للحين',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = list[i];
                return animalCard(
                  a,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AnimalDetailPage(animal: a)),
                    );
                    if (mounted) setState(() {});
                  },
                  trailing: isTag
                      ? IconButton(
                          tooltip: 'إزالة من القسم',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () async {
                            setState(() => a.tags.remove(s.title));
                            await Store.save();
                          },
                        )
                      : null,
                );
              },
            ),
      floatingActionButton: isTag
          ? FloatingActionButton(
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              onPressed: addToSection,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ───────────────────────── صفحة قسم سجلات ─────────────────────────

class EventsPage extends StatefulWidget {
  final Section section;
  const EventsPage({super.key, required this.section});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  Section get s => widget.section;

  List<EventRec> get items {
    final l = Store.events.where((e) => e.kind == s.title).toList();
    if (s.kind == Kind.appointment) {
      // الأقرب أول، وبعدها المواعيد اللي فاتت
      final today = fmtDate(DateTime.now());
      final up = l.where((e) => e.date.compareTo(today) >= 0).toList()
        ..sort((x, y) => x.date.compareTo(y.date));
      final past = l.where((e) => e.date.compareTo(today) < 0).toList()
        ..sort((x, y) => y.date.compareTo(x.date));
      return [...up, ...past];
    }
    l.sort((x, y) => y.date.compareTo(x.date));
    return l;
  }

  String when(EventRec e) {
    if (s.kind != Kind.appointment) return e.date;
    final d = DateTime.tryParse(e.date);
    if (d == null) return e.date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final n = (d.difference(today).inHours / 24).round();
    final rel = n == 0
        ? 'اليوم'
        : n > 0
            ? 'بعد $n يوم'
            : 'قبل ${-n} يوم';
    return '${e.date}  ($rel)';
  }

  Future<void> add() async {
    if (Store.animals.isEmpty) {
      snack(context, 'أضف رأس أول من الصفحة الرئيسية');
      return;
    }
    final rec = await showDialog<EventRec>(
      context: context,
      builder: (_) => AddEventDialog(kind: s.title),
    );
    if (rec != null) {
      setState(() => Store.events.add(rec));
      await Store.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = items;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: list.isEmpty
          ? const Center(
              child: Text('ما فيه سجلات للحين\nاضغط + عشان تضيف',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16)),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = list[i];
                return Container(
                  decoration: BoxDecoration(
                    color: kTile,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    title: Text(Store.animalTitle(e.animalId),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(e.note.isEmpty
                        ? when(e)
                        : '${when(e)}\n${e.note}'),
                    isThreeLine: e.note.isNotEmpty,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        setState(() => Store.events.remove(e));
                        await Store.save();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        onPressed: add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddEventDialog extends StatefulWidget {
  final String kind;
  const AddEventDialog({super.key, required this.kind});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  String? animalId = Store.animals.first.id;
  DateTime date = DateTime.now();
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة - ${widget.kind}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: animalId,
              isExpanded: true,
              items: Store.animals
                  .map((a) =>
                      DropdownMenuItem(value: a.id, child: Text(a.title)))
                  .toList(),
              onChanged: (v) => setState(() => animalId = v),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(fmtDate(date)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => date = d);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (animalId == null) return;
            Navigator.pop(
              context,
              EventRec(
                id: newId(),
                kind: widget.kind,
                animalId: animalId!,
                date: fmtDate(date),
                note: note.text.trim(),
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

// ───────────────────────── الإنتاج (المواليد) ─────────────────────────

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage> {
  List<Birth> get items {
    final l = [...Store.births];
    l.sort((x, y) => y.date.compareTo(x.date));
    return l;
  }

  Future<void> add() async {
    final b = await showDialog<Birth>(
      context: context,
      builder: (_) => const AddBirthDialog(),
    );
    if (b != null) {
      setState(() => Store.births.add(b));
      await Store.save();
    }
  }

  Widget countChip(String label, int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: kTile,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('$label: $n', style: const TextStyle(fontSize: 15)),
      );

  @override
  Widget build(BuildContext context) {
    final list = items;
    final males = Store.births.where((b) => b.gender == 'ذكر').length;
    final females = Store.births.where((b) => b.gender == 'أنثى').length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإنتاج',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                countChip('الكل', Store.births.length),
                const SizedBox(width: 10),
                countChip('ذكور', males),
                const SizedBox(width: 10),
                countChip('إناث', females),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('ما فيه مواليد مسجلة\nاضغط + عشان تضيف',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final b = list[i];
                      final label = b.gender.isEmpty ? 'غير محدد' : b.gender;
                      final title =
                          b.name.isEmpty ? label : '${b.name} - $label';
                      return Container(
                        decoration: BoxDecoration(
                          color: kTile,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          leading: Icon(
                            b.gender == 'ذكر'
                                ? Icons.male
                                : b.gender == 'أنثى'
                                    ? Icons.female
                                    : Icons.help_outline,
                            color: kBrown,
                          ),
                          title: Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800)),
                          subtitle: Text(
                              'الأب: ${Store.parentTitle(b.fatherId)}  |  الأم: ${Store.parentTitle(b.motherId)}\n${b.date}${b.note.isEmpty ? '' : '\n${b.note}'}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              setState(() => Store.births.remove(b));
                              await Store.save();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        onPressed: add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddBirthDialog extends StatefulWidget {
  const AddBirthDialog({super.key});

  @override
  State<AddBirthDialog> createState() => _AddBirthDialogState();
}

class _AddBirthDialogState extends State<AddBirthDialog> {
  String gender = 'أنثى';
  String? fatherId; // null = غير محدد
  String? motherId;
  DateTime date = DateTime.now();
  final name = TextEditingController();
  final note = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Widget parentField({
    required String label,
    required List<Animal> options,
    required String emptyHint,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: options.isEmpty ? emptyHint : null,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('غير محدد')),
        ...options.map((a) =>
            DropdownMenuItem<String?>(value: a.id, child: Text(a.title))),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final males = Store.animals.where((a) => a.gender == 'ذكر').toList();
    final females = Store.animals.where((a) => a.gender == 'أنثى').toList();
    return AlertDialog(
      title: const Text('إضافة مولود'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'أنثى', label: Text('أنثى')),
                ButtonSegment(value: 'ذكر', label: Text('ذكر')),
              ],
              selected: {gender},
              onSelectionChanged: (v) => setState(() => gender = v.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                hintText: 'اسم أو رقم المولود (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            parentField(
              label: 'الأب',
              options: males,
              emptyHint: 'ما فيه ذكور مسجلين في الحلال',
              value: fatherId,
              onChanged: (v) => setState(() => fatherId = v),
            ),
            const SizedBox(height: 12),
            parentField(
              label: 'الأم',
              options: females,
              emptyHint: 'ما فيه إناث مسجلة في الحلال',
              value: motherId,
              onChanged: (v) => setState(() => motherId = v),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(fmtDate(date)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => date = d);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              Birth(
                id: newId(),
                gender: gender,
                name: name.text.trim(),
                fatherId: fatherId ?? '',
                motherId: motherId ?? '',
                date: fmtDate(date),
                note: note.text.trim(),
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

// ───────────────────────── تفاصيل الرأس ─────────────────────────

class AnimalDetailPage extends StatefulWidget {
  final Animal animal;
  const AnimalDetailPage({super.key, required this.animal});

  @override
  State<AnimalDetailPage> createState() => _AnimalDetailPageState();
}

class _AnimalDetailPageState extends State<AnimalDetailPage> {
  Animal get a => widget.animal;

  Future<void> confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الرأس؟'),
        content: const Text('بيتحذف الرأس مع كل سجلاته.'),
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
    if (ok == true) {
      Store.animals.remove(a);
      Store.events.removeWhere((e) => e.animalId == a.id);
      await Store.save();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recs = Store.events.where((e) => e.animalId == a.id).toList()
      ..sort((x, y) => y.date.compareTo(x.date));
    return Scaffold(
      appBar: AppBar(
        title: Text(a.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline),
            onPressed: confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kTile,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(details(a), style: const TextStyle(fontSize: 16)),
          ),
          if (a.fatherId.isNotEmpty || a.motherId.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'الأب: ${Store.parentTitle(a.fatherId)}  |  الأم: ${Store.parentTitle(a.motherId)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
          const SizedBox(height: 22),
          const Text('الأقسام',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tagTitles
                .map((t) => FilterChip(
                      label: Text(t),
                      selected: a.tags.contains(t),
                      onSelected: (v) async {
                        setState(() {
                          if (v) {
                            a.tags.add(t);
                          } else {
                            a.tags.remove(t);
                          }
                        });
                        await Store.save();
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 22),
          const Text('السجلات',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          if (recs.isEmpty)
            const Text('ما فيه سجلات لهذا الرأس')
          else
            ...recs.map((e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.kind),
                  subtitle:
                      Text(e.note.isEmpty ? e.date : '${e.date}\n${e.note}'),
                )),
        ],
      ),
    );
  }
}

// ───────────────────────── ملاحظات المربي ─────────────────────────

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final controller = TextEditingController(text: Store.notes);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملاحظات المربي',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: 'اكتب ملاحظاتك هنا ... تنحفظ تلقائياً',
            filled: true,
            fillColor: kTile,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (v) {
            Store.notes = v;
            Store.save();
          },
        ),
      ),
    );
  }
}

// ───────────────────────── الإعدادات ─────────────────────────

class SettingsView extends StatelessWidget {
  final VoidCallback onChanged;
  const SettingsView({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('الراعي'),
          subtitle: Text('النسخة 0.2'),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
          title: const Text('حذف كل البيانات',
              style: TextStyle(color: Colors.red)),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('حذف كل البيانات؟'),
                content: const Text(
                    'بيتحذف كل الحلال والسجلات والملاحظات من هذا الجهاز.'),
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
            if (ok == true) {
              await Store.clear();
              onChanged();
            }
          },
        ),
      ],
    );
  }
}

// ───────────────────────── إضافة رأس ─────────────────────────

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
  String? fatherId;
  String? motherId;

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
                          color: kBrown,
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
                    items: ['ضأن', 'ماعز', 'إبل']
                        .map((v) =>
                            DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: gender,
                    decoration: field('الجنس'),
                    items: ['أنثى', 'ذكر']
                        .map((v) =>
                            DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
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
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: field('وزن الرأس - كجم'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: price,
                    validator: numberValidator,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
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
            parentDropdown(
              label: 'الأب (اختياري)',
              options: Store.animals.where((a) => a.gender == 'ذكر').toList(),
              emptyHint: 'ما فيه ذكور مسجلين في الحلال',
              value: fatherId,
              onChanged: (v) => setState(() => fatherId = v),
            ),
            const SizedBox(height: 18),
            parentDropdown(
              label: 'الأم (اختياري)',
              options: Store.animals.where((a) => a.gender == 'أنثى').toList(),
              emptyHint: 'ما فيه إناث مسجلة في الحلال',
              value: motherId,
              onChanged: (v) => setState(() => motherId = v),
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
              onSelectionChanged: (v) => setState(() => purpose = v.first),
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Store.animals.add(Animal(
                  id: newId(),
                  name: name.text.trim(),
                  type: type,
                  gender: gender,
                  color: color,
                  age: age ?? '',
                  weight: normalizeDigits(weight.text),
                  price: normalizeDigits(price.text),
                  pen: normalizeDigits(pen.text),
                  purpose: purpose,
                  fatherId: fatherId ?? '',
                  motherId: motherId ?? '',
                ));
                await Store.save();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('إضافة', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
