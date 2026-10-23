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

// ───────────────────────── التخزين الدائم ─────────────────────────

class Store {
  static final List<Animal> animals = [];
  static final List<EventRec> events = [];
  static String notes = '';
  static SharedPreferences? _prefs;

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
      notes = _prefs!.getString('notes') ?? '';
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
      await p.setString('notes', notes);
    } catch (_) {}
  }

  static Future<void> clear() async {
    animals.clear();
    events.clear();
    notes = '';
    await save();
  }

  static String animalTitle(String id) =>
      animals.where((a) => a.id == id).map((a) => a.title).firstOrNull ??
      'رأس محذوف';
}

// ───────────────────────── الأقسام ─────────────────────────

enum Kind { event, tag, males, females, fattening }

class Section {
  final String title;
  final IconData icon;
  final Kind kind;
  const Section(this.title, this.icon, this.kind);
}

const sections = [
  Section('السجل المرضي', Icons.medical_services_outlined, Kind.event),
  Section('التحصين', Icons.vaccines_outlined, Kind.event),
  Section('البهـم', Icons.pets_outlined, Kind.event),
  Section('قريب الولادة', Icons.child_friendly_outlined, Kind.tag),
  Section('الذكور', Icons.male, Kind.males),
  Section('الإناث', Icons.female, Kind.females),
  Section('الصحة الوقائية', Icons.health_and_safety_outlined, Kind.event),
  Section('غير دافع', Icons.money_off_outlined, Kind.tag),
  Section('الدافع', Icons.paid_outlined, Kind.tag),
  Section('المقرعات', Icons.pets_outlined, Kind.tag),
  Section('غير منتجة', Icons.groups_outlined, Kind.tag),
  Section('المقاومة', Icons.groups_2_outlined, Kind.tag),
  Section('إنتاج الحليب', Icons.local_drink_outlined, Kind.tag),
  Section('المراضعات', Icons.family_restroom_outlined, Kind.tag),
  Section('التسمين', Icons.restaurant_outlined, Kind.fattening),
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
    case Kind.fattening:
      return Store.animals.where((a) => a.purpose == 'تسمين').toList();
    case Kind.tag:
      return Store.animals.where((a) => a.tags.contains(s.title)).toList();
    case Kind.event:
      return [];
  }
}

int countFor(Section s) => s.kind == Kind.event
    ? Store.events.where((e) => e.kind == s.title).length
    : animalsFor(s).length;

String details(Animal a) => [
      '${a.type} • ${a.gender} • ${a.color}',
      if (a.age.isNotEmpty) a.age,
      if (a.weight.isNotEmpty) '${a.weight} كجم',
      if (a.price.isNotEmpty) '${a.price} ريال',
      if (a.pen.isNotEmpty) 'حظيرة ${a.pen}',
      a.purpose,
    ].join('  |  ');

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
    if (s.kind == Kind.event) {
      open(EventsPage(section: s));
    } else {
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
            Text('غنم الوالده',
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
    l.sort((x, y) => y.date.compareTo(x.date));
    return l;
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
                    subtitle: Text(
                        e.note.isEmpty ? e.date : '${e.date}\n${e.note}'),
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
