// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ObdStore on _ObdStore, Store {
  late final _$isConnectedAtom = Atom(
    name: '_ObdStore.isConnected',
    context: context,
  );

  @override
  bool get isConnected {
    _$isConnectedAtom.reportRead();
    return super.isConnected;
  }

  @override
  set isConnected(bool value) {
    _$isConnectedAtom.reportWrite(value, super.isConnected, () {
      super.isConnected = value;
    });
  }

  late final _$isInitializedAtom = Atom(
    name: '_ObdStore.isInitialized',
    context: context,
  );

  @override
  bool get isInitialized {
    _$isInitializedAtom.reportRead();
    return super.isInitialized;
  }

  @override
  set isInitialized(bool value) {
    _$isInitializedAtom.reportWrite(value, super.isInitialized, () {
      super.isInitialized = value;
    });
  }

  late final _$isMonitoringAtom = Atom(
    name: '_ObdStore.isMonitoring',
    context: context,
  );

  @override
  bool get isMonitoring {
    _$isMonitoringAtom.reportRead();
    return super.isMonitoring;
  }

  @override
  set isMonitoring(bool value) {
    _$isMonitoringAtom.reportWrite(value, super.isMonitoring, () {
      super.isMonitoring = value;
    });
  }

  late final _$selectedConnectionTypeAtom = Atom(
    name: '_ObdStore.selectedConnectionType',
    context: context,
  );

  @override
  ConnectionType get selectedConnectionType {
    _$selectedConnectionTypeAtom.reportRead();
    return super.selectedConnectionType;
  }

  @override
  set selectedConnectionType(ConnectionType value) {
    _$selectedConnectionTypeAtom.reportWrite(
      value,
      super.selectedConnectionType,
      () {
        super.selectedConnectionType = value;
      },
    );
  }

  late final _$addressAtom = Atom(name: '_ObdStore.address', context: context);

  @override
  String get address {
    _$addressAtom.reportRead();
    return super.address;
  }

  @override
  set address(String value) {
    _$addressAtom.reportWrite(value, super.address, () {
      super.address = value;
    });
  }

  late final _$portAtom = Atom(name: '_ObdStore.port', context: context);

  @override
  String get port {
    _$portAtom.reportRead();
    return super.port;
  }

  @override
  set port(String value) {
    _$portAtom.reportWrite(value, super.port, () {
      super.port = value;
    });
  }

  late final _$rpmAtom = Atom(name: '_ObdStore.rpm', context: context);

  @override
  double? get rpm {
    _$rpmAtom.reportRead();
    return super.rpm;
  }

  @override
  set rpm(double? value) {
    _$rpmAtom.reportWrite(value, super.rpm, () {
      super.rpm = value;
    });
  }

  late final _$speedKmhAtom = Atom(
    name: '_ObdStore.speedKmh',
    context: context,
  );

  @override
  double? get speedKmh {
    _$speedKmhAtom.reportRead();
    return super.speedKmh;
  }

  @override
  set speedKmh(double? value) {
    _$speedKmhAtom.reportWrite(value, super.speedKmh, () {
      super.speedKmh = value;
    });
  }

  late final _$coolantTempCAtom = Atom(
    name: '_ObdStore.coolantTempC',
    context: context,
  );

  @override
  double? get coolantTempC {
    _$coolantTempCAtom.reportRead();
    return super.coolantTempC;
  }

  @override
  set coolantTempC(double? value) {
    _$coolantTempCAtom.reportWrite(value, super.coolantTempC, () {
      super.coolantTempC = value;
    });
  }

  late final _$throttlePercentAtom = Atom(
    name: '_ObdStore.throttlePercent',
    context: context,
  );

  @override
  double? get throttlePercent {
    _$throttlePercentAtom.reportRead();
    return super.throttlePercent;
  }

  @override
  set throttlePercent(double? value) {
    _$throttlePercentAtom.reportWrite(value, super.throttlePercent, () {
      super.throttlePercent = value;
    });
  }

  late final _$batteryVoltageAtom = Atom(
    name: '_ObdStore.batteryVoltage',
    context: context,
  );

  @override
  double? get batteryVoltage {
    _$batteryVoltageAtom.reportRead();
    return super.batteryVoltage;
  }

  @override
  set batteryVoltage(double? value) {
    _$batteryVoltageAtom.reportWrite(value, super.batteryVoltage, () {
      super.batteryVoltage = value;
    });
  }

  late final _$engineLoadPercentAtom = Atom(
    name: '_ObdStore.engineLoadPercent',
    context: context,
  );

  @override
  double? get engineLoadPercent {
    _$engineLoadPercentAtom.reportRead();
    return super.engineLoadPercent;
  }

  @override
  set engineLoadPercent(double? value) {
    _$engineLoadPercentAtom.reportWrite(value, super.engineLoadPercent, () {
      super.engineLoadPercent = value;
    });
  }

  late final _$responsesAtom = Atom(
    name: '_ObdStore.responses',
    context: context,
  );

  @override
  ObservableList<ObdResponse> get responses {
    _$responsesAtom.reportRead();
    return super.responses;
  }

  @override
  set responses(ObservableList<ObdResponse> value) {
    _$responsesAtom.reportWrite(value, super.responses, () {
      super.responses = value;
    });
  }

  late final _$connectAsyncAction = AsyncAction(
    '_ObdStore.connect',
    context: context,
  );

  @override
  Future<void> connect() {
    return _$connectAsyncAction.run(() => super.connect());
  }

  late final _$disconnectAsyncAction = AsyncAction(
    '_ObdStore.disconnect',
    context: context,
  );

  @override
  Future<void> disconnect() {
    return _$disconnectAsyncAction.run(() => super.disconnect());
  }

  late final _$initializeAndStartMonitoringAsyncAction = AsyncAction(
    '_ObdStore.initializeAndStartMonitoring',
    context: context,
  );

  @override
  Future<void> initializeAndStartMonitoring() {
    return _$initializeAndStartMonitoringAsyncAction.run(
      () => super.initializeAndStartMonitoring(),
    );
  }

  late final _$singleBatchQueryAsyncAction = AsyncAction(
    '_ObdStore.singleBatchQuery',
    context: context,
  );

  @override
  Future<void> singleBatchQuery() {
    return _$singleBatchQueryAsyncAction.run(() => super.singleBatchQuery());
  }

  late final _$sendCommandAsyncAction = AsyncAction(
    '_ObdStore.sendCommand',
    context: context,
  );

  @override
  Future<void> sendCommand(String commandCode) {
    return _$sendCommandAsyncAction.run(() => super.sendCommand(commandCode));
  }

  late final _$_ObdStoreActionController = ActionController(
    name: '_ObdStore',
    context: context,
  );

  @override
  void setConnectionType(ConnectionType type) {
    final _$actionInfo = _$_ObdStoreActionController.startAction(
      name: '_ObdStore.setConnectionType',
    );
    try {
      return super.setConnectionType(type);
    } finally {
      _$_ObdStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAddress(String value) {
    final _$actionInfo = _$_ObdStoreActionController.startAction(
      name: '_ObdStore.setAddress',
    );
    try {
      return super.setAddress(value);
    } finally {
      _$_ObdStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPort(String value) {
    final _$actionInfo = _$_ObdStoreActionController.startAction(
      name: '_ObdStore.setPort',
    );
    try {
      return super.setPort(value);
    } finally {
      _$_ObdStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void stopMonitoring() {
    final _$actionInfo = _$_ObdStoreActionController.startAction(
      name: '_ObdStore.stopMonitoring',
    );
    try {
      return super.stopMonitoring();
    } finally {
      _$_ObdStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearResponses() {
    final _$actionInfo = _$_ObdStoreActionController.startAction(
      name: '_ObdStore.clearResponses',
    );
    try {
      return super.clearResponses();
    } finally {
      _$_ObdStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isConnected: ${isConnected},
isInitialized: ${isInitialized},
isMonitoring: ${isMonitoring},
selectedConnectionType: ${selectedConnectionType},
address: ${address},
port: ${port},
rpm: ${rpm},
speedKmh: ${speedKmh},
coolantTempC: ${coolantTempC},
throttlePercent: ${throttlePercent},
batteryVoltage: ${batteryVoltage},
engineLoadPercent: ${engineLoadPercent},
responses: ${responses}
    ''';
  }
}
