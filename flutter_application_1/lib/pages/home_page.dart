import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/icon_park_twotone.dart';
import '../widgets/calendar_section.dart';
import '../widgets/location_map.dart';
import '../user_data.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Handler polling background (top-level)
class AntiTheftTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return;
    try {
      final response = await ApiService().checkAntiTheft(token);
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}
      double? distance;
      if (data['distance'] != null) {
        if (data['distance'] is num) {
          distance = (data['distance'] as num).toDouble();
        } else {
          distance = double.tryParse(data['distance']);
        }
      }
      if (distance != null && distance > 50) {
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            channelKey: 'anti_theft_channel',
            title: 'Peringatan!',
            body: 'Sepeda berpindah lebih dari 50 meter!',
            notificationLayout: NotificationLayout.Default,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}
}

void antiTheftStartCallback() {
  FlutterForegroundTask.setTaskHandler(AntiTheftTaskHandler());
}

class HomePage extends StatefulWidget {
  final GlobalKey<CalendarSectionState>? calendarKey;

  const HomePage({super.key, this.calendarKey});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String selectedMonth = months[DateTime.now().month - 1];
  late int selectedYear = DateTime.now().year;

  bool _isBuzzerOn = false;
  bool _isLoadingBuzzer = false;
  bool _isParking = false;

  Timer? _antiTheftTimer;

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  String getGreeting() {
    final hour = DateTime.now().hour;
    final userName =
        UserData().fullName.isNotEmpty ? UserData().fullName : 'User';
    if (hour < 12) {
      return 'Selamat pagi, $userName!';
    } else if (hour < 17) {
      return 'Selamat siang, $userName!';
    } else if (hour < 20) {
      return 'Selamat sore, $userName!';
    } else {
      return 'Selamat malam, $userName!';
    }
  }

  String getFormattedDate() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthsShort = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final dayName = days[now.weekday - 1];
    final day = now.day;
    final month = monthsShort[now.month - 1];
    final year = now.year;

