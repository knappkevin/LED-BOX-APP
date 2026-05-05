import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ble_manager.dart';
import 'models/command.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BleProvider(),
      child: MaterialApp(
        title: 'BLE Remote',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class BleProvider extends ChangeNotifier {
  final BleManager _bleManager = BleManager();
  List<Command> _commands = List.from(defaultCommands);
  static const String _commandsKey = 'custom_commands';

  List<Command> get commands => _commands;

  BluetoothDevice? get connectedDevice => _bleManager.connectedDevice;
  bool get isConnected => _bleManager.isConnected;

  Stream<BluetoothConnectionState> get connectionState =>
      _bleManager.connectionState;

  Future<void> init() async {
    await _bleManager.init();
    await _bleManager.reconnectLast();
    await _loadCommands();
    notifyListeners();
  }

  Future<void> _loadCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_commandsKey);
      if (jsonStr != null) {
        _commands = commandsFromJson(jsonStr);
      }
    } catch (e) {
      debugPrint('Error loading commands: $e');
    }
  }

  Future<void> _saveCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_commandsKey, commandsToJson(_commands));
    } catch (e) {
      debugPrint('Error saving commands: $e');
    }
  }

  void addCommand(Command command) {
    _commands.add(command);
    _saveCommands();
    notifyListeners();
  }

  void updateCommand(int index, Command command) {
    if (index >= 0 && index < _commands.length) {
      _commands[index] = command;
      _saveCommands();
      notifyListeners();
    }
  }

  void deleteCommand(int index) {
    if (index >= 0 && index < _commands.length) {
      _commands.removeAt(index);
      _saveCommands();
      notifyListeners();
    }
  }

  Future<List<BluetoothDevice>> scanDevices() async {
    return await _bleManager.scanDevices();
  }

  Future<bool> connect(BluetoothDevice device) async {
    final result = await _bleManager.connect(device);
    notifyListeners();
    return result;
  }

  Future<void> disconnect() async {
    await _bleManager.disconnect();
    notifyListeners();
  }

  Future<bool> sendCommand(String command) async {
    return await _bleManager.sendCommand(command);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _customCommandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BleProvider>().init();
    });
  }

  @override
  void dispose() {
    _customCommandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Remote'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildConnectionSection(),
          const Divider(height: 1),
          Expanded(child: _buildCommandList()),
          _buildCustomCommandSection(),
        ],
      ),
    );
  }

  Widget _buildConnectionSection() {
    return Consumer<BleProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    provider.isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: provider.isConnected ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.isConnected
                              ? provider.connectedDevice?.platformName ??
                                    'Unknown Device'
                              : 'Not Connected',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (provider.isConnected)
                          Text(
                            provider.connectedDevice?.remoteId.str ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (provider.isConnected)
                    TextButton(
                      onPressed: () => provider.disconnect(),
                      child: const Text('Disconnect'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _showScanDialog(context),
                      icon: const Icon(Icons.search),
                      label: const Text('Scan'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommandList() {
    return Consumer<BleProvider>(
      builder: (context, provider, _) {
        if (!provider.isConnected) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bluetooth_disabled,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect to a device to send commands',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final commands = provider.commands;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Commands',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showCommandDialog(context, provider),
                    tooltip: 'Add Command',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: commands.length,
                itemBuilder: (context, index) {
                  final command = commands[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 0,
                    ),
                    child: ListTile(
                      title: Text(command.name),
                      subtitle: Text(
                        command.value,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showCommandDialog(
                              context,
                              provider,
                              index: index,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () =>
                                _deleteCommand(context, provider, index),
                          ),
                          const Icon(Icons.send),
                        ],
                      ),
                      onTap: () =>
                          _sendCommand(context, provider, command.value),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomCommandSection() {
    return Consumer<BleProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Custom Command',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customCommandController,
                      enabled: provider.isConnected,
                      decoration: InputDecoration(
                        hintText: provider.isConnected
                            ? 'Enter custom command...'
                            : 'Connect to device first',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _sendCommand(context, provider, value);
                          _customCommandController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: provider.isConnected
                        ? () {
                            final text = _customCommandController.text.trim();
                            if (text.isNotEmpty) {
                              _sendCommand(context, provider, text);
                              _customCommandController.clear();
                            }
                          }
                        : null,
                    child: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendCommand(
    BuildContext context,
    BleProvider provider,
    String command,
  ) async {
    final success = await provider.sendCommand(command);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Sent: $command' : 'Failed to send command'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showCommandDialog(
    BuildContext context,
    BleProvider provider, {
    int? index,
  }) {
    final isEditing = index != null;
    final nameController = TextEditingController(
      text: isEditing ? provider.commands[index].name : '',
    );
    final valueController = TextEditingController(
      text: isEditing ? provider.commands[index].value : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Command' : 'Add Command'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., My Animation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Command Value',
                hintText: 'e.g., my_animation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final value = valueController.text.trim();
              if (name.isNotEmpty && value.isNotEmpty) {
                final command = Command(name: name, value: value);
                if (isEditing) {
                  provider.updateCommand(index, command);
                } else {
                  provider.addCommand(command);
                }
                Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deleteCommand(BuildContext context, BleProvider provider, int index) {
    final command = provider.commands[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Command'),
        content: Text('Delete "${command.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteCommand(index);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showScanDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ScanDevicesSheet(),
    );
  }
}

class ScanDevicesSheet extends StatefulWidget {
  const ScanDevicesSheet({super.key});

  @override
  State<ScanDevicesSheet> createState() => _ScanDevicesSheetState();
}

class _ScanDevicesSheetState extends State<ScanDevicesSheet> {
  List<BluetoothDevice> _devices = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _scanning = true);
    final devices = await context.read<BleProvider>().scanDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _scanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Available Devices',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_scanning)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _startScan,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: _scanning
                          ? const Text('Scanning...')
                          : const Text('No devices found'),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final name = device.platformName.isNotEmpty
                            ? device.platformName
                            : 'Unknown Device';
                        return ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(name),
                          subtitle: Text(device.remoteId.str),
                          onTap: () => _connectDevice(context, device),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _connectDevice(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    final provider = context.read<BleProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.connect(device);

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.pop(context);

      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
