// Archivo: lib/domain/entities/tecnico.dart

class Tecnico {
  final String id;
  final String nombreCompleto;
  final String carnetIdentidad; // Validado en RF-01 [cite: 126]
  final String especialidad;    // Plomería, Electricidad, etc. [cite: 132]
  final String fotoPerfilUrl;
  final String certificadoAntecedentesUrl; // Requerido en RF-01 
  final bool identidadVerificada; // Estado "Aprobado" por admin [cite: 159]
  final bool disponibleGps;       // Para el rastreo en tiempo real [cite: 304]
  final double promedioCalificacion; // Reputación digital [cite: 132]
  final int aniosExperiencia;

  Tecnico({
    required this.id,
    required this.nombreCompleto,
    required this.carnetIdentidad,
    required this.especialidad,
    required this.fotoPerfilUrl,
    required this.certificadoAntecedentesUrl,
    this.identidadVerificada = false, // Por defecto no verificado
    this.disponibleGps = false,
    this.promedioCalificacion = 0.0,
    this.aniosExperiencia = 0,
  });

  // Método para verificar si puede recibir trabajos (Regla de Negocio)
  bool puedeTrabajar() {
    return identidadVerificada && disponibleGps;
  }
}