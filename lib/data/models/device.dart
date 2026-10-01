enum DeviceType { light, ac, tv, other }

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final String room;
  bool isOn;
  int level; // brightness / temperature / volume 0-100

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.room,
    this.isOn = false,
    this.level = 50,
  });

  Device copyWith({bool? isOn, int? level}) => Device(
        id: id,
        name: name,
        type: type,
        room: room,
        isOn: isOn ?? this.isOn,
        level: level ?? this.level,
      );
}
