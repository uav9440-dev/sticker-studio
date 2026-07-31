/// Curated font catalog. Arabic faces come first — the app is Arabic-first.
/// The full store (hundreds of faces) is downloaded on demand and merged with
/// user-imported TTF/OTF files registered via FontLoader.
class StudioFont {
  const StudioFont(this.family, this.sample, {this.arabic = true});
  final String family;
  final String sample;
  final bool arabic;
}

abstract final class FontCatalog {
  static const featured = <StudioFont>[
    StudioFont('Cairo', 'صباح الخير'),
    StudioFont('Amiri', 'جمعة مباركة'),
    StudioFont('Marhey', 'مرحبا'),
    StudioFont('Reem Kufi', 'رمضان كريم'),
    StudioFont('Lateef', 'عيد سعيد'),
    StudioFont('Aref Ruqaa', 'مبارك'),
    StudioFont('Poppins', 'Good Morning', arabic: false),
    StudioFont('Playfair Display', 'Luxury', arabic: false),
    StudioFont('Bebas Neue', 'GAMING', arabic: false),
  ];
}
