import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tyme/tyme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart'; // Import the new theme file

// --- 数据模型 ---
// Event 模型用于存储事件数据
class Event {
  String id;
  String title;
  DateTime nextOccurrence; // 此事件下一次发生的 *公历* 日期
  bool isLunar;
  int? lunarYear;
  int? lunarMonth;
  int? lunarDay;
  bool isLeapMonth; // 是否为闰月
  bool isRecurring;

  Event({
    required this.id,
    required this.title,
    required this.nextOccurrence,
    required this.isLunar,
    this.lunarYear,
    this.lunarMonth,
    this.lunarDay,
    this.isLeapMonth = false,
    required this.isRecurring,
  });

  // 用于 Hive 存储（JSON 序列化）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'nextOccurrence': nextOccurrence.toIso8601String(),
      'isLunar': isLunar,
      'lunarYear': lunarYear,
      'lunarMonth': lunarMonth,
      'lunarDay': lunarDay,
      'isLeapMonth': isLeapMonth,
      'isRecurring': isRecurring,
    };
  }

  // 从 JSON 反序列化
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      nextOccurrence: DateTime.parse(json['nextOccurrence']),
      isLunar: json['isLunar'],
      lunarYear: json['lunarYear'],
      lunarMonth: json['lunarMonth'],
      lunarDay: json['lunarDay'],
      isLeapMonth: json['isLeapMonth'],
      isRecurring: json['isRecurring'],
    );
  }
}

