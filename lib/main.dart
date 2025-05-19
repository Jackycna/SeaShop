import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/profile/deletion_page.dart';
import 'package:sea_shop/src/profile/new_profile.dart';
import 'package:sea_shop/src/sign_in/signin_page.dart';
import 'package:sea_shop/src/sign_in/userinformation_page.dart';
import 'package:sea_shop/src/home.dart';
import 'package:sea_shop/src/some/splash_screen.dart';
import 'dart:async';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyA58z2uu3v1rPSWrNxpO5CsCMuC5_GqWHA",
            authDomain: "sea-shop.firebaseapp.com",
            databaseURL: "https://sea-shop-default-rtdb.firebaseio.com",
            projectId: "sea-shop",
            storageBucket: "sea-shop.appspot.com",
            messagingSenderId: "140729895728",
            appId: "1:140729895728:web:fba341546eb3f4a5a216f5"));
  } else {
    await Firebase.initializeApp();
  }

  // Firebase messaging setup
  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: androidInitSettings);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Firebase messaging setup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Timer? _updateTimer;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _startPeriodicUpdateCheck();
    _loadLanguage();

    FirebaseMessaging.instance.requestPermission();
    _getDeviceToken();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received a foreground message: ${message.messageId}');
      }
      _showNotification(message);
    });
  }

  Future<void> _loadLanguage() async {
    String languageCode = await LocalizationService().getSavedLanguage();
    setState(() {
      _currentLanguage = languageCode;
    });
    // Load the language strings after loading the saved language
    await LocalizationService().loadLanguage(_currentLanguage);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicUpdateCheck() {
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForUpdates();
    });
  }

  void _checkForUpdates() {
    if (kDebugMode) {
      print("Checking for updates...");
    }
  }

  Future<void> _getDeviceToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      print("FCM Token: $token");
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message.',
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sea Shop',
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate, // Add the localization delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English language
        Locale('ta', ''), // Tamil language
      ],
      localeResolutionCallback:
          (Locale? deviceLocale, Iterable<Locale> supportedLocales) {
        for (var locale in supportedLocales) {
          if (locale.languageCode == deviceLocale?.languageCode) {
            LocalizationService().loadLanguage(locale.languageCode);
            return locale;
          }
        }

        LocalizationService().loadLanguage('en');
        return const Locale('en');
      },
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF003780),
          ),
        ),
        colorScheme: const ColorScheme.light(primary: Color(0xFF003780))
            .copyWith(secondary: const Color(0xFF003780)),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/delete': (context) => const AccountDeletionPage(),
        '/': (context) => const AuthChecker(),
        '/sign_in': (context) => const SignInPage(),
        '/user': (context) => const UserDetailsPage(),
        '/home': (context) => const Nav(),
        '/profile': (context) => const ProfilePages(),
      },
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  AuthCheckerState createState() => AuthCheckerState();
}

class AuthCheckerState extends State<AuthChecker> {
  late StreamSubscription<User?> _authStateSubscription;

  @override
  void initState() {
    super.initState();

    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _checkUserExists(user.uid);
      } else {
        Navigator.pushReplacementNamed(context, '/sign_in');
      }
    });
  }

  Future<void> _checkUserExists(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/splash');
        }
      } else {
        _showUserNotFoundDialog();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking user details: $e');
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/sign_in');
      }
    }
  }

  void _showUserNotFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('User Not Found'),
        content: const Text(
          'No details found for this account. Please register with a different number.',
        ),
        actions: [
          TextButton(
            onPressed: () => exit(0), // Closes the app
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.black),
    );
  }
}
