import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async'; // Added for StreamSubscription
import 'screens/home_screen.dart';
import 'providers/notification_provider.dart';
import 'utils/notification_helper.dart';
import 'screens/login_screen.dart';
import '../utils/theme.dart';
import 'firebase_options.dart';

// Create a global key for navigation that can be accessed from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  NotificationHelper.showLocalNotification(message); // Display notification
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase initialized successfully with Prescribr-SC database.');

    // Initialize timezone data
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    //intialize notification helper
    await NotificationHelper.initialize();

    // Initialize FCM
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    //print FCM token
    String? fcmToken = await messaging.getToken();
    print("FCM Token: $fcmToken");

    // Request notification permissions (iOS only)
    await messaging.requestPermission();

    //Initialize dotenv
    await dotenv.load(fileName: ".env");

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        print("Received a message while in foreground: ${notification.title}");
        // Add the notification to the provider
        Provider.of<NotificationProvider>(navigatorKey.currentContext!,
                listen: false)
            .addNotification(notification.title ?? "No Title",
                notification.body ?? "No Body");
      }
    });
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatefulWidget {
  @override
  _AuthStateHandlerState createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  User? _currentUser;
  bool _isInitialized = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    print('🔴 AuthStateHandler initState');
    
    // Immediately check current user without waiting for stream
    _currentUser = FirebaseAuth.instance.currentUser;
    print('🔴 Initial auth check in initState: user=${_currentUser?.email}');
    
    // Important: IMMEDIATELY mark as initialized if we have a user
    if (_currentUser != null) {
      _isInitialized = true;
      print('🔴 User already logged in, marking as initialized');
    } else {
      // Add a safety timeout to ensure we don't get stuck in the loading state
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && !_isInitialized) {
          setState(() {
            _isInitialized = true;
            print('🔴 Forcing initialization after timeout');
          });
        }
      });
    }
    
    // Setup auth listener
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _listenToAuthChanges() {
    print('🔴 Setting up auth state listener');
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      print('🔴 Auth state changed: ${user?.email}, previous: ${_currentUser?.email}');
      
      // Force a fresh user check to ensure we have the latest state
      final freshUser = FirebaseAuth.instance.currentUser;
      print('🔴 Fresh user check: ${freshUser?.email}');
      
      if (!mounted) {
        print('🔴 Widget not mounted, skipping update');
        return;
      }
      
      // IMPORTANT: ALWAYS update state with the latest user info
      print('🔴 Updating state with current auth status');
      setState(() {
        _currentUser = freshUser;
        _isInitialized = true; // Always mark as initialized
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only get fresh user if we need to (reduces unnecessary operations)
    final refreshedUser = _isInitialized ? _currentUser : FirebaseAuth.instance.currentUser;
    
    print('🔴 AuthStateHandler build called: user=${_currentUser?.email}, fresh user=${refreshedUser?.email}, initialized=$_isInitialized');

    if (!_isInitialized) {
      // Still initializing - show loading spinner
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading Prescribr App...'),
            ],
          ),
        )
      );
    }

    if (_currentUser != null) {
      // User is logged in
      print('🔴 User authenticated: ${_currentUser?.email} - Showing HomeScreen');
      return const HomeScreen(initialIndex: 0);
    } else {
      // User is not logged in
      print('🔴 No authenticated user - Showing LoginScreen');
      return const LoginScreen();
    }
  }
}
