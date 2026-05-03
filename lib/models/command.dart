class Command {
  final String name;
  final String value;

  const Command({required this.name, required this.value});
}

const List<Command> defaultCommands = [
  Command(name: 'RGB Worms', value: 'rgb worms'),
  Command(name: 'RGB Fleas', value: 'rgb fleas'),
  Command(name: 'RGB Wave', value: 'rgb wave'),
  Command(name: 'RGB Fill', value: 'rgb fill'),
  Command(name: 'RGB Pulse', value: 'rgb pulse'),
  Command(name: 'Worms', value: 'worms'),
  Command(name: 'Snake', value: 'snake'),
  Command(name: 'Life', value: 'life'),
];
