class DatosFacturacionModel {
  final bool    usarDatosCliente;
  final String? razonSocial;
  final String? rucCedula;
  final String? direccion;
  final String? email;
  final String? telefono;

  const DatosFacturacionModel({
    required this.usarDatosCliente,
    this.razonSocial,
    this.rucCedula,
    this.direccion,
    this.email,
    this.telefono,
  });

  factory DatosFacturacionModel.fromJson(Map<String, dynamic> j) =>
      DatosFacturacionModel(
        usarDatosCliente: j['factUsarDatosCliente'] as bool? ?? true,
        razonSocial:      j['factRazonSocial']?.toString(),
        rucCedula:        j['factRucCedula']?.toString(),
        direccion:        j['factDireccion']?.toString(),
        email:            j['factEmail']?.toString(),
        telefono:         j['factTelefono']?.toString(),
      );

  Map<String, dynamic> toJson() => {
    'usarDatosCliente':    usarDatosCliente,
    'razonSocial':         razonSocial,
    'rucCedula':           rucCedula,
    'direccionFacturacion':direccion,
    'emailFacturacion':    email,
    'telefonoFacturacion': telefono,
  };
}