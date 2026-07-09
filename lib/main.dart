import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyDiaryApp());
}

class MyDiaryApp extends StatelessWidget {
  const MyDiaryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink.shade50),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (snapshot.hasData) return const MainNavigationPage();
          return const LoginPage();
        },
      ),
    );
  }
}

// --- ログイン画面 ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signUp() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text, password: _passwordController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("登録エラー: $e")));
    }
  }

  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text, password: _passwordController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ログインエラー: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン / 新規登録')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'メールアドレス')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'パスワード'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _signIn, child: const Text('ログイン')),
            TextButton(onPressed: _signUp, child: const Text('新規アカウント作成')),
          ],
        ),
      ),
    );
  }
}

// --- ナビゲーション管理 ---
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});
  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 1;
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [const ChartPage(), const CalendarPage(), const MyPage()];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.pink,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'グラフ'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: '日記'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
        ],
      ),
    );
  }
}

// --- カレンダー画面 ---
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance.collection('users').doc(uid).collection('diaries').snapshots().listen((snapshot) {
      final Map<DateTime, List> newEvents = {};
      for (var doc in snapshot.docs) {
        final dateData = doc.data()['date'];
        if (dateData == null) continue;
        final date = (dateData as Timestamp).toDate();
        final day = DateTime.utc(date.year, date.month, date.day);
        if (newEvents[day] == null) newEvents[day] = [];
        newEvents[day]!.add(doc.data());
      }
      if (mounted) setState(() => _events = newEvents);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景画像をスマホの一番上（時計や電池の裏）まで広げるためのおまじない
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent, // 上のバーを透明にします
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. 一番後ろに背景画像を敷く
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/images/homu.png', // ⚠️ここのファイル名が合っているか確認！
              fit: BoxFit.cover, // 画面全体に隙間なく広げます
            ),
          ),
          
          // 2. その上にカレンダーを重ねる
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80), // 背景画像の「April」の文字とカレンダーが重ならないように少し余白を作ります
                Expanded(
                  child: TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    eventLoader: (day) => _events[DateTime.utc(day.year, day.month, day.day)] ?? [],
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
                      Navigator.push(context, MaterialPageRoute(builder: (context) => DiaryInputPage(selectedDate: selectedDay)));
                    },
                    // --- カレンダーの文字色を画像に合わせて見やすく変更 ---
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A4A6A)),
                      leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF4A4A6A)),
                      rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF4A4A6A)),
                    ),
                    calendarStyle: const CalendarStyle(
                      defaultTextStyle: TextStyle(color: Color(0xFF4A4A6A)),
                      weekendTextStyle: TextStyle(color: Color(0xFF4A4A6A)),
                      outsideTextStyle: TextStyle(color: Colors.grey),
                      todayDecoration: BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(color: Color(0xFF4A4A6A), shape: BoxShape.circle),
                      markerDecoration: BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold),
                      weekendStyle: TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- グラフ画面 ---
// --- グラフ画面（切り替え機能付き） ---
class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  // どのグラフを表示するか管理する変数 (0:すべて, 1:うれしい, 2:おこった, 3:かなしい)
  int _displayType = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('感情バランスグラフ')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('diaries')
            .orderBy('date')
            .limitToLast(7)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          List<FlSpot> happySpots = [], angrySpots = [], sadSpots = [];
          var docs = snapshot.data!.docs;
          
          for (int i = 0; i < docs.length; i++) {
            double x = i.toDouble();
            happySpots.add(FlSpot(x, (docs[i]['happy'] as num).toDouble()));
            angrySpots.add(FlSpot(x, (docs[i]['angry'] as num).toDouble()));
            sadSpots.add(FlSpot(x, (docs[i]['sad'] as num).toDouble()));
          }

          if (docs.isEmpty) return const Center(child: Text('日記を書いてグラフを作ろう！'));

          return Column(
            children: [
              const SizedBox(height: 10),
              // 切り替えスイッチ
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chip('すべて', 0, Colors.grey),
                    _chip('😊うれしい', 1, Colors.pink),
                    _chip('💢おこった', 2, Colors.orange),
                    _chip('😢かなしい', 3, Colors.blue),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 40, 40),
                  child: LineChart(LineChartData(
                    lineBarsData: [
                      if (_displayType == 0 || _displayType == 1)
                        LineChartBarData(spots: happySpots, color: Colors.pink, barWidth: 4, isCurved: true, dotData: const FlDotData(show: true)),
                      if (_displayType == 0 || _displayType == 2)
                        LineChartBarData(spots: angrySpots, color: Colors.orange, barWidth: 3, isCurved: true, dotData: const FlDotData(show: true)),
                      if (_displayType == 0 || _displayType == 3)
                        LineChartBarData(spots: sadSpots, color: Colors.blue, barWidth: 3, isCurved: true, dotData: const FlDotData(show: true)),
                    ],
                    minY: 1, maxY: 5,
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 40)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                  )),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 切り替え用のボタン（チップ）を作る関数
  Widget _chip(String label, int type, Color color) {
    bool isSelected = _displayType == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
        selected: isSelected,
        selectedColor: color,
        onSelected: (bool selected) {
          setState(() { _displayType = type; });
        },
      ),
    );
  }
}