// --- 服务 ---
// NotificationService 处理本地通知 (兼容 Web)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Web 平台不执行原生初始化
    if (kIsWeb) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<void> requestPermissions() async {
    // Web 平台不请求原生权限
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> scheduleNotification(Event event) async {
    // Web 平台使用 console.log 模拟通知
    if (kIsWeb) {
      print('--- [WEB 提醒 STUB] ---');
      print('标题: ${event.title}');
      print('提醒时间 (公历): ${event.nextOccurrence}');
      print('-------------------------');
      return;
    }

    // 移动平台 (Android/iOS) 发送真实通知
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lunar_calendar_channel',
      '农历提醒',
      channelDescription: '用于农历日历事件提醒',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    // 确保使用本地时区
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(event.nextOccurrence, tz.local);

    await _plugin.zonedSchedule(
      event.id.hashCode,
      '日历提醒',
      event.title,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(String eventId) async {
    if (kIsWeb) return;
    await _plugin.cancel(eventId.hashCode);
  }
}

// --- 农历工具类 (使用 tyme.dart) ---
class TymeUtil {
  // [已修复] 核心: 从公历 DateTime 获取农历 LunarDay 对象
  static LunarDay getLunarDate(DateTime gregorianDate) {
    // 遵照您的指示，严格使用 .fromYmd
    SolarDay solarDay = SolarDay.fromYmd(
        gregorianDate.year, gregorianDate.month, gregorianDate.day);
    // 2. 使用 .getLunarDay() 转换为农历
    return solarDay.getLunarDay();
  }

  // [已修复] 获取农历日期的 *下一次* 对应的公历日期
  static DateTime getNextGregorianOccurrence(
      int lunarYear, int lunarMonth, int lunarDay, bool isLeap) {
    DateTime today = DateTime.now();
    DateTime todayDateOnly = DateTime(today.year, today.month, today.day);

    // [核心修复] 根据 isLeap 确定月份参数 (e.g., 6 or -6)
    int targetLunarMonth = isLeap ? -lunarMonth : lunarMonth;

    DateTime gregorianThisYear;
    try {
      // [核心修复] 直接使用 LunarDay.fromYmd 构造
      LunarDay lunarThisYear =
          LunarDay.fromYmd(today.year, targetLunarMonth, lunarDay);

      // [核心修复] 从 LunarDay 获取 SolarDay，再转为 DateTime
      SolarDay solarThisYear = lunarThisYear.getSolarDay();
      gregorianThisYear = DateTime(solarThisYear.getYear(),
          solarThisYear.getMonth(), solarThisYear.getDay());
    } catch (e) {
      // [核心修复] 捕获错误
      // 这通常意味着这一年没有这个日期 (e.g. 闰二月 in 2024, or 二月三十)
      // 我们将其设置为一个过去的日期，强制逻辑流向 "next year"
      gregorianThisYear = DateTime(1900, 1, 1);
    }

    // 5. 如果今年的日期已经过去 (或者今年不存在这个日期)
    if (gregorianThisYear.isBefore(todayDateOnly)) {
      // 尝试计算明年的
      try {
        LunarDay lunarNextYear =
            LunarDay.fromYmd(today.year + 1, targetLunarMonth, lunarDay);
        SolarDay solarNextYear = lunarNextYear.getSolarDay();
        return DateTime(solarNextYear.getYear(), solarNextYear.getMonth(),
            solarNextYear.getDay());
      } catch (e) {
        // 如果明年也不存在 (e.g. 闰月 in 2023, 2024, 但用户在 2023 年添加)
        // 我们就查后年 (保证健壮性)
        try {
          LunarDay lunarNextNextYear =
              LunarDay.fromYmd(today.year + 2, targetLunarMonth, lunarDay);
          SolarDay solarNextNextYear = lunarNextNextYear.getSolarDay();
          return DateTime(solarNextNextYear.getYear(),
              solarNextNextYear.getMonth(), solarNextNextYear.getDay());
        } catch (e2) {
          // 如果3年内都找不到 (e.g. 非法的 二月三十日), 返回一个默认的未来日期
          // 这种情况几乎不会发生，因为构造函数会检查
          return DateTime.now().add(const Duration(days: 365)); // Fallback
        }
      }
    } else {
      // 今年的日期还没到
      return gregorianThisYear;
    }
  }

  // 辅助函数：获取用于显示的农历文本 (使用 tyme API)
  static String getLunarDayText(LunarDay lunar) {
    // 优先显示节气
    // String text = lunar.getTerm();
    // if (text.isNotEmpty) return text;

    // 其次显示节日 (基于 API, .getFestival() 返回 LunarFestival? 或 null)
    // 注意: tyme API 中 .getFestival() 仅返回农历节日
    LunarFestival? lunarFestival = lunar.getFestival();
    if (lunarFestival != null) {
      return lunarFestival.getName();
    }

    // 再次显示公历节日 (如国庆)
    // text = lunar.getSolarFestival();
    // if (text.isNotEmpty) return text;

    // 如果都不是，显示农历日 (e.g. 初一, 初二... 或 正月)
    // [已修复] 遵照 API，使用 .getName() 和 .getLunarMonth().getName()
    return lunar.getName() == '初一'
        ? lunar.getLunarMonth().getName() // 如果是初一，显示月份 (e.g. 正月, 闰二月)
        : lunar.getName(); // 否则显示日期 (e.g. 初二, 廿三)
  }
}

// --- 主应用 ---

const String kHiveBoxName = 'events';
const Uuid kUuid = Uuid();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化时区
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.local);

  // 平台特定的 Hive 初始化
  if (kIsWeb) {
    // Web: 不需要路径，它会自动使用 IndexedDB
    await Hive.initFlutter();
  } else {
    // Mobile: 需要 path_provider 来指定路径
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
  }

  // 打开 Box (所有平台通用)
  await Hive.openBox<String>(kHiveBoxName);

  // 初始化通知服务 (内部已有 Web 检查)
  await NotificationService().init();
  await NotificationService().requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '农历提醒日历',
      theme: AppTheme.lightTheme, // Use the custom Classic Elegance theme
      // 启用中文本地化
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: const CalendarScreen(),
    );
  }
}

