import 'package:flutter/material.dart';
import 'dart:math';  // Используется для Random в selectRandomLocation
import '../models/location.dart';
import '../services/api_service.dart';
import '../services/vpn_service.dart';

enum SelectionMode {
  auto,
  manual,
  none
}

class CountresScreen extends StatefulWidget {
  final bool isAutoMode;
  final String selectedCountry;
  final VpnLocation? currentLocation;

  const CountresScreen({
    Key? key,
    required this.isAutoMode,
    required this.selectedCountry,
    this.currentLocation,
  }) : super(key: key);

  @override
  _CountresScreenState createState() => _CountresScreenState();
}

class _CountresScreenState extends State<CountresScreen> {
  bool isDarkTheme = false;
  List<VpnLocation> locations = [];
  bool isLoading = true;
  final ApiService apiService = ApiService();
  String? currentSelection;
  SelectionMode selectionMode = SelectionMode.auto;
  bool _isAutoMode = false;

  @override
  void initState() {
    super.initState();
    _isAutoMode = widget.isAutoMode;
    _loadLocations();
    
    selectionMode = widget.currentLocation == null ? SelectionMode.auto : SelectionMode.manual;
  }

  Future<void> _loadLocations() async {
    try {
      final loadedLocations = await apiService.getLocations();
      setState(() {
        locations = loadedLocations;
        isLoading = false;
        
        if (widget.currentLocation != null) {
          for (var loc in locations) {
            loc.isSelected = loc.id == widget.currentLocation!.id;
          }
        }
        else {
          selectionMode = SelectionMode.auto;
        }
      });
    } catch (e) {
      debugPrint('Error loading locations: $e');
      setState(() => isLoading = false);
    }
  }

  void _onAutoModeChanged(bool? value) {
    if (value != null) {
      setState(() {
        _isAutoMode = value;
      });
      
      Navigator.pop(context, {
        'isAutoMode': value,
        'country': value ? 'Auto' : widget.selectedCountry,
        'location': value ? null : widget.currentLocation,
      });
    }
  }

  void _onLocationSelected(VpnLocation location) {
    Navigator.pop(context, {
      'isAutoMode': false,
      'country': location.country,
      'location': location,
    });
  }

  void _handleAutoSelection(bool? value) {
    if (value == true) {
      setState(() {
        selectionMode = SelectionMode.auto;
        for (var loc in locations) {
          loc.isSelected = false;
        }
      });
      
      Navigator.pop(context, {
        'isAutoMode': true,
        'country': 'Auto',
        'location': null,
      });
    }
  }

  void _handleLocationSelection(VpnLocation location) {
    if (location.isPremium) {
      _showPremiumDialog();
      return;
    }

    setState(() {
      selectionMode = SelectionMode.manual;
      
      for (var loc in locations) {
        loc.isSelected = false;
      }
      location.isSelected = true;
    });

    Navigator.pop(context, {
      'isAutoMode': false,
      'country': location.country,
      'location': location,
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String?> getVpnConfig(int locationId) async {
    try {
      final config = await apiService.getVpnConfig(locationId);
      return config;
    } catch (e) {
      debugPrint('[ERROR] Error fetching VPN config: $e');
      return null;
    }
  }

  void selectRandomLocation() {
    if (locations.isEmpty) return;

    final freeLocations = locations.where((loc) => !loc.isPremium).toList();
    if (freeLocations.isEmpty) return;

    final random = Random();
    final randomIndex = random.nextInt(freeLocations.length);

    setState(() {
      for (var loc in locations) {
        loc.isSelected = false;
      }

      if (currentSelection == 'auto') {
        freeLocations[randomIndex].isSelected = true;
      }
    });
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Premium Location'),
          content: Text('This is a premium location. Please upgrade to access it.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Upgrade'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAutoSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkTheme ? Color(0xFF0C1630) : Color(0xFFECF3FB),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Text(
            'Auto select',
            style: TextStyle(
              color: Color(0xFF5F719F),
              fontSize: 14,
              fontFamily: 'Montserrat',
            ),
          ),
          Spacer(),
          Image.asset(
            selectionMode == SelectionMode.auto
                ? (isDarkTheme ? 'assets/images/galka.png' : 'assets/images/galka1.png')
                : (isDarkTheme ? 'assets/images/chekbox.png' : 'assets/images/chekbox1.png'),
            width: 24,
            height: 24,
          ),
        ],
      ),
    ).asButton(
      onTap: () => _handleAutoSelection(true),
    );
  }

  Widget _buildLocationItem(VpnLocation location) {
    return Container(
      width: 370,
      height: 55,
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDarkTheme ? Color(0xFF0C1630) : Color(0xFFECF3FB),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          SizedBox(width: 15),
          Container(
            width: 40,
            height: 40,
            child: ClipOval(
              child: Image.network(
                '${ApiService.baseUrl}/${location.flagUrl}',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.flag),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              location.country,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: isDarkTheme ? Colors.white : Color(0xFF101B36),
              ),
            ),
          ),
          if (location.isPremium)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Image.asset(
                'assets/images/lapa.png',
                width: 20,
                height: 20,
              ),
            ),
          Image.asset(
            location.isSelected && selectionMode == SelectionMode.manual
                ? (isDarkTheme ? 'assets/images/galka.png' : 'assets/images/galka1.png')
                : (isDarkTheme ? 'assets/images/chekbox.png' : 'assets/images/chekbox1.png'),
            width: 24,
            height: 24,
          ),
          SizedBox(width: 15),
        ],
      ),
    ).asButton(
      onTap: () => _handleLocationSelection(location),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Кнопка "Назад"
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDarkTheme ? Color(0xFF0C1630) : Color(0xFFECF3FB),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(7),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                  color: Color(0xFF5F719F),
                ),
              ),
            ),
          ),
        ),
        // Заголовок
        Text(
          'Select Location',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkTheme ? Colors.white : Color(0xFF101B36),
          ),
        ),
        // Пустой контейнер для симметрии
        SizedBox(width: 40),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkTheme ? Color(0xFF101B36) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 20),
              _buildAutoSelector(),
              SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: locations.length,
                        itemBuilder: (context, index) => _buildLocationItem(locations[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension ButtonWidget on Widget {
  Widget asButton({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: this,
      ),
    );
  }
}