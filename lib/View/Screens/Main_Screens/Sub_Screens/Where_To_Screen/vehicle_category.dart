enum VehicleCategory {
  passenger,
  matatu,
  cargo,
  movers,
  ambulance,
  breakdown,
  waterBowser,
  exhauster,
  carhire,
  mechanical,
  machinery,
}

extension VehicleCategoryExtension on VehicleCategory {
  String get displayName {
    switch (this) {
      case VehicleCategory.passenger:
        return 'Ride Booking';
      case VehicleCategory.matatu:
        return 'Matatu/Bus';
      case VehicleCategory.cargo:
        return 'Cargo Transport';
      case VehicleCategory.movers:
        return 'Movers';
      case VehicleCategory.ambulance:
        return 'Ambulance';
      case VehicleCategory.breakdown:
        return 'Breakdown Services';
      case VehicleCategory.waterBowser:
        return 'Water Bowser';
      case VehicleCategory.exhauster:
        return 'Exhauster';
      case VehicleCategory.carhire:
        return 'Car Hire';
      case VehicleCategory.mechanical:
        return 'Mechanical Services';
      case VehicleCategory.machinery:
        return 'Machinery';
    }
  }

  String get apiValue => name; // Will be sent as string like "movers"
}