// --- 日历主屏幕 ---

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final Box<String> _eventBox;
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<String, Event> _allEvents = {};

  @override
  void initState() {
    super.initState();
    _eventBox = Hive.box<String>(kHiveBoxName);
    _selectedDay = _focusedDay;

    _loadAllEvents();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // 从 Hive 加载所有事件到内存
  void _loadAllEvents() {
    setState(() {
      _allEvents.clear();
      for (var key in _eventBox.keys) {
        final jsonString = _eventBox.get(key);
        if (jsonString != null) {
          final event = Event.fromJson(jsonDecode(jsonString));
          _allEvents[event.id] = event;
        }
      }
    });
  }

  // [核心] 获取某一天的所有事件 (使用 TymeUtil)
  List<Event> _getEventsForDay(DateTime day) {
    final List<Event> events = [];
    // 1. 获取当天的农历信息
    final LunarYear lunarYear =
        TymeUtil.getLunarDate(day).getLunarMonth().getLunarYear();
    final LunarDay lunarDay = TymeUtil.getLunarDate(day);

    for (final event in _allEvents.values) {
      if (event.isLunar) {
        // 2. 匹配农历事件
        // [已修复] 遵照 API, 使用 .getLunarMonth()
        int currentLunarMonth = lunarDay.getLunarMonth().getMonth();
        bool isCurrentLeap = lunarDay.getLunarMonth().isLeap();

        if (event.isRecurring) {
          // 农历循环事件：只匹配月日和闰月标志
          if (event.lunarMonth == currentLunarMonth &&
              event.lunarDay == lunarDay.getDay() &&
              event.isLeapMonth == isCurrentLeap) {
            events.add(event);
          }
        } else {
          // 农历一次性事件：需要完整匹配年月日
          if (event.lunarYear == lunarYear.getYear() &&
              event.lunarMonth == currentLunarMonth &&
              event.lunarDay == lunarDay.getDay() &&
              event.isLeapMonth == isCurrentLeap) {
            events.add(event);
          }
        }
      } else {
        // 3. 匹配公历事件
        if (event.isRecurring) {
          // 公历循环事件：只匹配月日
          if (event.nextOccurrence.month == day.month &&
              event.nextOccurrence.day == day.day) {
            events.add(event);
          }
        } else {
          // 公历一次性事件：完整匹配年月日
          if (isSameDay(event.nextOccurrence, day)) {
            events.add(event);
          }
        }
      }
    }
    return events;
  }

  // 当用户点击日历上的日期时
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  // [已修改] 显示添加/编辑事件的底部弹窗
  void _showAddEventDialog({Event? eventToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AddEventSheet(
            // 如果是新增，使用日历选中的日期；如果是编辑，使用 null
            selectedDate: eventToEdit == null ? _selectedDay! : null,
            eventToEdit: eventToEdit,
            onSave: (Event newEvent) {
              // 1. 保存到 Hive (put 会自动覆盖)
              _eventBox.put(newEvent.id, jsonEncode(newEvent.toJson()));
              // 2. 安排通知
              NotificationService().scheduleNotification(newEvent);
              // 3. 刷新 UI
              _loadAllEvents();
              _selectedEvents.value = _getEventsForDay(_selectedDay!);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  // [新功能] 显示删除确认对话框
  void _showDeleteConfirmationDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('您确定要删除 "${event.title}" 吗？'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(ctx).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
              onPressed: () {
                Navigator.of(ctx).pop(true);
              },
            ),
          ],
        );
      },
    ).then((result) {
      if (result == true) {
        _performDelete(event);
      }
    });
  }

  // [新功能] 执行删除操作
  void _performDelete(Event event) async {
    // 1. 从 Hive 删除
    await _eventBox.delete(event.id);
    // 2. 取消通知
    await NotificationService().cancelNotification(event.id);
    // 3. 刷新 UI
    _loadAllEvents();
    _selectedEvents.value = _getEventsForDay(_selectedDay!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('"${event.title}" 已删除'),
          backgroundColor: Colors.red[700]),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Custom Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20),
            decoration: const BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '農曆新年', // Traditional Lunar New Year Text
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Noto Serif SC',
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '二零二五', // Year 2025 (Snake Year)
                  style: TextStyle(
                    color: AppColors.accentGold.withOpacity(0.8),
                    fontSize: 18,
                    fontFamily: 'Noto Serif SC',
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Calendar "Scroll" Container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBeige,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderBeige, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: TableCalendar<Event>(
                      locale: 'zh_CN',
                      firstDay: DateTime.utc(2010, 1, 1),
                      lastDay: DateTime.utc(9999, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      eventLoader: _getEventsForDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed),
                        leftChevronIcon:
                            Icon(Icons.chevron_left, color: AppColors.primaryRed),
                        rightChevronIcon:
                            Icon(Icons.chevron_right, color: AppColors.primaryRed),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        todayDecoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryRed, width: 1.5),
                        ),
                        todayTextStyle: const TextStyle(
                            color: AppColors.primaryRed, fontWeight: FontWeight.bold),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                            color: AppColors.accentGold, fontWeight: FontWeight.bold),
                        markerDecoration: const BoxDecoration(
                          color: AppColors.accentGold,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
                        weekendTextStyle: const TextStyle(color: AppColors.primaryRed),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final lunar = TymeUtil.getLunarDate(day);
                          final lunarText = TymeUtil.getLunarDayText(lunar);
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderBeige),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    lunarText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          final lunar = TymeUtil.getLunarDate(day);
                          final lunarText = TymeUtil.getLunarDayText(lunar);
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryRed),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryRed.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.accentGold,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    lunarText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.accentGold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final lunar = TymeUtil.getLunarDate(day);
                          final lunarText = TymeUtil.getLunarDayText(lunar);
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryRed, width: 1.5),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.primaryRed,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    lunarText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Event List
                  ValueListenableBuilder<List<Event>>(
                    valueListenable: _selectedEvents,
                    builder: (context, value, _) {
                      if (value.isEmpty) {
                        final LunarDay lunar = TymeUtil.getLunarDate(_selectedDay!);
                        final LunarYear lunarYear =
                            lunar.getLunarMonth().getLunarYear();
                        final String solarDate =
                            DateFormat.yMMMd('zh_CN').format(_selectedDay!);
                        final String lunarDate =
                            "${lunarYear.getName()} ${lunar.getLunarMonth().getName()}${lunar.getName()}";

                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              '$solarDate\n$lunarDate\n\n无提醒事项',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  height: 1.5),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        shrinkWrap: true, // Important for nesting in SingleChildScrollView
                        physics: const NeverScrollableScrollPhysics(), // Important
                        itemCount: value.length,
                        itemBuilder: (context, index) {
                          final event = value[index];
                          String subtitleText;
                          if (event.isLunar) {
                            String lunarMonthName = "";
                            String lunarDayName = "";
                            if (event.lunarMonth != null &&
                                event.lunarMonth! > 0 &&
                                event.lunarMonth! <= LunarMonth.names.length) {
                              lunarMonthName =
                                  LunarMonth.names[event.lunarMonth! - 1];
                            } else {
                              lunarMonthName = "${event.lunarMonth}月";
                            }
                            if (event.isLeapMonth) {
                              lunarMonthName = "闰$lunarMonthName";
                            }
                            if (event.lunarDay != null &&
                                event.lunarDay! > 0 &&
                                event.lunarDay! <= LunarDay.names.length) {
                              lunarDayName = LunarDay.names[event.lunarDay! - 1];
                            } else {
                              lunarDayName = "${event.lunarDay}日";
                            }
                            subtitleText =
                                '农历: $lunarMonthName$lunarDayName ${event.isRecurring ? "(每年)" : ""}';
                          } else {
                            subtitleText =
                                '公历: ${DateFormat.yMMMd('zh_CN').format(event.nextOccurrence)}';
                          }

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              onTap: () {
                                _showAddEventDialog(eventToEdit: event);
                              },
                              leading: Icon(
                                event.isLunar
                                    ? Icons.brightness_3_outlined
                                    : Icons.calendar_today,
                                color: AppColors.primaryRed,
                              ),
                              title: Text(event.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              subtitle: Text(
                                subtitleText,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () =>
                                    _showDeleteConfirmationDialog(context, event),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 添加/编辑事件的底部弹窗 (已重构) ---
class AddEventSheet extends StatefulWidget {
  // [新] selectedDate 仅用于“新增”，编辑时为 null
  final DateTime? selectedDate;
  // [新] eventToEdit 用于“编辑”，新增时为 null
  final Event? eventToEdit;
  final Function(Event) onSave;

  const AddEventSheet(
      {super.key, this.selectedDate, this.eventToEdit, required this.onSave})
      : assert(selectedDate != null || eventToEdit != null,
            'Either selectedDate or eventToEdit must be provided');

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _titleController = TextEditingController();
  late bool _isLunar;
  late bool _isRecurring;
  late bool _isLeapMonth;
  bool _currentDayHasLeapMonth = false;
  late bool _isEditing;

  // [新] 状态变量，用于存储当前表单的日期
  late DateTime _date;
  late int _lunarYear;
  late LunarDay _lunarInfo;
  late int _lunarMonth;
  late int _lunarDay;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.eventToEdit != null;

    if (_isEditing) {
      // --- 编辑模式 ---
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _isLunar = event.isLunar;
      _isRecurring = event.isRecurring;
      _isLeapMonth = event.isLeapMonth;

      // [新] 使用事件的下次发生日期作为基础
      // 注意：对于农历事件，这可能是去年的日期，但没关系，
      // TymeUtil.getLunarDate 会正确处理它以获取 *当前* 的农历信息
      _date = event.nextOccurrence;
      _lunarInfo = TymeUtil.getLunarDate(_date);

      if (_isLunar) {
        // 从 *已保存* 的事件数据中加载农历信息
        _lunarMonth = event.lunarMonth!;
        _lunarDay = event.lunarDay!;
        // 检查 *当前* 选中的日期是否是闰月，以决定是否显示 Checkbox
        _currentDayHasLeapMonth = _lunarInfo.getLunarMonth().isLeap();
      }
    } else {
      // --- 新增模式 ---
      _date = widget.selectedDate!;
      _isLunar = true; // 新事件默认是农历
      _isRecurring = true; // 默认为true
      _updateLunarInfo(_date); // 使用日历选中的日期初始化
    }
  }

  // 当日期或类型变化时，更新农历信息
  void _updateLunarInfo(DateTime date) {
    setState(() {
      _date = date; // 更新状态
      _lunarInfo = TymeUtil.getLunarDate(date);

      // [已修复] 遵照 API, 使用 .getLunarMonth()
      _lunarYear = _lunarInfo.getLunarMonth().getLunarYear().getYear();
      _lunarMonth = _lunarInfo.getLunarMonth().getMonth();
      _lunarDay = _lunarInfo.getDay();
      _currentDayHasLeapMonth = _lunarInfo.getLunarMonth().isLeap();

      // 默认勾选
      if (_currentDayHasLeapMonth) {
        _isLeapMonth = true;
      } else {
        _isLeapMonth = false; // 如果不是闰月，取消勾选
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // [新功能] 弹出日期选择器
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null && picked != _date) {
      _updateLunarInfo(picked); // 使用新选中的日期更新所有状态
    }
  }

  void _saveEvent() {
    final title = _titleController.text;
    if (title.isEmpty) return;

    // [新] 编辑时使用旧 ID，新增时使用新 ID
    final String eventId = widget.eventToEdit?.id ?? kUuid.v4();
    Event newEvent;

    if (_isLunar) {
      // 1. 从 *状态* 获取农历月日
      // (注意: _lunarMonth, _lunarDay 在 _updateLunarInfo 中被设置)

      // 2. 计算下一次公历发生日期
      final DateTime nextOccurrence = TymeUtil.getNextGregorianOccurrence(
          _lunarYear,
          _lunarMonth,
          _lunarDay,
          _isLeapMonth); // _isLeapMonth 由 Checkbox 决定

      newEvent = Event(
        id: eventId,
        title: title,
        nextOccurrence: nextOccurrence,
        isLunar: true,
        lunarYear: _lunarYear,
        lunarMonth: _lunarMonth,
        lunarDay: _lunarDay,
        isLeapMonth: _isLeapMonth, // 用户是否指定为闰月
        isRecurring: _isRecurring,
      );
    } else {
      // 保存公历事件
      newEvent = Event(
        id: eventId,
        title: title,
        nextOccurrence: _date, // 使用状态中的公历日期
        isLunar: false,
        isRecurring: _isRecurring,
      );
    }

    // 调用回调保存
    widget.onSave(newEvent);
  }

  @override
  Widget build(BuildContext context) {
    // 确保UI实时反映选中的日期
    // [已修复] 遵照 API, 使用 .getName()
    String lunarDateText =
        "${_lunarInfo.getLunarMonth().getLunarYear().getName()}${_lunarInfo.getLunarMonth().getName()}${_lunarInfo.getName()}";
    String gregorianDateText = DateFormat.yMMMd('zh_CN').format(_date);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? '编辑提醒事项' : '添加提醒事项',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '事件标题',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            // 农历/公历 切换
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('农历'),
                  selected: _isLunar,
                  onSelected: (selected) {
                    setState(() {
                      _isLunar = true;
                    });
                  },
                  selectedColor: AppColors.primaryRed.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _isLunar ? AppColors.primaryRed : AppColors.textPrimary,
                    fontWeight: _isLunar ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('公历'),
                  selected: !_isLunar,
                  onSelected: (selected) {
                    setState(() {
                      _isLunar = false;
                    });
                  },
                  selectedColor: AppColors.primaryRed.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: !_isLunar ? AppColors.primaryRed : AppColors.textPrimary,
                    fontWeight: !_isLunar ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // --- 日期显示和更改 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLunar) ...[
                        Text(
                          '农历日期: $lunarDateText',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ] else ...[
                        Text(
                          '公历日期: $gregorianDateText',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('更改日期'),
                ),
              ],
            ),

            // 仅当该月确实是闰月时，才显示闰月选项
            if (_isLunar && _currentDayHasLeapMonth)
              CheckboxListTile(
                // [已修复] 遵照 API, 使用 .getLunarMonth().getName()
                title: Text('设为闰${_lunarInfo.getLunarMonth().getName()}提醒'),
                value: _isLeapMonth,
                onChanged: (value) {
                  setState(() {
                    _isLeapMonth = value!;
                  });
                },
                activeColor: AppColors.primaryRed,
                contentPadding: EdgeInsets.zero,
              ),

            // 每年提醒
            CheckboxListTile(
              title: const Text('每年提醒'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value!;
                });
              },
              activeColor: AppColors.primaryRed,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: AppColors.accentGold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_isEditing ? '更新' : '保存',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
