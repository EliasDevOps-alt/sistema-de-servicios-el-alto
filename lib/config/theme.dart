import 'package:flutter/material.dart';

class AppTheme {
  // Colores inspirados en seguridad (Azul) y construcción/trabajo (Naranja)
  static const Color primaryColor = Color(0xFF1565C0); // Azul Oscuro (Confianza)
  static const Color accentColor = Color(0xFFEF6C00);  // Naranja (Acción/Trabajo)
  static const Color backgroundColor = Color(0xFFF5F5F5); // Gris muy claro (Limpio)

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      // Configuración de la Barra Superior (AppBar)
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Estilo de los Botones (Grandes y fáciles de tocar)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55), // Botones altos
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),

      // Estilo de los Inputs (Cajas de texto)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIconColor: primaryColor,
      ),
    );
  }
}