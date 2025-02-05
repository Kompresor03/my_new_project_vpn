import 'package:flutter/material.dart';
import 'dart:math';
import 'main_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'language.dart';
import 'countres.dart';
import 'dart:async';
import '../models/location.dart';
import 'vpn_test_screen.dart';
import '../services/vpn_service.dart';
import '../services/api_service.dart';

class MainScreen2 extends StatefulWidget {
  @override
  _MainScreen2State createState() => _MainScreen2State();
}

class _MainScreen2State extends State<MainScreen2> {
  final VpnService _vpnService = VpnService();
  final ApiService _apiService = ApiService();
  
  bool isDarkTheme = false;
  bool isConnecting = false;
  bool isConnected = false;
  Timer? _trafficTimer;

  String connectionStatus = 'Disconnected';
  double? downloadSpeed;
  double? uploadSpeed;
  int? ping;

  String? selectedCountry;
  String? selectedFlag;
  String? userIpAddress;

  VpnLocation? selectedLocation;
  final String baseUrl = 'http://10.0.2.2/material-admin-master';
  bool isAutoMode = true;

  @override
  void initState() {
    super.initState();
    _initVpnStateListener();
    setState(() {
      selectedCountry = 'Auto';
      isAutoMode = true;
    });
  }

  Future<void> _loadDefaultLocation() async {
    try {
      final locations = await _apiService.getLocations();
      if (locations.isNotEmpty) {
        setState(() {
          if (!isAutoMode) {
            selectedLocation = locations.first;
            selectedCountry = locations.first.country;
          }
        });
      }
    } catch (e) {
      debugPrint('[UI] Error loading default location: $e');
    }
  }

  void _initVpnStateListener() {
    _vpnService.vpnStateStream.listen((state) {
      if (!mounted) return;
      
      debugPrint('[UI] VPN state changed to: $state');
      
      setState(() {
        switch (state) {
          case 'CONNECTED':
            if (!isConnected) {
              isConnected = true;
              isConnecting = false;
              connectionStatus = 'Connected';
              _startTrafficMonitoring();
              debugPrint('[UI] VPN Connected - Starting traffic monitoring');
            }
            break;
            
          case 'DISCONNECTED':
            isConnected = false;
            isConnecting = false;
            connectionStatus = 'Disconnected';
            _stopTrafficMonitoring();
            debugPrint('[UI] VPN Disconnected - Cleared traffic data');
            break;
            
          case 'CONNECTING':
            if (!isConnecting) {
              isConnected = false;
              isConnecting = true;
              connectionStatus = 'Connecting...';
              _stopTrafficMonitoring();
              debugPrint('[UI] VPN Connecting');
            }
            break;
            
          case 'DISCONNECTING':
            isConnected = false;
            isConnecting = true;
            connectionStatus = 'Disconnecting...';
            _stopTrafficMonitoring();
            debugPrint('[UI] VPN Disconnecting');
            break;
        }
      });
    });
  }

  void _stopTrafficMonitoring() {
    _trafficTimer?.cancel();
    _trafficTimer = null;
    setState(() {
      downloadSpeed = null;
      uploadSpeed = null;
      ping = null;
      userIpAddress = null;
    });
  }

  void _startTrafficMonitoring() {
    _stopTrafficMonitoring();
    
    if (!mounted || !isConnected) return;

    _trafficTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted || !isConnected) {
        _stopTrafficMonitoring();
        return;
      }

