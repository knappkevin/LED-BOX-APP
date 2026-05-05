import 'dart:convert';

class Command {
  final String name;
  final String value;

  Command({required this.name, required this.value});

  Map<String, dynamic> toJson() => {'name': name, 'value': value};

  factory Command.fromJson(Map<String, dynamic> json) =>
      Command(name: json['name'], value: json['value']);

  Command copyWith({String? name, String? value}) =>
      Command(name: name ?? this.name, value: value ?? this.value);
}

List<Command> defaultCommands = [
  Command(name: 'RGB Worms', value: 'rgb worms'),
  Command(name: 'RGB Fleas', value: 'rgb fleas'),
  Command(name: 'RGB Wave', value: 'rgb wave'),
  Command(name: 'RGB Fill', value: 'rgb fill'),
  Command(name: 'RGB Pulse', value: 'rgb pulse'),
  Command(name: 'Worms', value: 'worms'),
  Command(name: 'Snake', value: 'snake'),
  Command(name: 'Life', value: 'life'),
];

String commandsToJson(List<Command> commands) =>
    jsonEncode(commands.map((c) => c.toJson()).toList());

List<Command> commandsFromJson(String jsonStr) {
  final List<dynamic> decoded = jsonDecode(jsonStr);
  return decoded.map((e) => Command.fromJson(e)).toList();
}
