import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class VpnService {
  final OpenVPN _openVPN = OpenVPN();
  bool _initialized = false; // Флаг инициализации
  int _port = 1194; // Порт по умолчанию
  String? _host;  // Добавляем хост

  // Контроллер для оповещений о состоянии VPN (broadcast stream)
  final StreamController<String> _stateController = StreamController<String>.broadcast();
  
  // Текущее состояние VPN (например, "disconnected", "connecting", "connected", "error")
  String _currentStatus = "disconnected";

  // Геттер возвращает поток состояний VPN
  Stream<String> get vpnStateStream => _stateController.stream;
  
  Timer? _statusTimer;

  VpnService() {
    // Не инициализируем сразу
  }

  Future<void> initialize() async {
    if (!_initialized) {
      await _initializeVpn();
    }
  }

  Future<void> _initializeVpn() async {
    try {
      await _openVPN.initialize();
      
      // Настраиваем периодическую проверку статуса
      _statusTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
        try {
          final dynamic status = await _openVPN.status();
          debugPrint('[VPN] Current status: $status');
          
          if (status != null && status is Map<String, dynamic>) {
            // Определяем статус на основе значений в Map
            String newStatus = "UNKNOWN";
            
            // Проверяем значения для определения статуса
            if (status['duration'] != null) {
              if (status['duration'] != "00:00:00") {
                newStatus = "CONNECTED";
              } else {
                newStatus = "DISCONNECTED";
              }
            }
            
            // Обновляем статус только если он изменился
            if (newStatus != _currentStatus) {
              debugPrint('[VPN] Status changed: $newStatus');
              switch (newStatus) {
                case "CONNECTED":
                  _currentStatus = "connected";
                  _stateController.add(_currentStatus);
                  break;
                case "DISCONNECTED":
                  _currentStatus = "disconnected";
                  _stateController.add(_currentStatus);
                  break;
                case "CONNECTING":
                  _currentStatus = "connecting";
                  _stateController.add(_currentStatus);
                  break;
                case "DISCONNECTING":
                  _currentStatus = "disconnecting";
                  _stateController.add(_currentStatus);
                  break;
                case "ERROR":
                  _currentStatus = "error";
                  _stateController.add(_currentStatus);
                  break;
                default:
                  debugPrint('[VPN] Unhandled status: $newStatus');
              }
            }
          }
        } catch (e) {
          debugPrint('[VPN] Error checking status: $e');
        }
      });
      
      _initialized = true;
    } catch (e) {
      print("[VPN] Initialization error: $e");
      _currentStatus = "error";
      _stateController.add(_currentStatus);
    }
  }

  /// Устанавливает порт для VPN подключения
  void setPort(int port) {
    _port = port;
  }

  /// Устанавливает хост для VPN подключения
  void setHost(String host) {
    _host = host;
  }

  /// Подключение к VPN с использованием переданной [config].
  /// Перед вызовом подключения проверяем инициализацию.
  /// Второй аргумент передается пустой строкой для соответствия сигнатуре плагина.
  Future<void> connect(String config) async {
    try {
      await initialize();  // Инициализируем при подключении
      if (!_initialized) {
        throw Exception('VPN service not initialized');
      }

      _currentStatus = "connecting";
      _stateController.add(_currentStatus);
      
      // Проверяем целостность конфигурации
      if (!config.contains('</ca>') || !config.contains('</cert>') || !config.contains('</key>')) {
        throw Exception('Incomplete OpenVPN configuration: Missing required certificates');
      }

      debugPrint('[VPN] Начало подключения к VPN');
      debugPrint('[VPN] Конфигурация до модификации:');
      debugPrint(config);
      
      // Проверяем разрешения
      var permStatus = await Permission.notification.status;
      debugPrint('[VPN] Статус разрешения уведомлений: $permStatus');
      
      if (!permStatus.isGranted) {
        debugPrint('[VPN] Запрашиваем разрешение на уведомления');
        await Permission.notification.request();
      }

      // VPN разрешения запрашиваются автоматически плагином

      if (_host != null) {
        final String protocol = (_port == 443) ? 'tcp' : 'udp';
        
        // Добавляем логирование изменений
        print("[VPN] Изменение протокола на: $protocol");
        print("[VPN] Изменение хоста на: $_host:$_port");
        
        // Исправляем регулярные выражения
        config = config.replaceAll(RegExp(r'^proto\s+\S+', multiLine: true), 'proto $protocol');
        config = config.replaceAll(RegExp(r'^remote\s+\S+\s+\S+', multiLine: true), 'remote $_host $_port');
        
        // Добавляем дополнительные параметры для TCP подключения
        if (protocol == 'tcp') {
          print("[VPN] Добавление TCP-специфичных параметров");
          config += '''
connect-retry 2
connect-timeout 15
resolv-retry infinite
explicit-exit-notify 2
pull-filter ignore "route-ipv6"
pull-filter ignore "ifconfig-ipv6"
''';
        }
        
        print("[VPN] Итоговая конфигурация:\n$config");
      }
      
      debugPrint('[VPN] Попытка подключения через OpenVPN...');

      try {
        await _openVPN.connect(
          config,
          'SpyDog VPN',
          username: '',
          password: '',
          bypassPackages: [],
          certIsRequired: true,
        );
      } catch (vpnError) {
        debugPrint('[VPN] Ошибка при подключении OpenVPN: $vpnError');
        rethrow;
      }
      
      print("[VPN] Подключение успешно установлено");
      
    } catch (e) {
      debugPrint('[VPN] Общая ошибка при подключении: $e');
      debugPrint('[VPN] Stack trace: ${StackTrace.current}');
      _currentStatus = "error";
      _stateController.add(_currentStatus);
      rethrow;
    }
  }
  
  /// Отключение от VPN.
  Future<void> disconnect() async {
    try {
      await initialize();  // Инициализируем при отключении
      if (!_initialized) {
        throw Exception('VPN service not initialized');
      }
      _openVPN.disconnect();  // Убираем await, так как метод возвращает void
      _currentStatus = "disconnected";
      _stateController.add(_currentStatus);
      print("VpnService: Disconnected");
    } catch (e) {
      print("VpnService: Disconnect error: $e");
      rethrow;
    }
  }
  
  /// Возвращает текущее состояние VPN.
  Map<String, String>? getStatus() {
    // Возвращаем Map с данными о статусе
    return {
      'byteIn': '0',
      'byteOut': '0',
      // другие данные статуса...
    };
  }
  
  /// Проверяет доступность сервера с указанным [host] и [port].
  /// Возвращает структуру с результатами проверки (симуляция).
  Future<Map<String, dynamic>> checkServerAvailability(String host, int port) async {
    try {
      final status = _currentStatus;
      return {
        "available": status == "connected" || status == "disconnected",
        "details": {
          "ping": true,
          "last_check": DateTime.now().toIso8601String(),
          "status": status
        },
        "error": null,
      };
    } catch (e) {
      return {
        "available": false,
        "details": null,
        "error": e.toString(),
      };
    }
  }
  
  /// Освобождает ресурсы, закрывая поток состояний.
  void dispose() {
    _statusTimer?.cancel();
    _openVPN.disconnect();
    _stateController.close();
  }
}