      final status = _vpnService.getStatus();
      if (status != null) {
        setState(() {
          // Конвертируем байты в килобайты и округляем до 2 знаков
          downloadSpeed = (double.tryParse(status.byteIn ?? '0')! / 1024).roundToDouble();
          uploadSpeed = (double.tryParse(status.byteOut ?? '0')! / 1024).roundToDouble();
          ping = 20 + Random().nextInt(80); // Временно оставим рандомный пинг
          
          // Обновляем IP адрес только если он еще не установлен
          if (userIpAddress == null) {
            userIpAddress = '192.168.${Random().nextInt(255)}.${Random().nextInt(255)}';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _trafficTimer?.cancel();
    _vpnService.dispose();
    super.dispose();
  }

  Future<void> _connectVPN() async {
    if (isConnected) {
      await _vpnService.disconnect();
      return;
    }

    if (isAutoMode) {
      final locations = await _apiService.getLocations();
      if (locations.isEmpty) {
        debugPrint('[VPN] No locations available for Auto mode');
        return;
      }
      selectedLocation = locations.first;
    }

    if (selectedLocation == null) {
      debugPrint('[VPN] No location selected');
      return;
    }

    final config = await _apiService.getVpnConfig(selectedLocation!.id);
    if (config == null) {
      debugPrint('[VPN] Failed to get config for location');
      return;
    }

    await _vpnService.connect(config);
  }

  Widget buildConnectButton() {
    String buttonImagePath;
    
    if (isDarkTheme) {
      buttonImagePath = isConnected
          ? 'assets/images/Buttononndarkonn.png'
          : 'assets/images/Buttononndarkoff.png';
    } else {
      buttonImagePath = isConnected
          ? 'assets/images/Buttononnlightonn.png'
          : 'assets/images/Buttononnlightoff.png';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isConnecting ? null : _connectVPN,
        borderRadius: BorderRadius.circular(85),
        child: Container(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                buttonImagePath,
                width: 170,
                height: 170,
                fit: BoxFit.contain,
              ),
              if (isConnecting)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkTheme ? Colors.white : Colors.blue,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoBlock({
    required double width,
    required double height,
    required Color backgroundColor,
    required String iconPath,
    required String labelText,
    String? valueText,
  }) {
    return Container(
      width: width,
      height: height + 10,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Stack(
        children: [
          if (isConnected && valueText != null)
            Center(
              child: Text(
                valueText,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  color: Color(0xFF5F719F),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    iconPath,
                    width: 12,
                    height: 12,
                  ),
                  SizedBox(width: 3),
                  Text(
                    labelText,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 8,
                      color: Color(0xFF5F719F),
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

  Widget _buildCountryButton() {
    return Container(
      width: 330,
      height: 40,
      decoration: BoxDecoration(
        color: isDarkTheme ? Color(0xFF0C1630) : Color(0xFFECF3FB),
        borderRadius: BorderRadius.circular(7),
      ),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CountresScreen(
                isAutoMode: isAutoMode,
                selectedCountry: selectedCountry ?? 'Auto',
                currentLocation: selectedLocation,
              ),
            ),
          );

          if (result != null) {
            debugPrint('[UI] Location selection result: $result');
            setState(() {
              isAutoMode = result['isAutoMode'] ?? false;
              if (isAutoMode) {
                selectedCountry = 'Auto';
                selectedLocation = null;
              } else {
                selectedCountry = result['country'];
                selectedLocation = result['location'];
              }
              debugPrint('[UI] Updated state - isAutoMode: $isAutoMode, selectedCountry: $selectedCountry');
            });
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              if (!isAutoMode && selectedLocation != null)
                Container(
                  width: 24,
                  height: 24,
                  margin: EdgeInsets.only(right: 10),
                  child: ClipOval(
                    child: Image.network(
                      '${ApiService.baseUrl}/${selectedLocation!.flagUrl}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.flag,
                        color: Color(0xFF5F719F),
                      ),
                    ),
                  ),
                )
              else
                Icon(
                  Icons.location_on,
                  color: Color(0xFF5F719F),
                  size: 24,
                ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedCountry ?? 'Auto',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: Color(0xFF5F719F),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF5F719F),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildIpButton() {
    return Container(
      width: 330,
      height: 40,
      decoration: BoxDecoration(
        color: isDarkTheme ? Color(0xFF0C1630) : Color(0xFFECF3FB),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          SizedBox(width: 15),
          Text(
            'Your IP',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              color: Color(0xFF5F719F),
            ),
          ),
          SizedBox(width: 10),
          if (connectionStatus == 'Connected' && userIpAddress != null)
            Text(
              userIpAddress!,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                color: isDarkTheme ? Colors.white : Color(0xFF101B36),
              ),
            ),
          Spacer(),
          Image.asset(
            'assets/images/arrowcircle.png',
            width: 15,
            height: 15,
          ),
          SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget buildGoPremiumButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      },
      child: Container(
        width: 330,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.asset(
            isDarkTheme
                ? 'assets/images/gopremium.png'
                : 'assets/images/gopremiumdark.png',
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    return Text(
      isConnected ? 'Connected' : 'Disconnected',
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        color: isDarkTheme ? Colors.white : Color(0xFF101B36),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Column(
                children: [
                  Image.asset(
                    isDarkTheme
                        ? 'assets/images/logo.png'
                        : 'assets/images/logolight.png',
                    width: 140,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 3),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDarkTheme ? Color(0xFF101B36) : Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset(
              isDarkTheme
                  ? 'assets/images/iconmenudark.png'
                  : 'assets/images/iconmenulight.png',
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/king.png'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MainScreen()),
              );
            },
          ),
          IconButton(
            icon: Image.asset(
              isDarkTheme ? 'assets/images/moon.png' : 'assets/images/sun.png',
            ),
            onPressed: () {
              setState(() {
                isDarkTheme = !isDarkTheme;
              });
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      backgroundColor: isDarkTheme ? Color(0xFF101B36) : Colors.white,
      drawer: buildDrawer(),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/space.png',
                  width: 220,
                  height: 295,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 20),
                buildConnectButton(),
                SizedBox(height: 16),
                _buildStatusText(),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildInfoBlock(
                      width: 93,
                      height: 40,
                      backgroundColor:
                      isDarkTheme ? Color(0xFF0C1630) : Color(0xFFECF3FB),
                      iconPath: 'assets/images/greeLine.png',
                      labelText: 'Download',
                      valueText: downloadSpeed != null
                          ? '${downloadSpeed!.toStringAsFixed(2)} kb/s'
                          : null,
                    ),
                    buildInfoBlock(
                      width: 93,
                      height: 40,
                      backgroundColor:
                      isDarkTheme ? Color(0xFF0C1630) : Color(0xFFECF3FB),
                      iconPath: 'assets/images/yellowLine.png',
                      labelText: 'Upload',
                      valueText: uploadSpeed != null
                          ? '${uploadSpeed!.toStringAsFixed(2)} kb/s'
                          : null,
                    ),
                    buildInfoBlock(
                      width: 93,
                      height: 40,
                      backgroundColor:
                      isDarkTheme ? Color(0xFF0C1630) : Color(0xFFECF3FB),
                      iconPath: 'assets/images/ping.png',
                      labelText: 'Ping',
                      valueText: ping != null ? '${ping} ms' : null,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Column(
                  children: [
                    _buildCountryButton(),
                    SizedBox(height: 20),
                    buildIpButton(),
                    SizedBox(height: 20),
                    buildGoPremiumButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDrawer() {
    return Drawer(
      child: Container(
        color: isDarkTheme ? Color(0xFF101B36) : Colors.white,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDarkTheme ? Color(0xFF0C1630) : Color(0xFFECF3FB),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.vpn_lock,
                    size: 64,
                    color: isDarkTheme ? Colors.white : Color(0xFF101B36),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.location_on,
                color: isDarkTheme ? Colors.white : Color(0xFF101B36),
              ),
              title: Text(
                'Location',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Color(0xFF101B36),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CountresScreen(
                      isAutoMode: isAutoMode,
                      selectedCountry: selectedCountry ?? 'Auto',
                      currentLocation: selectedLocation,
                    ),
                  ),
                ).then((result) {
                  if (result != null) {
                    setState(() {
                      isAutoMode = result['isAutoMode'] ?? false;
                      if (isAutoMode) {
                        selectedCountry = 'Auto';
                        selectedLocation = null;
                      } else {
                        selectedCountry = result['country'];
                        selectedLocation = result['location'];
                      }
                    });
                  }
                });
              },
            ),
            // Другие пункты меню
          ],
        ),
      ),
    );
  }

  Widget buildMenuItem({
    required String iconPath,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 24,
            height: 24,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: isDarkTheme ? Colors.white : Color(0xFF101B36),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}