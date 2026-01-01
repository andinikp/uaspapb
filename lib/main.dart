import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:andini1/services/auth_service.dart';
import 'package:andini1/models/user_model.dart';
import 'package:andini1/screens/login_screen.dart';
import 'package:andini1/models/pasien_model.dart';
import 'package:andini1/models/antrian_model.dart';
import 'package:andini1/models/rekam_medis_model.dart';
import 'package:andini1/models/obat_model.dart';
import 'package:andini1/models/resep_model.dart';
import 'package:andini1/repositories/pasien_repository.dart';
import 'package:andini1/repositories/antrian_repository.dart';
import 'package:andini1/repositories/rekam_medis_repository.dart';
import 'package:andini1/repositories/obat_repository.dart';
import 'package:andini1/repositories/resep_repository.dart';
import 'package:andini1/models/audit_model.dart';
import 'package:andini1/repositories/audit_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // safe register adapters
  try {
    Hive.registerAdapter(UserRoleAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(UserModelAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(PasienModelAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(AntrianStatusAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(AntrianModelAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(RekamMedisModelAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(ObatModelAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(ResepModelAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(ResepDetailModelAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(AuditModelAdapter());
  } catch (_) {}

  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<PasienModel>('pasienBox');
  await Hive.openBox<AntrianModel>('antrianBox');
  await Hive.openBox<RekamMedisModel>('rmBox');
  await Hive.openBox<ObatModel>('obatBox');
  await Hive.openBox<ResepModel>('resepBox');
  await Hive.openBox<AuditModel>('auditBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PasienRepository()),
        ChangeNotifierProvider(create: (_) => AntrianRepository()),
        ChangeNotifierProvider(create: (_) => RekamMedisRepository()),
        ChangeNotifierProvider(create: (_) => ObatRepository()),
        ChangeNotifierProvider(create: (_) => ResepRepository()),
        ChangeNotifierProvider(create: (_) => AuditRepository()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Klinik Lokal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}
