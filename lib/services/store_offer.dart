/// Offre d'abonnement affichée dans le paywall (web + mobile).
/// [nativePackage] est le `Package` RevenueCat sur mobile uniquement.
class StoreOffer {
  final String title;
  final String priceString;
  final Object? nativePackage;

  const StoreOffer({
    required this.title,
    required this.priceString,
    this.nativePackage,
  });
}
