import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kBrown = Color(0xFFC97A2B);
const kTile = Color(0xFFFBF4EF);
const kKhalafat = 'الخلفات';

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

/// العمر محسوب من تاريخ الميلاد.
String ageText(String dateStr) {
  final d = DateTime.tryParse(dateStr);
  if (d == null) return 'غير معروف';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = (today.difference(d).inHours / 24).round();
  if (days < 0) return 'لم يولد بعد';
  if (days == 0) return 'مولود اليوم';
  if (days < 30) return '$days يوم';
  if (days < 365) {
    final m = days ~/ 30;
    final r = days % 30;
    return r == 0 ? '$m شهر' : '$m شهر و$r يوم';
  }
  final y = days ~/ 365;
  final m = (days % 365) ~/ 30;
  return m == 0 ? '$y سنة' : '$y سنة و$m شهر';
}

Future<String?> askText(BuildContext context, String title, String initial) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
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
  String fatherText; // أب مكتوب يدوي
  String motherId;
  String motherText;
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
    this.fatherText = '',
    this.motherId = '',
    this.motherText = '',
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
        'fatherText': fatherText,
        'motherId': motherId,
        'motherText': motherText,
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
        fatherText: (j['fatherText'] ?? '').toString(),
        motherId: (j['motherId'] ?? '').toString(),
        motherText: (j['motherText'] ?? '').toString(),
        tags: ((j['tags'] as List?) ?? const [])
            .map((e) => e.toString())
            .toSet(),
      );
}

class EventRec {
  String id;
  String kind; // مفتاح القسم الثابت
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
  String fatherId;
  String fatherText;
  String motherId;
  String motherText;
  String date;
  String note;

