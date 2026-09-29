enum CihazTipi {
  sensor,
  gateway,
  edgeServer,
  router,
}

class IoTCihaz {
  final String seriNo;
  final String cihazAdi;
  final CihazTipi tip;
  final double cpuYukYuzdesi;
  final int bellekMb;
  final Set<String> acikPortlar;
  final bool sslSertifikasiGecerliMi;
  final bool acikMi;

  IoTCihaz({
    required this.seriNo,
    required this.cihazAdi,
    required this.tip,
    required this.cpuYukYuzdesi,
    required this.bellekMb,
    required this.acikPortlar,
    required this.sslSertifikasiGecerliMi,
    this.acikMi = true,
  });

  bool get guvenlikAcigiVarMi =>
      !sslSertifikasiGecerliMi ||
      acikPortlar.contains("23/TELNET");

  bool get riskliMi =>
      guvenlikAcigiVarMi || cpuYukYuzdesi > 85;
}

class CihazErisilemezException implements Exception {
  final String mesaj;

  CihazErisilemezException(this.mesaj);

  @override
  String toString() => mesaj;
}

// Dart 3 Record: cihaz adı, tipi ve alarm durumu döndürülür.
(String cihazAdi, CihazTipi tip, bool alarmDurumu) cihazBilgisiBul(
  List<IoTCihaz> cihazlar,
  String seriNo,
) {
  for (final cihaz in cihazlar) {
    if (cihaz.seriNo == seriNo) {
      return (cihaz.cihazAdi, cihaz.tip, cihaz.riskliMi);
    }
  }

  throw StateError("$seriNo seri numaralı cihaz bulunamadı.");
}

// Dart 3 Switch Expression
String izolasyonBolgesiBul(CihazTipi tip) {
  return switch (tip) {
    CihazTipi.sensor => "ZONE-S",
    CihazTipi.gateway => "ZONE-G",
    CihazTipi.edgeServer => "ZONE-E",
    CihazTipi.router => "ZONE-R",
  };
}

void cihazaBaglan(IoTCihaz cihaz) {
  if (!cihaz.acikMi) {
    throw CihazErisilemezException(
      "${cihaz.cihazAdi} (${cihaz.seriNo}) kapalı olduğu için erişilemiyor.",
    );
  }

  print("${cihaz.cihazAdi} cihazına bağlantı başarılı.");
}

void main() {
  // Altı farklı cihazı tutan List
  final List<IoTCihaz> cihazlar = [
    IoTCihaz(
      seriNo: "IOT-001",
      cihazAdi: "Sıcaklık Sensörü",
      tip: CihazTipi.sensor,
      cpuYukYuzdesi: 25.0,
      bellekMb: 128,
      acikPortlar: {"443/HTTPS"},
      sslSertifikasiGecerliMi: true,
    ),
    IoTCihaz(
      seriNo: "IOT-002",
      cihazAdi: "Nem Sensörü",
      tip: CihazTipi.sensor,
      cpuYukYuzdesi: 40.0,
      bellekMb: 256,
      acikPortlar: {"80/HTTP"},
      sslSertifikasiGecerliMi: false,
    ),
    IoTCihaz(
      seriNo: "IOT-003",
      cihazAdi: "Ana Gateway",
      tip: CihazTipi.gateway,
      cpuYukYuzdesi: 70.0,
      bellekMb: 1024,
      acikPortlar: {"443/HTTPS", "23/TELNET"},
      sslSertifikasiGecerliMi: true,
    ),
    IoTCihaz(
      seriNo: "IOT-004",
      cihazAdi: "Edge Sunucu",
      tip: CihazTipi.edgeServer,
      cpuYukYuzdesi: 92.0,
      bellekMb: 4096,
      acikPortlar: {"443/HTTPS", "22/SSH"},
      sslSertifikasiGecerliMi: true,
    ),
    IoTCihaz(
      seriNo: "IOT-005",
      cihazAdi: "Ana Router",
      tip: CihazTipi.router,
      cpuYukYuzdesi: 85.0,
      bellekMb: 512,
      acikPortlar: {"22/SSH"},
      sslSertifikasiGecerliMi: true,
    ),
    IoTCihaz(
      seriNo: "IOT-006",
      cihazAdi: "Yedek Gateway",
      tip: CihazTipi.gateway,
      cpuYukYuzdesi: 0.0,
      bellekMb: 0,
      acikPortlar: <String>{},
      sslSertifikasiGecerliMi: false,
      acikMi: false,
    ),
  ];

  print("=== AĞDAKİ CİHAZLAR ===");
  for (final cihaz in cihazlar) {
    print(
      "${cihaz.seriNo} | ${cihaz.cihazAdi} | "
      "Tip: ${cihaz.tip.name} | CPU: %${cihaz.cpuYukYuzdesi} | "
      "Bellek: ${cihaz.bellekMb} MB | "
      "Durum: ${cihaz.acikMi ? 'Açık' : 'Kapalı'}",
    );
    print("Açık portlar: ${cihaz.acikPortlar.join(', ')}");
  }

  // where() ile riskli cihazlardan yeni liste oluşturulur.
  final List<IoTCihaz> riskliCihazlar = cihazlar
      .where((cihaz) => cihaz.riskliMi)
      .toList();

  print("\n=== RİSKLİ CİHAZLAR ===");
  for (final cihaz in riskliCihazlar) {
    print(
      "${cihaz.cihazAdi} | "
      "Güvenlik açığı: ${cihaz.guvenlikAcigiVarMi} | "
      "CPU: %${cihaz.cpuYukYuzdesi}",
    );
  }
  print("Riskli cihaz sayısı: ${riskliCihazlar.length}");

  // fold() ile bütün cihazların bellek kullanımları toplanır.
  final int toplamBellek = cihazlar.fold<int>(
    0,
    (toplam, cihaz) => toplam + cihaz.bellekMb,
  );

  print("\nToplam bellek kullanımı: $toplamBellek MB");

  print("\n=== SERİ NUMARASIYLA CİHAZ BULMA ===");
  try {
    // Dönen Record, üç ayrı değişkene ayrılır.
    final (cihazAdi, tip, alarmDurumu) =
        cihazBilgisiBul(cihazlar, "IOT-004");

    print("Cihaz adı: $cihazAdi");
    print("Cihaz tipi: ${tip.name}");
    print("Alarm durumu: ${alarmDurumu ? 'Aktif' : 'Pasif'}");
  } on StateError catch (hata) {
    print("Arama hatası: ${hata.message}");
  }

  // Listede olmayan seri numarası da ele alınır.
  try {
    cihazBilgisiBul(cihazlar, "IOT-999");
  } on StateError catch (hata) {
    print("Arama hatası: ${hata.message}");
  }

  print("\n=== İZOLASYON BÖLGELERİ ===");
  for (final cihaz in cihazlar) {
    print(
      "${cihaz.cihazAdi} → ${izolasyonBolgesiBul(cihaz.tip)}",
    );
  }

  print("\n=== CİHAZLARA BAĞLANMA ===");
  for (final cihaz in cihazlar) {
    try {
      cihazaBaglan(cihaz);
    } on CihazErisilemezException catch (hata) {
      print("Bağlantı hatası: $hata");
    }
  }
}
