import 'package:flutter/material.dart';
class Blower {
  final num velocidad;
  final bool estado;

  const Blower({
    required this.velocidad,
    required this.estado,
  });

  // Método para crear una copia con nuevos valores
  Blower copyWith({
    num? velocidad,
    bool? estado,
  }) {
    return Blower(
      velocidad: velocidad ?? this.velocidad,
      estado: estado ?? this.estado,
    );
  }

  // Convertir a Map para JSON
  Map<String, dynamic> toMap() {
    return {
      'velocidad': velocidad,
      'estado': estado,
    };
  }

  // Crear desde Map (JSON)
  factory Blower.fromMap(Map<String, dynamic> map) {
    return Blower(
      velocidad: map['velocidad'] ?? 0,
      estado: map['estado'] ?? false,
    );
  }

  // Método toString para debugging
  @override
  String toString() {
    return 'Blower(velocidad: $velocidad, estado: $estado)';
  }

  // Comparación de objetos
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Blower &&
        other.velocidad == velocidad &&
        other.estado == estado;
  }

  @override
  int get hashCode => velocidad.hashCode ^ estado.hashCode;
}