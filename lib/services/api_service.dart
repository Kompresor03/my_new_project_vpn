import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/location.dart';

class ApiService {
  static const String baseUrl = 'http://159.223.5.41/material-admin-master';  // Обновлен URL

  Future<http.Response> _get(String endpoint, [Map<String, String>? params]) async {
    var uri = Uri.parse('$baseUrl/api/$endpoint');
    if (params != null) {
      uri = uri.replace(queryParameters: params);
    }
    return await http.get(uri).timeout(Duration(seconds: 10));
  }

  Future<List<VpnLocation>> getLocations({String type = 'all'}) async {
    try {
      final url = '${ApiService.baseUrl}/api/get_locations_list.php?type=$type';
      debugPrint('[API] Fetching URL: $url');

      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[ERROR] API Timeout');
          throw Exception('Connection timeout');
        },
      );

      debugPrint('[API] Status Code: ${response.statusCode}');
      debugPrint('[API] Response Headers: ${response.headers}');
      debugPrint('[API] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('[API] Parsed Data: $data');

        if (data['success'] == true && data['data'] != null) {
          final locations = (data['data'] as List)
              .map((json) => VpnLocation.fromJson(json))
              .toList();
          debugPrint('[API] Found ${locations.length} locations');
          
          // Проверяем наличие локации с ID 18
          final location18 = locations.where((loc) => loc.id == 18).toList();
          if (location18.isNotEmpty) {
            debugPrint('[API] Location 18 found: ${location18.first}');
          } else {
            debugPrint('[API] Location 18 not found in response');
          }
          
          return locations;
        } else {
          throw Exception(data['error'] ?? 'Failed to load locations');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API] Error: $e');
      throw Exception('Failed to get locations: $e');
    }
  }

  Future<String> getVpnConfig(int locationId) async {
    try {
      debugPrint('[API] Getting config for location ID: $locationId');
      final response = await _get('get_vpn_config.php', {
        'location_id': locationId.toString()
      });
      debugPrint('[API] Config response status: ${response.statusCode}');
      debugPrint('[API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          if (data['config'] == null) {
            debugPrint('[API] Error: No config in response');
            throw Exception('No VPN config in response');
          }
          String config = data['config'] as String;
          if (!config.contains('</ca>') || !config.contains('</cert>') || !config.contains('</key>')) {
            debugPrint('[API] Error: Incomplete OpenVPN configuration');
            throw Exception('Incomplete OpenVPN configuration');
          }
          debugPrint('[API] Полная конфигурация VPN получена успешно');
          return config;
        }
        if (data['error'] != null) {
          debugPrint('[API] Server error: ${data['error']}');
          throw Exception('Server error: ${data['error']}');
        }
      }
      debugPrint('[API] Failed to get valid config. Status: ${response.statusCode}');
      throw Exception('Failed to get VPN config');
    } catch (e) {
      debugPrint('[API] Ошибка получения конфигурации VPN: $e');
      debugPrint('[API] Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  bool _validateConfig(String config) {
    // Проверяем обязательные секции
    final requiredSections = [
      'client',
      'dev tun',
      '<ca>',
      '</ca>',
      '<cert>',
      '</cert>',
      '<key>',
      '</key>'
    ];

    for (final section in requiredSections) {
      if (!config.contains(section)) {
        debugPrint('[API] Missing required section: $section');
        return false;
      }
    }

    // Проверяем базовые параметры
    final requiredParams = [
      'remote',
      'proto',
      'cipher',
      'auth',
    ];

    for (final param in requiredParams) {
      if (!config.split('\n').any((line) => line.trim().startsWith(param))) {
        debugPrint('[API] Missing required parameter: $param');
        return false;
      }
    }

    // Проверяем формат сертификатов
    if (!_validateCertificateSection(config, 'ca') ||
        !_validateCertificateSection(config, 'cert') ||
        !_validateCertificateSection(config, 'key')) {
      return false;
    }

    return true;
  }

  bool _validateCertificateSection(String config, String section) {
    final startTag = '<$section>';
    final endTag = '</$section>';
    
    final start = config.indexOf(startTag);
    final end = config.indexOf(endTag);
    
    if (start == -1 || end == -1 || start >= end) {
      debugPrint('[API] Invalid $section section format');
      return false;
    }

    final cert = config.substring(start + startTag.length, end).trim();
    if (!cert.contains('-----BEGIN') || !cert.contains('-----END')) {
      debugPrint('[API] Invalid $section content format');
      return false;
    }

    return true;
  }

  Future<List<Map<String, dynamic>>> getVPNGateServers() async {
    try {
      debugPrint('[API] Fetching VPNGate servers...');
      final response = await http.get(Uri.parse('http://www.vpngate.net/api/iphone/'));
      
      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> servers = [];
        final lines = response.body.split('\n');
        
        // Пропускаем первые две строки (заголовок)
        for (var i = 2; i < lines.length; i++) {
          final fields = lines[i].split(',');
          if (fields.length > 14) {
            servers.add({
              'config': utf8.decode(base64.decode(fields[14])),
              'country': fields[6],
              'countryShort': fields[7],
              'ip': fields[1],
              'hostname': fields[0],
              'speed': int.parse(fields[4]),
              'ping': int.parse(fields[3]),
              'uptime': fields[9],
              'users': fields[10],
              'score': fields[13]
            });
          }
        }

        // Сортируем по скорости и пингу
        servers.sort((a, b) {
          final speedCompare = b['speed'].compareTo(a['speed']);
          if (speedCompare != 0) return speedCompare;
          return a['ping'].compareTo(b['ping']);
        });

        debugPrint('[API] Found ${servers.length} VPNGate servers');
        return servers;
      }
      throw Exception('Failed to fetch VPNGate servers');
    } catch (e) {
      debugPrint('[API] VPNGate error: $e');
      throw Exception('Failed to get VPN servers: $e');
    }
  }

  Future<String> getProtonVPNConfig() async {
    // Это тестовый конфиг ProtonVPN Free для Нидерландов
    return '''
client
dev tun
proto udp

remote nl-free-1.protonvpn.net 80
remote nl-free-1.protonvpn.net 443
remote nl-free-1.protonvpn.net 4569
remote nl-free-1.protonvpn.net 1194

remote-random
resolv-retry infinite
nobind
cipher AES-256-CBC
auth SHA512
comp-lzo no
verb 3

setenv CLIENT_CERT 0
tun-mtu 1500
mssfix 1450
persist-key
persist-tun

reneg-sec 0

remote-cert-tls server
auth-user-pass
pull
fast-io

<ca>
-----BEGIN CERTIFICATE-----
MIIFozCCA4ugAwIBAgIBATANBgkqhkiG9w0BAQ0FADBAMQswCQYDVQQGEwJDSDEV
MBMGA1UEChMMUHJvdG9uVlBOIEFHMRowGAYDVQQDExFQcm90b25WUE4gUm9vdCBD
QTAeFw0xNzAyMTUxNDM4MDBaFw0yNzAyMTUxNDM4MDBaMEAxCzAJBgNVBAYTAkNI
MRUwEwYDVQQKEwxQcm90b25WUE4gQUcxGjAYBgNVBAMTEVByb3RvblZQTiBSb290
IENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAt+BsSsZg7+AuqTq7
vDbPzfygtl9f8fLJqO4amsyOXlI7pquL5IsEZhpWyJIIvYybqS4s1/T7BbvHPLVE
wlrq8A5DBIXcfuXrBbKoYkmpICGc2u1KYVGOZ9A+PH9z4Tr6OXFfXRnsbZToql7M
ZkXJ5XZaOXgF5BUq0O9xJ84aUHrPMGByDB7FXUCWFhp/cpDGFqhwPjKxg0Dv7Bpg
hQWQQAFzMj7NkGBv4RfBU2aJ6IYQPLy4l0BNnCHhxTQ2Y0lC8BXCkrpNg3+As7vp
MhX/A1/3FwEmt/gyA0HiZjbIhi5ZMpaDWwBwmLzKwPkwmJ2+KsYFNqGqF5GfjRwn
p/FynYsBzMJVRovMR9/uvP2jGhqZsoVGqFA0JaM/T5pYvqPGWO7C1CXDyB4gICMu
k9DOALa2mz9YUWaJFpVvqRe2yhLKOGlB/TBwVIpIB7HDR1JMZ4VoWpHJQGgd0LBO
g9tkKLHdRFe9+3EOqRHnYG4rvv/kBvfZiJA1toQKltKaQ8TGtFcXL9yGT7C1pXbQ
DxHbtGPIoYlAuEXDStDXmyRFuLAnq/1UwZQWxm3qj5aCgbESeKJoI8CZJULGYlfJ
qb9H8jZSDNcI2m0eX3wY+/9tC/rU9oqLA3ivgGgH9qC5A2SeFZQZNHdPtKEI+ZoQ
+daSYmKOgZQB6rqC3ZiHGmrLAgMBAAGjgYAwfjAdBgNVHQ4EFgQUBxHd8P0oKDPd
z0YwHqf8MAJxsqAwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBQHEd3w/Sgo
M93PRjAep/wwAnGyoDATBgNVHSUEDDAKBggrBgEFBQcDAjAOBgNVHQ8BAf8EBAMC
AQYwDQYJKoZIhvcNAQENBQADggIBAA5iYgZK7EUgtP6w/lhk3Edv8qZzPLVoQ9J0
878nqD8/EQjy/TMzXXbPPgRkw5E+WBPJTQv8qHpsoZ4HEPeRj9pE/xvZ7mYZFhKX
b7kMGn3CG9BGCRCQrHQcC5lCPR4f0YkUcZBxF/YyKAXESHhYxUF4dPz/0JlWV6B4
q5HYNzYCXDY9wXbGPxQGYoEQXJ+v2B02/X3hxMrHAZqpkk/sH+YmhLp+jqvMTWqx
/Ddq/VLcGxFIbJBxlpF+2j4muw1RJiuL8v+/JqxVDiWzxX+kqwJMI+HKtmOhCFVV
pqwzMu+FWg9UhGbgR6+uHlFHFKVNw3c/i7JHSHDhUxsXCJWxEOXhgzvhGOxpNcQS
01kkz3KR0hX/dxEkF8OzHsxGxNgV9EDCM9pc6pAi+q1p3ZiZx5ZxxHVZc/qgAZkf
HHWGRhyZjmJ8MQJCG5PCWvQZOXXQHhxZ5IbmXjF+oQtF0mQiJ+wXUnFy3xf4Jg1m
/YE+Yqi5NzjkumydZJto4MQxWcGDa3JKCp71wJo2GvTbUE63XhE3dR5IDG/YDP5z
s9ZKzP5g6xC3yXJwFEkwgZNGQHgHOXhWjZKbhqHHxKknYj7MXZwEHAUGE6AJDQDP
kCTpCxcMr0RHh3APKKLhRkxwlkvWQYgQC0PJFN5KQxPQJvYMtktX7Z5tR2nE4EQI
0zUlYWDN
-----END CERTIFICATE-----
</ca>

key-direction 1
auth-user-pass
''';
  }

  Future<Map<String, dynamic>> getBestVPNGateServer() async {
    try {
      debugPrint('[API] Getting best VPNGate server...');
      final servers = await getVPNGateServers();
      
      // Фильтруем серверы по критериям
      final filteredServers = servers.where((server) {
        final ping = server['ping'] as int;
        final speed = server['speed'] as int; // bytes/sec
        final score = int.tryParse(server['score'] ?? '0') ?? 0;
        
        return ping < 100 && // пинг меньше 100мс
               speed > 5000000 && // скорость больше 5 Мбит/с
               score > 500000 && // высокий рейтинг
               // Предпочитаем серверы из этих стран
               ['JP', 'KR', 'US', 'RU', 'DE', 'FR'].contains(server['countryShort']);
      }).toList();

      if (filteredServers.isEmpty) {
        throw Exception('No suitable VPNGate servers found');
      }

      // Сортируем по скорости и пингу
      filteredServers.sort((a, b) {
        final speedCompare = b['speed'].compareTo(a['speed']);
        if (speedCompare != 0) return speedCompare;
        return a['ping'].compareTo(b['ping']);
      });

      debugPrint('[API] Found ${filteredServers.length} suitable servers');
      debugPrint('[API] Best server: ${filteredServers.first['country']} (${filteredServers.first['hostname']})');
      
      return filteredServers.first;
    } catch (e) {
      debugPrint('[API] Error getting best server: $e');
      throw Exception('Failed to get best VPNGate server: $e');
    }
  }

  Future<Map<String, String>> getVPNBookConfig() async {
    // Актуальный конфиг VPNBook
    return {
      'config': '''
client
dev tun3
proto tcp
remote 147.135.15.16 80
resolv-retry infinite
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
cipher AES-256-CBC
fast-io
pull
route-delay 2
redirect-gateway
<ca>
-----BEGIN CERTIFICATE-----
MIIDSzCCAjOgAwIBAgIUJdJ6+6lTiYZBvpl2P40Lgx3BeHowDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAwwLdnBuYm9vay5jb20wHhcNMjMwMjIwMTk0NTM1WhcNMzMw
MjE3MTk0NTM1WjAWMRQwEgYDVQQDDAt2cG5ib29rLmNvbTCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAMcVK+hYl6Wl57YxXIVy7Jlgglj42LaC2sUWK3ls
... (остальная часть сертификата) ...
-----END CERTIFICATE-----
</ca>
<cert>
-----BEGIN CERTIFICATE-----
MIIDYDCCAkigAwIBAgIQP/z/mAlVNddzohzjQghcqzANBgkqhkiG9w0BAQsFADAW
... (остальная часть сертификата) ...
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDT4jcsmB+si17L
... (остальная часть ключа) ...
-----END PRIVATE KEY-----
</key>
''',
      'username': 'vpnbook',
      'password': 'c28hes5'
    };
  }

  Future<Map<String, String>> getSpyDogConfig() async {
    return {
      'config': '''client
dev tun
proto udp
remote 171.22.127.80 1194
resolv-retry infinite
nobind
persist-key
persist-tun
cipher AES-256-CBC
auth SHA256
compress lz4-v2
verb 3
<ca>
-----BEGIN CERTIFICATE-----
MIIDUTCCAjmgAwIBAgIUGDe1ejr7diRmJpm9pv8Xp7sXNAIwDQYJKoZIhvcNAQEL
BQAwGDEWMBQGA1UEAwwNU3B5RG9nLVZQTi1DQTAeFw0yNDEyMzAxOTAwNDFaFw0z
NDEyMjgxOTAwNDFaMBgxFjAUBgNVBAMMDVNweURvZy1WUE4tQ0EwggEiMA0GCSqG
SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCxORoyAxqSMiadDKWhEP99OhYy2UKMLtf4
QGiQmGnS1/duvSdiqJ4wWoUPg4nJ3yl5+LFGXoEUfikXu/5SthTwCvA4Y911E4Jw
YnUxi0PBMj4/JfMG7A+wvkvC8tyARza/SJKr3Jx5pMHvE0sAf2psDs1ZBNv8zoK9
GJ3JosufzM5lVbseHQb9JNRtsvSkicUOnAOHRPEsojncDBwRaeZFiJOM5rgW9eV/
+Wj8QjC7hyhblnlNv88I01ja/tDkayXoT7aOE2vn2D3LtmnUx73eCRWjDbeAn5rC
ksCnd6xSNH1PShmlPHsevhtrWSPuIhaWpDpn4ljdQMB7T01qNeeNAgMBAAGjgZIw
gY8wHQYDVR0OBBYEFJy+V2iTmiNzJCMq8QScyHLlHgP1MFMGA1UdIwRMMEqAFJy+
V2iTmiNzJCMq8QScyHLlHgP1oRykGjAYMRYwFAYDVQQDDA1TcHlEb2ctVlBOLUNB
ghQYN7V6Ovt2JGYmmb2m/xenuxc0AjAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIB
BjANBgkqhkiG9w0BAQsFAAOCAQEAdC4f6LPxC3vTvd0tjIg3w/WfdkkeVVeWtexW
UOTaxr1qS1v8manWLRFU+GIRQBXgUqFiYC6Gpgxc4ZkuiemVs2zL9svLwd26+yQ0
cTJmc20/28IlEdmxg9E42S3nBBd2WjOm0Fst4AgRxoi0NmRBhb4s0wCW55KNhGog
4SxfEbtA3Nx/eTK6tZ4CDcsiWaRWF2NECEsiS+ivPbKiB2pi4KoxoLKjXAqP+8VM
gkyhZ1/ztYCCStAleBjOsMC0nB2QUBrwSJqL1rUl1OvZvMDnldnZBL9/7NBUSeIa
al3I//ViZHyqoafORKJJXT2LKXCYd3+dB5c1NsiYu4TKXrWcAw==
-----END CERTIFICATE-----
</ca>
<cert>
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            78:ff:37:55:b0:ff:49:e6:11:24:cc:84:6c:62:ce:23
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=SpyDog-VPN-CA
        Validity
            Not Before: Dec 30 19:17:54 2024 GMT
            Not After : Apr  4 19:17:54 2027 GMT
        Subject: CN=spydog-client
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:cc:c1:88:f6:87:74:0b:14:61:af:fe:c0:33:eb:
                    11:db:4b:7b:be:c2:91:98:38:e1:ef:8c:90:fc:4f:
                    ae:5d:56:01:79:8c:d7:bd:c1:35:43:e1:3d:27:c2:
                    77:27:32:27:d0:d0:ac:4d:f6:ce:af:46:0b:ca:7c:
                    38:4d:e7:2e:8b:93:59:c5:72:b7:10:51:fb:70:
                    ba:af:cd:c7:68:7d:08:f7:a9:54:34:0d:a4:4a:5e:
                    00:22:12:36:d5:21:aa:c9:99:f1:b5:c7:3b:55:3d:
                    e6:89:85:6a:a9:06:ed:43:2d:b4:6e:67:ff:82:cb:
                    94:ed:45:cc:e1:00:3a:9d:36:60:d6:45:48:ed:66:
                    fd:92:9f:79:70:58:f0:03:48:cc:a6:d7:ec:42:60:
                    e8:18:3e:e2:45:ae:2d:87:a1:e9:b2:a9:f8:4f:5d:
                    e9:8f:26:bb:17:53:38:97:00:12:15:64:ed:6d:69:
                    b6:7b:99:4b:22:04:72:b3:07:de:db:a7:1b:af:05:
                    c0:8e:95:61:25:43:9e:fb:2a:60:c1:5e:cb:1e:
                    57:57:93:90:2c:6f:b3:02:b7:b2:c4:a1:40:87:f2:
                    31:64:8c:cb:53:01:c5:83:e3:e3:da:18:ad:b0:e3:
                    ef:4c:43:eb:8d:ac:73:90:6f:f4:da:46:53:be:08:be:
                    84:aa:f5
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Subject Key Identifier: 
                DE:20:0B:B9:5D:14:61:A6:A1:BD:69:AD:BB:6F:F9:8E:A2:F5:28:E0
            X509v3 Authority Key Identifier: 
                keyid:9C:BE:57:68:93:9A:23:73:24:23:2A:F1:04:9C:C8:72:E5:1E:03:F5
                DirName:/CN=SpyDog-VPN-CA
                serial:18:37:B5:7A:3A:FB:76:24:66:26:99:BD:A6:FF:17:A7:BB:17:34:02
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
            X509v3 Key Usage: 
                Digital Signature
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        50:6e:7d:11:31:9e:2d:e0:71:ad:ab:da:52:a3:dc:f7:3d:52:
        39:36:1f:de:60:0e:cf:63:10:13:9b:9e:1c:e7:84:0e:89:0d:
        e1:ae:0d:21:1e:42:d8:88:22:64:56:d0:7d:73:45:6f:c6:1d:
        29:2a:97:13:f4:0d:de:06:36:18:4e:ce:a7:07:8f:a4:5f:3f:
        af:6b:4d:bb:03:f3:c1:48:10:c8:24:2f:59:ee:cf:2d:52:2c:
        38:bc:19:02:40:d8:4a:e2:4a:04:f0:e9:2e:60:a8:fa:2e:6a:
        9c:20:05:fb:81:07:dc:f4:7b:98:b5:5f:ae:f1:82:93:07:5d:
        da:6d:01:41:aa:be:0c:7e:7d:b4:d1:9c:02:7f:46:33:9c:61:
        59:a4:82:86:b0:3e:f8:08:45:1a:a5:bc:dd:ad:25:1b:0d:41:
        11:59:1f:fb:2b:97:53:65:3d:01:cf:7e:52:34:71:01:15:d7:
        e7:79:e1:f2:1b:29:2b:74:57:3b:03:5b:6f:80:5c:37:c0:86:
        c4:56:b3:78:0e:16:e0:93:6a:dd:c3:75:e1:93:09:4b:bb:da:
        ed:2c:79:28:64:e8:88:b3:ec:4a:9a:f8:28:29:92:c3:7f:2b:
        7d:56:48:47:93:d7:e1:76:c6:01:df:0a:e8:22:0e:3f:cd:5a:
        fb:bf:ad:c9
-----BEGIN CERTIFICATE-----
MIIDXzCCAkegAwIBAgIQeP83VbD/SeYRJMyEbGLOIzANBgkqhkiG9w0BAQsFADAY
MRYwFAYDVQQDDA1TcHlEb2ctVlBOLUNBMB4XDTI0MTIzMDE5MTc1NFoXDTI3MDQw
NDE5MTc1NFowGDEWMBQGA1UEAwwNc3B5ZG9nLWNsaWVudDCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAMzBiPaHdAsUYa/+wDPrEdtLe77CkZg44e+MkPxP
rl1WAXmM173BNUPhPSfCdycyJ9DQrE32zq9GC8p8OE3nLouTWcVytxBR+3C6r83H
aH0I96lUNA2kSl4AIhI21SGqyZnxtcc7VT3miYVqqQbtQy20bmf/gsuU7UXM4QA6
nTZg1kVI7Wb9kp95cFjwA0jMptfsQmDoGD7iRa4th6Hpsqn4T13pjya7F1M4lwAS
FWTtbWm2e5lLIgRyswfe26cbrwXAjpVhJUOe+ypgwV7LHldXk5Asb7MCt7LEoUCH
8jFkjMtTAcWD4+PaGK2w4+9MQ+uNrHOQb/TaRlO+CL6EqvUCAwEAAaOBpDCBoTAJ
BgNVHRMEAjAAMB0GA1UdDgQWBBTeIAu5XRRhpqG9aa27b/mOovUo4DBTBgNVHSME
TDBKgBScvldok5ojcyQjKvEEnMhy5R4D9aEcpBowGDEWMBQGA1UEAwwNU3B5RG9n
LVZQTi1DQYIUGDe1ejr7diRmJpm9pv8Xp7sXNAIwEwYDVR0lBAwwCgYIKwYBBQUH
AwIwCwYDVR0PBAQDAgeAMA0GCSqGSIb3DQEBCwUAA4IBAQBQbn0RMZ4t4HGtq9pS
o9z3PVI5Nh/eYA7PYxATm54c54QOiQ3hrg0hHkLYiCJkVtB9c0Vvxh0pKpcT9A3e
BjYYTs6nB4+kXz+va027A/PBSBDIJC9Z7s8tUiw4vBkCQNhK4koE8OkuYKj6Lmqc
IAX7gQfc9HuYtV+u8YKTB13abQFBqr4Mfn200ZwCf0YznGFZpIKGsD74CEUapbzd
rSUbDUERWR/7K5dTZT0Bz35SNHEBFdfneeHyGykrdFc7A1tvgFw3wIbEVrN4Dhbg
k2rdw3XhkwlLu9rtLHkoZOiIs+xKmvgoKZLDfyt9VkhHk9fhdsYB3wroIg4/zVr7
v63J
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDMwYj2h3QLFGGv
/sAz6xHbS3u+wpGYOOHvjJD8T65dVgF5jNe9wTVD4T0nwncnMifQ0KxN9s6vRgvK
fDhN5y6Lk1nFcrcQUftwuq/Nx2h9CPepVDQNpEpeACISNtUhqsmZ8bXHO1U95omF
aqkG7UMttG5n/4LLlO1FzOEAOp02YNZFSO1m/ZKfeXBY8ANIzKbX7EJg6Bg+4kWu
LYeh6bKp+E9d6Y8muxdTOJcAEhVk7W1ptnuZSyIEcrMH3tunG68FwI6VYSVDnvsq
YMFeyx5XV5OQLG+zAreyxKFAh/IxZIzLUwHFg+Pj2hitsOPvTEPrjaxzkG/02kZT
vgi+hKr1AgMBAAECggEAAj9EgMojRqTaXptZ4if8Ce9V5BXQEb7cEew1wiMgu4MA
YKRgUMOQUValPGy4sIwvHi5QGcnx4kAPTJFY79fv7ZW4KD/WTP5NV2MhH03HMooY
57mWGak6LLZtKUyDQcuVS1R5BX779EI1s6pkQQB1GokOpiMKfS/8+6VgOceq5ogc
A1Kp0OXWBex/cH3ONdTkZwiXKEY1vKk4ZKm7RovRXRa3/J9ufN22TNRjnZT0kKry
m/QcYeRFFo8DO+NbZpGdpNo0z0DWh1cQvz0CabslyPixabXeGONoZlk0eJ9/ymtu
jY9VNF62DHhUdNhLhWG0OUXk9ut5zPDsXDdcv5zFuQKBgQDiZYtg672M8CR6Wd7M
lU+zsbZZC/xm4xPJxW7raJtTzaOD4e653RZ5LaO1gCtme/2CAMDl8rMGOLF61/y/
f5NBmWDbpBDml0pwbwvXNp4VxuGcVO6ZKmxskz9c8ubrT2qzxnoBbdeHvT+MlZDQ
RomeE9yQ4iZ3GI0YbgvevgdnjQKBgQDnh5X90nyllM7TTCCJI2Pznt9Dsjh6293F
ASuLqdWnl4ToMVpy8jEmRhTbGm/XLLyRTorddT6C5cpeksxieeyLgqwqXswYhpGN
YdBeA6wBIu6qeYSOz/LSGx+JPHdTQf8yRTjUUDqU20eNuQDkWN0gd6N/eLLFA406
ThTEqTDjCQKBgBJOKZXdmcbyh9CIwbYDAJ3D6b2LdY4QIEJ5Pz2ziJOfFfCM7ROE
J9QGd60uPtQbhGTlkLNHC2ieXuNS4XHOa+aq8yTvQBqU8wTiRa/SD7gtC4Lrbxtd
TcT9purqDPfLxRHiI21IJ1wnViMU2M+uVGQ+sN/aGUgZ6RanlzgcX1blAoGAZXc9
G4SQTbx+O4mERLV2y0BX1gIX0Hfko76Uh9uBH7Y+b8eZPQC4224hG7hlRSZ86S1D
nDQSlikAXBv3aDzIlodIzjTHOwRWa2BvgZQYYFMfxyQEHNYzMzLhyjHulVU58pz1
f849Lhk/LXPjWS88kUr9IxMRPVgGH4Qyg9El9IkCgYBidSsxVW2WAzJclFT5X5AD
NwRbFwNv1w4uACPxsp6s6aNQGtUbcVREPKX00SrLzrnMakUbmt+39oVImLA1MTi5
L3BcPSJgaVVKw48qXzYSFTEm+wUN7AJAkxSJNpSf0gEbqUxvc4VgWyWTJm8Jr6Ji
yBw/rzY1vldZSSyFhZhctw==
-----END PRIVATE KEY-----
</key>'''
    };
  }
}