  Birth({
    required this.id,
    this.gender = '',
    this.name = '',
    this.fatherId = '',
    this.fatherText = '',
    this.motherId = '',
    this.motherText = '',
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'gender': gender,
        'name': name,
        'fatherId': fatherId,
        'fatherText': fatherText,
        'motherId': motherId,
        'motherText': motherText,
        'date': date,
        'note': note,
      };

  factory Birth.fromJson(Map<String, dynamic> j) => Birth(
        id: (j['id'] ?? newId()).toString(),
        gender: (j['gender'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        fatherId: (j['fatherId'] ?? '').toString(),
        fatherText: (j['fatherText'] ?? '').toString(),
        motherId: (j['motherId'] ?? '').toString(),
        motherText: (j['motherText'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
      );
}

// ───────────────────────── التخزين الدائم ─────────────────────────

class Store {
  static final List<Animal> animals = [];
  static final List<EventRec> events = [];
  static final List<Birth> births = [];
  static final Map<String, String> names = {}; // أسماء الأقسام المخصصة
  static final Set<String> hidden = {}; // الأقسام المخفية
  static String notes = '';
  static String farmName = 'العزبه';
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
      farmName = _prefs!.getString('farmName') ?? 'العزبه';
      final n = _prefs!.getString('names');
      if (n != null) {
        (jsonDecode(n) as Map).forEach((k, v) {
          names[k.toString()] = v.toString();
        });
      }
      final h = _prefs!.getString('hidden');
      if (h != null) {
        hidden.addAll((jsonDecode(h) as List).map((x) => x.toString()));
      }

      // ترحيل بيانات النسخ القديمة للأقسام الجديدة
      const tagMap = {'الدافع': 'اللقحات', 'غير منتجة': 'الضرايب'};
      for (final an in animals) {
        an.tags = an.tags
            .map((t) => tagMap[t] ?? t)
            .where((t) => tagTitles.contains(t))
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
      await p.setString('farmName', farmName);
      await p.setString('names', jsonEncode(names));
      await p.setString('hidden', jsonEncode(hidden.toList()));
    } catch (_) {}
  }

  /// يحذف الحلال والسجلات والملاحظات (الإعدادات تبقى).
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

  /// الأب/الأم: من الحلال المسجل، أو مكتوب يدوي.
  static String parentLabel(String id, String text) {
    final reg =
        animals.where((a) => a.id == id).map((a) => a.title).firstOrNull;
    if (id.isNotEmpty && reg != null) return reg;
    if (text.isNotEmpty) return text;
    return id.isNotEmpty ? 'رأس محذوف' : 'غير محدد';
  }
}

// ───────────────────────── الأقسام ─────────────────────────

enum Kind { event, appointment, production, tag, males, females }

class Section {
  /// المفتاح الثابت للقسم (ما يتغير حتى لو غيّرت الاسم)
  final String title;
  final IconData icon;
  final Kind kind;
  const Section(this.title, this.icon, this.kind);

  /// الاسم الظاهر (ممكن المستخدم يغيّره من الإعدادات)
  String get name => Store.names[title] ?? title;
}

const sections = [
  Section('السجل المرضي', Icons.medical_services_outlined, Kind.event),
  Section('التحصين', Icons.vaccines_outlined, Kind.event),
  Section('الإنتاج', Icons.pets_outlined, Kind.production),
  Section('مواعيد الولادة المتوقعة', Icons.event_available_outlined,
      Kind.appointment),
  Section('الذكور', Icons.male, Kind.males),
  Section('الإناث', Icons.female, Kind.females),
  Section(kKhalafat, Icons.family_restroom_outlined, Kind.tag),
  Section('الصحة الوقائية', Icons.health_and_safety_outlined, Kind.event),
  Section('مواعيد الضراب', Icons.calendar_month_outlined, Kind.appointment),
  Section('اللقحات', Icons.favorite_border, Kind.tag),
  Section('الضرايب', Icons.groups_outlined, Kind.tag),
  Section('الفحوصات', Icons.biotech_outlined, Kind.event),
];

List<String> get tagTitles =>
    sections.where((s) => s.kind == Kind.tag).map((s) => s.title).toList();

List<Section> get visibleSections =>
    sections.where((s) => !Store.hidden.contains(s.title)).toList();

String sectionName(String id) =>
    sections.where((s) => s.title == id).map((s) => s.name).firstOrNull ?? id;

List<Animal> animalsFor(Section s) {
  switch (s.kind) {
    case Kind.males:
      return Store.animals.where((a) => a.gender == 'ذكر').toList();
    case Kind.females:
      // الأمهات اللي ولدت تنتقل للخلفات، وترجع هنا لما تنشال منها
      return Store.animals
          .where((a) => a.gender == 'أنثى' && !a.tags.contains(kKhalafat))
          .toList();
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

Widget animalCard(Animal a,
    {VoidCallback? onTap, Widget? trailing, String? extra}) {
  return Container(
    decoration: BoxDecoration(
      color: kTile,
      borderRadius: BorderRadius.circular(18),
    ),
    child: ListTile(
      onTap: onTap,
      title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(extra == null ? details(a) : '${details(a)}\n$extra'),
      trailing: trailing,
    ),
  );
}

// ───────────────────────── خانة الأب/الأم ─────────────────────────

/// اختيار من الحلال المسجل، أو "كتابة يدوية" لو الأب/الأم مو مسجلين.
class ParentField extends StatefulWidget {
  final String label;
  final List<Animal> options;
  final String emptyHint;
  final String initialId;
  final String initialText;
  final void Function(String id, String text) onChanged;

  const ParentField({
    super.key,
    required this.label,
    required this.options,
    required this.emptyHint,
    required this.initialId,
    required this.initialText,
    required this.onChanged,
  });

  @override
  State<ParentField> createState() => _ParentFieldState();
}

class _ParentFieldState extends State<ParentField> {
  static const typed = '__typed__';
  String? selected; // null = غير محدد
  late final TextEditingController text;

  @override
  void initState() {
    super.initState();
    text = TextEditingController(text: widget.initialText);
    if (widget.initialId.isNotEmpty &&
        widget.options.any((a) => a.id == widget.initialId)) {
      selected = widget.initialId;
    } else if (widget.initialText.isNotEmpty) {
      selected = typed;
    } else {
      selected = null;
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  void notify() {
    final id = (selected != null && selected != typed) ? selected! : '';
    final t = selected == typed ? text.text.trim() : '';
    widget.onChanged(id, t);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String?>(
          value: selected,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.options.isEmpty ? widget.emptyHint : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('غير محدد')),
            ...widget.options.map((a) =>
                DropdownMenuItem<String?>(value: a.id, child: Text(a.title))),
            const DropdownMenuItem<String?>(
                value: typed, child: Text('كتابة يدوية ✎')),
          ],
          onChanged: (v) {
            setState(() => selected = v);
            notify();
          },
        ),
        if (selected == typed) ...[
          const SizedBox(height: 10),
          TextField(
            controller: text,
            decoration: InputDecoration(
              hintText: 'اكتب اسم أو رقم ${widget.label}',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onChanged: (_) => notify(),
          ),
        ],
      ],
    );
  }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('أهلاً بك ...',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            Text(Store.farmName,
                style: const TextStyle(fontSize: 17, color: Colors.black87)),
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
    final list = visibleSections;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: .93,
        ),
        itemBuilder: (context, i) {
          final item = list[i];
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, size: 40, color: kBrown),
                          const SizedBox(height: 10),
                          Text(item.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15)),
                        ],
                      ),
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
  bool get isKhalafat => s.title == kKhalafat;

  Future<void> addDelivery() async {
    if (!Store.animals.any((a) => a.gender == 'أنثى')) {
      snack(context, 'سجّل أنثى أول من الصفحة الرئيسية');
      return;
    }
    final b = await showDialog<Birth>(
      context: context,
      builder: (_) => const AddBirthDialog(delivered: true),
    );
    if (b != null) {
      Store.births.add(b);
      final mom = Store.animals.where((a) => a.id == b.motherId).firstOrNull;
      if (mom != null) mom.tags.add(kKhalafat);
      setState(() {});
      await Store.save();
      if (mounted) snack(context, 'انضاف المولود للإنتاج والأم للخلفات');
    }
  }

  Future<void> addToSection() async {
    if (isKhalafat) {
      await addDelivery();
      return;
    }
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
        title: Text('اختر رأس لقسم ${s.name}'),
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
        title: Text(s.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: list.isEmpty
          ? Center(
              child: Text(
                isKhalafat
                    ? 'ما فيه أمهات ولدت\nاضغط "ولدت" عشان تسجل ولادة'
                    : isTag
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
                final n = Store.births.where((b) => b.motherId == a.id).length;
                return animalCard(
                  a,
                  extra: isKhalafat ? 'عدد المواليد: $n' : null,
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
                          tooltip: isKhalafat
                              ? 'إزالة من الخلفات (ترجع للإناث)'
                              : 'إزالة من القسم',
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
      floatingActionButton: isKhalafat
          ? FloatingActionButton.extended(
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              onPressed: addToSection,
              icon: const Icon(Icons.add),
              label: const Text('ولدت'),
            )
          : isTag
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
      builder: (_) => AddEventDialog(kind: s.title, label: s.name),
    );
    if (rec != null) {
      setState(() => Store.events.add(rec));
      await Store.save();
    }
  }

  Future<void> edit(EventRec e) async {
    final rec = await showDialog<EventRec>(
      context: context,
      builder: (_) => AddEventDialog(kind: s.title, label: s.name, initial: e),
    );
    if (rec != null) {
      setState(() {
        final i = Store.events.indexWhere((x) => x.id == e.id);
        if (i >= 0) Store.events[i] = rec;
      });
      await Store.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = items;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.name,
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'تعديل',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => edit(e),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            setState(() => Store.events.remove(e));
                            await Store.save();
                          },
                        ),
                      ],
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
  final String label;
  final EventRec? initial;
  const AddEventDialog({
    super.key,
    required this.kind,
    required this.label,
    this.initial,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  late String? animalId;
  late DateTime date;
  late final TextEditingController note;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    animalId = (init != null && Store.animals.any((a) => a.id == init.animalId))
        ? init.animalId
        : Store.animals.first.id;
    date = (init != null ? DateTime.tryParse(init.date) : null) ??
        DateTime.now();
    note = TextEditingController(text: init?.note ?? '');
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null
          ? 'إضافة - ${widget.label}'
          : 'تعديل - ${widget.label}'),
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
                id: widget.initial?.id ?? newId(),
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

  Future<void> edit(Birth old) async {
    final b = await showDialog<Birth>(
      context: context,
      builder: (_) => AddBirthDialog(initial: old),
    );
    if (b != null) {
      setState(() {
        final i = Store.births.indexWhere((x) => x.id == old.id);
        if (i >= 0) Store.births[i] = b;
      });
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
        title: Text(sectionName('الإنتاج'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
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
                      final lines = [
                        'الأب: ${Store.parentLabel(b.fatherId, b.fatherText)}  |  الأم: ${Store.parentLabel(b.motherId, b.motherText)}',
                        'العمر: ${ageText(b.date)}  (${b.date})',
                        if (b.note.isNotEmpty) b.note,
                      ];
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
                          subtitle: Text(lines.join('\n')),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'تعديل',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => edit(b),
                              ),
                              IconButton(
                                tooltip: 'حذف',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  setState(() => Store.births.remove(b));
                                  await Store.save();
                                },
                              ),
                            ],
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
  final Birth? initial;

  /// من قسم الخلفات: الأم لازم تكون من الإناث المسجلة، والزر "ولدت"
  final bool delivered;

  const AddBirthDialog({super.key, this.initial, this.delivered = false});

  @override
  State<AddBirthDialog> createState() => _AddBirthDialogState();
}

class _AddBirthDialogState extends State<AddBirthDialog> {
  late String gender;
  late String fatherId;
  late String fatherText;
  late String motherId;
  late String motherText;
  late DateTime date;
  late final TextEditingController name;
  late final TextEditingController note;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    gender = (i != null && (i.gender == 'ذكر' || i.gender == 'أنثى'))
        ? i.gender
        : 'أنثى';
    fatherId = i?.fatherId ?? '';
    fatherText = i?.fatherText ?? '';
    motherId = i?.motherId ?? '';
    motherText = i?.motherText ?? '';
    date = (i != null ? DateTime.tryParse(i.date) : null) ?? DateTime.now();
    name = TextEditingController(text: i?.name ?? '');
    note = TextEditingController(text: i?.note ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final males = Store.animals.where((a) => a.gender == 'ذكر').toList();
    final females = Store.animals.where((a) => a.gender == 'أنثى').toList();
    final canSave = !(widget.delivered && motherId.isEmpty);
    return AlertDialog(
      title: Text(widget.delivered
          ? 'تسجيل ولادة'
          : widget.initial == null
              ? 'إضافة مولود'
              : 'تعديل مولود'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.delivered) ...[
              DropdownButtonFormField<String>(
                value: motherId.isEmpty ? null : motherId,
                isExpanded: true,
                hint: const Text('اختر الأم'),
                decoration: const InputDecoration(
                  labelText: 'الأم',
                  border: OutlineInputBorder(),
                ),
                items: females
                    .map((a) =>
                        DropdownMenuItem(value: a.id, child: Text(a.title)))
                    .toList(),
                onChanged: (v) => setState(() => motherId = v ?? ''),
              ),
              const SizedBox(height: 12),
            ],
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
            ParentField(
              label: 'الأب',
              options: males,
              emptyHint: 'ما فيه ذكور مسجلين، تقدر تكتبه يدوي',
              initialId: fatherId,
              initialText: fatherText,
              onChanged: (id, t) {
                fatherId = id;
                fatherText = t;
              },
            ),
            if (!widget.delivered) ...[
              const SizedBox(height: 12),
              ParentField(
                label: 'الأم',
                options: females,
                emptyHint: 'ما فيه إناث مسجلة، تقدر تكتبها يدوي',
                initialId: motherId,
                initialText: motherText,
                onChanged: (id, t) {
                  motherId = id;
                  motherText = t;
                },
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text('تاريخ الميلاد: ${fmtDate(date)}'),
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
            const SizedBox(height: 6),
            Text('العمر: ${ageText(fmtDate(date))}',
                style: const TextStyle(color: Colors.black54)),
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
          onPressed: canSave
              ? () {
                  Navigator.pop(
                    context,
                    Birth(
                      id: widget.initial?.id ?? newId(),
                      gender: gender,
                      name: name.text.trim(),
                      fatherId: fatherId,
                      fatherText: fatherText,
                      motherId: motherId,
                      motherText: motherText,
                      date: fmtDate(date),
                      note: note.text.trim(),
                    ),
                  );
                }
              : null,
          child: Text(widget.delivered ? 'ولدت' : 'حفظ'),
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

  Future<void> edit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddAnimalPage(initial: a)),
    );
    if (mounted) setState(() {});
  }

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
    final hasParents = a.fatherId.isNotEmpty ||
        a.fatherText.isNotEmpty ||
        a.motherId.isNotEmpty ||
        a.motherText.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(a.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'تعديل',
            icon: const Icon(Icons.edit_outlined),
            onPressed: edit,
          ),
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
          if (hasParents) ...[
            const SizedBox(height: 12),
            Text(
              'الأب: ${Store.parentLabel(a.fatherId, a.fatherText)}  |  الأم: ${Store.parentLabel(a.motherId, a.motherText)}',
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
            children: sections
                .where((x) => x.kind == Kind.tag)
                .map((t) => FilterChip(
                      label: Text(t.name),
                      selected: a.tags.contains(t.title),
                      onSelected: (v) async {
                        setState(() {
                          if (v) {
                            a.tags.add(t.title);
                          } else {
                            a.tags.remove(t.title);
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
                  title: Text(sectionName(e.kind)),
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
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: const Text('اسم العزبة'),
          subtitle: Text(Store.farmName),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () async {
            final v = await askText(context, 'اسم العزبة', Store.farmName);
            if (v != null && v.isNotEmpty) {
              Store.farmName = v;
              await Store.save();
              onChanged();
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.dashboard_customize_outlined),
          title: const Text('تخصيص الأقسام'),
          subtitle: const Text('غيّر أسماء الأقسام أو أخفِ اللي ما تحتاجه'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SectionsSettingsPage()),
            );
            onChanged();
          },
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('الراعي'),
          subtitle: Text('النسخة 0.3'),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
          title: const Text('حذف كل البيانات',
              style: TextStyle(color: Colors.red)),
          subtitle: const Text('يحذف الحلال والسجلات والملاحظات (الإعدادات تبقى)'),
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

class SectionsSettingsPage extends StatefulWidget {
  const SectionsSettingsPage({super.key});

  @override
  State<SectionsSettingsPage> createState() => _SectionsSettingsPageState();
}

class _SectionsSettingsPageState extends State<SectionsSettingsPage> {
  Future<void> rename(Section s) async {
    final v = await askText(context, 'اسم القسم', s.name);
    if (v == null) return;
    setState(() {
      if (v.isEmpty || v == s.title) {
        Store.names.remove(s.title);
      } else {
        Store.names[s.title] = v;
      }
    });
    await Store.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تخصيص الأقسام',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'اضغط على القلم لتغيير اسم القسم، والمفتاح يظهر القسم أو يخفيه من الرئيسية. بيانات القسم المخفي ما تنحذف.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ...sections.map((s) => ListTile(
                leading: Icon(s.icon, color: kBrown),
                title: Text(s.name),
                subtitle: s.name == s.title
                    ? null
                    : Text('الاسم الأصلي: ${s.title}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'تغيير الاسم',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => rename(s),
                    ),
                    Switch(
                      value: !Store.hidden.contains(s.title),
                      onChanged: (v) async {
                        setState(() {
                          if (v) {
                            Store.hidden.remove(s.title);
                          } else {
                            Store.hidden.add(s.title);
                          }
                        });
                        await Store.save();
                      },
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('إرجاع الأسماء الأصلية'),
            onPressed: () async {
              setState(() => Store.names.clear());
              await Store.save();
            },
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── إضافة / تعديل رأس ─────────────────────────

class AddAnimalPage extends StatefulWidget {
  final Animal? initial;
  const AddAnimalPage({super.key, this.initial});

  @override
  State<AddAnimalPage> createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends State<AddAnimalPage> {
  static const types = ['ضأن', 'ماعز', 'إبل'];
  static const genders = ['أنثى', 'ذكر'];
  static const colors = ['أبيض', 'أسود', 'أشقر', 'بني', 'أحمر', 'متعدد'];
  static const ages = [
    'أقل من سنة',
    'سنة',
    'سنتان',
    '3 سنوات',
    '4 سنوات فأكثر'
  ];

  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController weight;
  late final TextEditingController price;
  late final TextEditingController pen;

  String type = 'ضأن';
  String gender = 'أنثى';
  String color = 'أبيض';
  String purpose = 'تربية';
  String? age;
  String fatherId = '';
  String fatherText = '';
  String motherId = '';
  String motherText = '';

  bool get editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    name = TextEditingController(text: a?.name ?? '');
    weight = TextEditingController(text: a?.weight ?? '');
    price = TextEditingController(text: a?.price ?? '');
    pen = TextEditingController(text: a?.pen ?? '');
    if (a != null) {
      type = types.contains(a.type) ? a.type : types.first;
      gender = genders.contains(a.gender) ? a.gender : genders.first;
      color = colors.contains(a.color) ? a.color : colors.first;
      purpose = (a.purpose == 'تربية' || a.purpose == 'تسمين')
          ? a.purpose
          : 'تربية';
      age = ages.contains(a.age) ? a.age : null;
      fatherId = a.fatherId;
      fatherText = a.fatherText;
      motherId = a.motherId;
      motherText = a.motherText;
    }
  }

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

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final a = widget.initial;
    if (a != null) {
      a.name = name.text.trim();
      a.type = type;
      a.gender = gender;
      a.color = color;
      a.age = age ?? '';
      a.weight = normalizeDigits(weight.text);
      a.price = normalizeDigits(price.text);
      a.pen = normalizeDigits(pen.text);
      a.purpose = purpose;
      a.fatherId = fatherId;
      a.fatherText = fatherText;
      a.motherId = motherId;
      a.motherText = motherText;
    } else {
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
        fatherId: fatherId,
        fatherText: fatherText,
        motherId: motherId,
        motherText: motherText,
      ));
    }
    await Store.save();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final selfId = widget.initial?.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'تعديل رأس' : 'إضافة رأس',
            style: const TextStyle(fontWeight: FontWeight.w800)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('البيانات الأساسية',
                      style: TextStyle(
                          color: kBrown,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(editing
                      ? 'عدّل بيانات الرأس ...'
                      : 'أضف البيانات الأساسية للرأس ...'),
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
                    items: types
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
                    items: genders
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
              items: colors
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
              items: ages
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => age = v),
            ),
            const SizedBox(height: 18),
            ParentField(
              label: 'الأب (اختياري)',
              options: Store.animals
                  .where((a) => a.gender == 'ذكر' && a.id != selfId)
                  .toList(),
              emptyHint: 'ما فيه ذكور مسجلين، تقدر تكتبه يدوي',
              initialId: fatherId,
              initialText: fatherText,
              onChanged: (id, t) {
                fatherId = id;
                fatherText = t;
              },
            ),
            const SizedBox(height: 18),
            ParentField(
              label: 'الأم (اختياري)',
              options: Store.animals
                  .where((a) => a.gender == 'أنثى' && a.id != selfId)
                  .toList(),
              emptyHint: 'ما فيه إناث مسجلة، تقدر تكتبها يدوي',
              initialId: motherId,
              initialText: motherText,
              onChanged: (id, t) {
                motherId = id;
                motherText = t;
              },
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
              onPressed: save,
              child: Text(editing ? 'حفظ التعديل' : 'إضافة',
                  style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
