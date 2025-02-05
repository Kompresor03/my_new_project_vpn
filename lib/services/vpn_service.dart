import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'dart:async';

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
  
  VpnService() {
    // Инициализируем слушатели в конструкторе
    _initializeVpn();
  }

  Future<void> _initializeVpn() async {
    try {
      await _openVPN.initialize();
      
      // В v1.3.3 отсутствует API для подписки на изменение статуса,
      // поэтому здесь обратные вызовы не устанавливаются.
      
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
      if (!_initialized) {
        print("[VPN] Инициализация VPN сервиса...");
        await _initializeVpn();
      }

      _currentStatus = "connecting";
      _stateController.add(_currentStatus);
      
      print("[VPN] Начало подключения к VPN");
      print("[VPN] Конфигурация до модификации:\n$config");
      
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
      
      print("[VPN] Попытка подключения через OpenVPN...");
      await _openVPN.connect(config, "").timeout(
        Duration(seconds: 120),
        onTimeout: () {
          print("[VPN] Превышено время ожидания подключения (120 сек)");
          throw TimeoutException("VPN connection timeout");
        },
      );
      
      _currentStatus = "connected";
      _stateController.add(_currentStatus);
      print("[VPN] Подключение успешно установлено");
      
    } catch (e) {
      print("[VPN] Ошибка при подключении: $e");
      _currentStatus = "error";
      _stateController.add(_currentStatus);
      rethrow;
    }
  }
  
  /// Отключение от VPN.
  Future<void> disconnect() async {
    try {
      _openVPN.disconnect();
      _currentStatus = "disconnected";
      _stateController.add(_currentStatus);
      print("VpnService: Disconnected");
    } catch (e) {
      print("VpnService: Disconnect error: $e");
      rethrow;
    }
  }
  
  /// Возвращает текущее состояние VPN.
  String getStatus() {
    return _currentStatus;
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
    _openVPN.disconnect();
    _stateController.close();
  }
}
