# Geliştirme Kuralları

## Kod Kalitesi
- **Linting:** PEP8 kurallarına uyulacak.
- **Testler:** Unit testler ve integration testler yazılacak.

## Version Control
- **Git:** Kaynak kod yönetimi için Git kullanılacak.
- **Branching Strategy:** Git Flow branching strategy kullanılacak.

## Dokümantasyon
- **Kod Dokümantasyonu:** Her fonksiyon ve sınıfın dokümantasyonu yapılacak.
- **Proje Dokümantasyonu:** Mimari tasarım, geliştirme kuralları, proje planı ve diğer belgeler oluşturulacak.

## Deployment
- **CI/CD:** Continuous Integration ve Continuous Deployment süreçleri kurulacak.
- **Kubernetes:** Mikro-servislerin Kubernetes üzerinde deploy edilmesi.

## Potansiyel Sorunlar ve Çözümleri
- **Dosya Oluşturma Hatası:**
  - **Sorun:** `development_guidelines.md` dosyası oluştururken `filepath` argümanı boş veya sadece boşluk içerdi.
  - **Çözüm:** `filepath` argümanının doğru şekilde belirtilmesi sağlandı.
- **Eksik Dosyalar:**
  - **Sorun:** `project_info.txt`, `hardware_info.txt`, `network_info.txt`, `user_access_info.txt` dosyaları eksik.
  - **Çözüm:** Bu dosyalar oluşturuldu.
