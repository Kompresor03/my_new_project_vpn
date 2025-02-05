enum VpnConnectionState {
  DISCONNECTED,
  CONNECTING,
  CONNECTED,
  DISCONNECTING,
  ERROR
}

class VpnConnectionDetails {
  final VpnConnectionState state;
  final DateTime timestamp;
  final String? serverAddress;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  VpnConnectionDetails({
    required this.state,
    required this.timestamp,
    this.serverAddress,
    this.errorCode,
    this.errorMessage,
    this.metadata,
  });

  factory VpnConnectionDetails.fromJson(Map<String, dynamic> json) {
    return VpnConnectionDetails(
      state: VpnConnectionState.values.firstWhere(
        (e) => e.toString() == json['state'],
        orElse: () => VpnConnectionState.DISCONNECTED,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      serverAddress: json['serverAddress'],
      errorCode: json['errorCode'],
      errorMessage: json['errorMessage'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state.toString(),
      'timestamp': timestamp.toIso8601String(),
      'serverAddress': serverAddress,
      'errorCode': errorCode,
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }
}

class VpnErrorCodes {
  static const String SERVER_UNREACHABLE = 'SERVER_UNREACHABLE';
  static const String INVALID_CONFIG = 'INVALID_CONFIG';
  static const String AUTH_FAILED = 'AUTH_FAILED';
  static const String PERMISSION_DENIED = 'PERMISSION_DENIED';
  static const String NETWORK_ERROR = 'NETWORK_ERROR';
  static const String UNKNOWN_ERROR = 'UNKNOWN_ERROR';
}
