class Command {
  final String name;
  final String value;

  const Command({required this.name, required this.value});
}

const List<Command> defaultCommands = [
  Command(name: 'LED On', value: 'LED_ON'),
  Command(name: 'LED Off', value: 'LED_OFF'),
  Command(name: 'Blink', value: 'BLINK'),
  Command(name: 'Pulse', value: 'PULSE'),
  Command(name: 'Rainbow', value: 'RAINBOW'),
  Command(name: 'Clear', value: 'CLEAR'),
  Command(name: 'Pattern 1', value: 'PATTERN_1'),
  Command(name: 'Pattern 2', value: 'PATTERN_2'),
  Command(name: 'Speed Up', value: 'SPEED_UP'),
  Command(name: 'Speed Down', value: 'SPEED_DOWN'),
];