// --- 日記入力画面（スライダー復活！） ---
class DiaryInputPage extends StatefulWidget {
  final DateTime selectedDate;
  const DiaryInputPage({super.key, required this.selectedDate});
  @override
  State<DiaryInputPage> createState() => _DiaryInputPageState();
}

class _DiaryInputPageState extends State<DiaryInputPage> {
  final TextEditingController _controller = TextEditingController();
  double _happy = 1, _angry = 1, _sad = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.selectedDate.month}/${widget.selectedDate.day} の日記')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(children: [
          TextField(controller: _controller, maxLines: 5, decoration: InputDecoration(hintText: '今日はどんな日だった？', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)))),
          const SizedBox(height: 30),
          emotionRow('😊 うれしい', _happy, Colors.pink, (v) => setState(() => _happy = v)),
          emotionRow('💢 おこった', _angry, Colors.orange, (v) => setState(() => _angry = v)),
          emotionRow('😢 かなしい', _sad, Colors.blue, (v) => setState(() => _sad = v)),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade100, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;
              await FirebaseFirestore.instance.collection('users').doc(uid).collection('diaries').add({
                'content': _controller.text, 'happy': _happy, 'angry': _angry, 'sad': _sad,
                'date': Timestamp.fromDate(widget.selectedDate), 'createdAt': Timestamp.now(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('保存する', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ]),
      ),
    );
  }
  Widget emotionRow(String label, double val, Color color, Function(double) onTap) {
    return ListTile(
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)), child: Text('Lv ${val.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      onTap: () => onTap((val % 5) + 1),
    );
  }
}

// --- マイページ画面（リッチ版 ＆ 保存機能付き） ---
class MyPage extends StatefulWidget {
  const MyPage({super.key});
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String _userName = '読み込み中...';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  Color _themeColor = Colors.pink;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _userName = data['name'] ?? 'ユーザー名未設定';
        if (data['themeColor'] != null) _themeColor = Color(data['themeColor']);
        if (data['reminderHour'] != null) {
          _reminderTime = TimeOfDay(hour: data['reminderHour'], minute: data['reminderMinute'] ?? 0);
        }
      });
    }
  }

  Future<void> _saveUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': _userName,
      'themeColor': _themeColor.value,
      'reminderHour': _reminderTime.hour,
      'reminderMinute': _reminderTime.minute,
    }, SetOptions(merge: true));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('設定を保存しました！')));
  }

  void _editName() {
    final controller = TextEditingController(text: _userName);
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('名前を変更'),
      content: TextField(controller: controller),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        TextButton(onPressed: () { setState(() => _userName = controller.text); _saveUserProfile(); Navigator.pop(context); }, child: const Text('保存')),
      ],
    ));
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) { setState(() => _reminderTime = picked); _saveUserProfile(); }
  }

  void _selectThemeColor() {
    showModalBottomSheet(context: context, builder: (context) => Container(
      padding: const EdgeInsets.all(20), height: 200,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _colorOption(Colors.pink), _colorOption(Colors.orange), _colorOption(Colors.blue), _colorOption(Colors.green), _colorOption(Colors.purple),
      ]),
    ));
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () { setState(() => _themeColor = color); _saveUserProfile(); Navigator.pop(context); },
      child: Container(width: 40, height: 40, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeColor.withOpacity(0.05),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0, pinned: true, backgroundColor: _themeColor,
            flexibleSpace: FlexibleSpaceBar(title: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold))),
          ),
          SliverToBoxAdapter(
            child: Column(children: [
              ListTile(leading: Icon(Icons.edit, color: _themeColor), title: const Text('名前を編集'), onTap: _editName),
              ListTile(leading: Icon(Icons.notifications, color: _themeColor), title: const Text('リマインダー'), subtitle: Text('毎日 ${_reminderTime.format(context)}'), onTap: _selectTime),
              ListTile(leading: Icon(Icons.palette, color: _themeColor), title: const Text('テーマカラー'), trailing: CircleAvatar(backgroundColor: _themeColor, radius: 10), onTap: _selectThemeColor),
              const SizedBox(height: 30),
              TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('ログアウト', style: TextStyle(color: Colors.red))),
            ]),
          ),
        ],
      ),
    );
  }
}