    return '$dayName, $day $month $year';
  }

  @override
  void initState() {
    super.initState();
    _fetchBuzzerState();
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'anti_theft_channel',
          channelName: 'Anti Theft Notifications',
          channelDescription: 'Notifikasi anti-maling CoolWheel',
          defaultColor: const Color(0xFF242E49),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          soundSource:
              'resource://raw/peringatan_sepeda_berpindah', // Tambahkan suara custom
        ),
      ],
      debug: true,
    );
    _requestNotificationPermission();
    _requestIgnoreBatteryOptimizations(); // Tambahkan permintaan izin background
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'anti_theft_channel',
        channelName: 'Anti Theft Notifications',
        channelDescription: 'Notifikasi anti-maling CoolWheel',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  void _requestIgnoreBatteryOptimizations() async {
    if (Platform.isAndroid) {
      final isIgnoring =
          await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      if (!isIgnoring) {
        await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
      }
    }
  }

  void _requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed && mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Izinkan Notifikasi'),
          content: const Text(
              'Aplikasi membutuhkan izin notifikasi untuk fitur anti-maling.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AwesomeNotifications()
                    .requestPermissionToSendNotifications();
              },
              child: const Text('Izinkan'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _fetchBuzzerState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return;
    try {
      final apiService = ApiService();
      final state = await apiService.getBuzzerState(token);
      setState(() {
        _isBuzzerOn = state;
      });
    } catch (e) {
      // Optionally show error
    }
  }

  Future<void> _toggleBuzzer() async {
    setState(() {
      _isLoadingBuzzer = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoadingBuzzer = false;
      });
      return;
    }
    final apiService = ApiService();
    try {
      final response = await apiService.playBuzzer(token);
      if (response.statusCode == 200) {
        // Ambil status buzzer terbaru dari backend
        final state = await apiService.getBuzzerState(token);
        setState(() {
          _isBuzzerOn = state;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBuzzerOn
                ? 'Buzzer berhasil dinyalakan!'
                : 'Buzzer berhasil dimatikan!'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menjalankan buzzer: \n${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingBuzzer = false;
      });
    }
  }

  void _startAntiTheftPolling(String token) {
    _antiTheftTimer?.cancel();
    _antiTheftTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        if (!_isParking) return;
        final apiService = ApiService();
        final antiTheftResponse = await apiService.checkAntiTheft(token);
        if (!_isParking) return;
        if (antiTheftResponse.statusCode == 200) {
          Map<String, dynamic> antiTheftData;
          if (antiTheftResponse.body is Map<String, dynamic>) {
            antiTheftData = antiTheftResponse.body as Map<String, dynamic>;
          } else if (antiTheftResponse.body.isNotEmpty) {
            antiTheftData = jsonDecode(antiTheftResponse.body);
          } else {
            antiTheftData = {};
          }
          double? distance;
          if (antiTheftData['distance'] != null) {
            if (antiTheftData['distance'] is num) {
              distance = (antiTheftData['distance'] as num).toDouble();
            } else {
              distance = double.tryParse(antiTheftData['distance']);
            }
          }
          if (_isParking && distance != null && distance > 50) {
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                channelKey: 'anti_theft_channel',
                title: 'Peringatan!',
                body: 'Sepeda berpindah lebih dari 50 meter!',
                notificationLayout: NotificationLayout.Default,
              ),
            );
          }
        }
      } catch (_) {}
    });
  }

  void _stopAntiTheftPolling() {
    _antiTheftTimer?.cancel();
    _antiTheftTimer = null;
  }

  void _startAntiTheftForegroundTask(String token) async {
    if (!Platform.isAndroid) return;
    await FlutterForegroundTask.startService(
      notificationTitle: 'Anti-Theft Aktif',
      notificationText: 'Monitoring sepeda berjalan di background',
      callback: antiTheftStartCallback,
    );
  }

  Future<void> _stopAntiTheftForegroundTask() async {
    if (!Platform.isAndroid) return;
    await FlutterForegroundTask.stopService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Stack(
        children: [
          // Main content with padding top to avoid header overlap
          Padding(
            padding: const EdgeInsets.only(top: 136), // Reduced from 120 to 110
            child: RefreshIndicator(
              onRefresh: () async {
                widget.calendarKey?.currentState?.refreshCalendar();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CalendarSection(
                        key: widget.calendarKey,
                        selectedMonth: selectedMonth,
                        year: selectedYear,
                        onMonthChanged: (newMonth) async {
                          setState(() {
                            selectedMonth = newMonth;
                          });
                        },
                        onYearChanged: (newYear) {
                          setState(() {
                            selectedYear = newYear;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text("Bike Location",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const LocationMap(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoadingBuzzer
                              ? null
                              : () async {
                                  setState(() {
                                    _isLoadingBuzzer = true;
                                  });
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final token = prefs.getString('token') ?? '';
                                  if (token.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Token tidak ditemukan'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    setState(() {
                                      _isLoadingBuzzer = false;
                                    });
                                    return;
                                  }
                                  final apiService = ApiService();
                                  try {
                                    final response =
                                        await apiService.playBuzzer(token);
                                    if (response.statusCode == 200) {
                                      setState(() {
                                        _isBuzzerOn = !_isBuzzerOn;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(_isBuzzerOn
                                              ? 'Buzzer berhasil dinyalakan!'
                                              : 'Buzzer berhasil dimatikan!'),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Gagal menjalankan buzzer: \n${response.body}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setState(() {
                                      _isLoadingBuzzer = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF242E49),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoadingBuzzer
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Iconify(
                                      IconParkTwotone.alarm,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isBuzzerOn
                                          ? 'Turn off buzzer'
                                          : 'Turn on buzzer',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('token') ?? '';
                            if (token.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Token tidak ditemukan'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _isParking = !_isParking;
                            });
                            if (_isParking) {
                              try {
                                final apiService = ApiService();
                                final response =
                                    await apiService.toggleParking(token);
                                if (response.statusCode == 201) {
                                  _startAntiTheftPolling(token);
                                  _startAntiTheftForegroundTask(
                                      token); // Panggil tanpa await karena fungsi void
                                  // Panggil checkAntiTheft hanya jika parkir berhasil diaktifkan
                                  final antiTheftResponse =
                                      await apiService.checkAntiTheft(token);
                                  if (antiTheftResponse.statusCode == 200) {
                                    try {
                                      Map<String, dynamic> antiTheftData;
                                      if (antiTheftResponse.body
                                          is Map<String, dynamic>) {
                                        antiTheftData = antiTheftResponse.body
                                            as Map<String, dynamic>;
                                      } else if (antiTheftResponse.body
                                          is String) {
                                        antiTheftData =
                                            jsonDecode(antiTheftResponse.body);
                                      } else {
                                        antiTheftData = {};
                                      }
                                      double? distance;
                                      if (antiTheftData['distance'] != null) {
                                        if (antiTheftData['distance'] is num) {
                                          distance =
                                              (antiTheftData['distance'] as num)
                                                  .toDouble();
                                        } else {
                                          distance = double.tryParse(
                                              antiTheftData['distance']);
                                        }
                                      }
                                      if (distance != null && distance > 50) {
                                        Future.delayed(
                                            Duration(milliseconds: 300), () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('sepeda berpindah'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Parkir & Anti-Theft aktif!'),
                                            backgroundColor: Colors.blueGrey,
                                          ),
                                        );
                                      }
                                    } catch (_) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Parkir & Anti-Theft aktif!'),
                                          backgroundColor: Colors.blueGrey,
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Parkir aktif, tapi gagal cek anti-theft: \n${antiTheftResponse.body}'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Gagal mengaktifkan parkir: \n${response.body}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  setState(() {
                                    _isParking = false;
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                setState(() {
                                  _isParking = false;
                                });
                              }
                            } else {
                              _stopAntiTheftPolling();
                              _stopAntiTheftForegroundTask(); // Panggil tanpa await karena fungsi void
                              ScaffoldMessenger.of(context).clearSnackBars();
                              await Future.delayed(
                                  const Duration(milliseconds: 100));
                              try {
                                final apiService = ApiService();
                                final response =
                                    await apiService.toggleParking(token);
                                if (response.statusCode == 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Parkir dinonaktifkan!'),
                                      backgroundColor: Colors.blueGrey,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Gagal menonaktifkan parkir: \n${response.body}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  setState(() {
                                    _isParking = true;
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                setState(() {
                                  _isParking = true;
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isParking
                                ? const Color(0xFF242E49)
                                : Colors.white,
                            foregroundColor: _isParking
                                ? Colors.white
                                : const Color(0xFF242E49),
                            elevation: 0,
                            side: const BorderSide(
                                color: Color(0xFF242E49), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Iconify(
                                MaterialSymbols.local_parking,
                                color: _isParking
                                    ? Colors.white
                                    : const Color(0xFF242E49),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isParking
                                    ? 'Nonaktifkan Parkir'
                                    : 'Aktifkan Parkir',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Fixed header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                  24, 52, 32, 20), // Reduced bottom padding from 24 to 20
              decoration: const BoxDecoration(
                color: Color(0xFF242E49),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Iconify(
                        MaterialSymbols.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        getFormattedDate(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // Reduced from 8 to 6
                  Text(
                    getGreeting(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
