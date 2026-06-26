# AI Grid Mimari Tasarımı

## Genel Bakış
AI Grid projesi, birlikte MoE (Mixture of Experts) tabanlı bir yapay zeka gridi oluşturmayı amaçlamaktadır. Proje iki ana makineden oluşmaktadır: Makine-1 (Pc-1) ve Makine-2 (Pc-2). Makine-1, yönetim ve eğitim sunucusu olarak görev yaparken, Makine-2 eğitim veri depolama ve eğitim modellerinin çalıştırılacağı yardımcı sunucu olarak görev yapmaktadır.

## Donanım ve Yazılım
- **Makine-1 (Pc-1):**
  - **CPU:** Ryzen 7 7700X3D
  - **RAM:** 32GB
  - **GPU:** 16GB 5060Ti
- **Makine-2 (Pc-2):**
  - **IP Adresi:** 192.168.50.2

## Ağ Yapısı
- **SSH Bağlantısı:** Makine-1 (Pc-1) ve Makine-2 (Pc-2) arasında SSH bağlantısı kurulacak.

## Veri Yönetimi
- **Depolama:** Eğitim verileri Makine-2 (Pc-2)'de depolanacak.
- **Erişim:** Makine-1 (Pc-1) ve Makine-2 (Pc-2) arasında veri paylaşımı için NFS (Network File System) kullanılacak.

## Mikro-Servisler
- **Orkestrasyon:** Kubernetes kullanılarak mikro-servisler yönetilecek.
- **Mikro-Servisler:**
  - **Veri İşleme Servisi:** Eğitim verilerinin işlenmesi.
  - **Eğitim Servisi:** Eğitim modelinin çalıştırılması.
  - **API Servisi:** Kullanıcıların API aracılığıyla modellere erişimi sağlama.

## Scalabilite ve Yük Dengeleme
- **Kubernetes:** Yük dağılımı ve ölçeklendirme için Kubernetes kullanılacak.
- **Load Balancer:** Yük dengeli dağıtım için NGINX kullanılacak.

## Güvenlik
- **SSH Bağlantısı:** Passwordless SSH yapılandırması mevcut.
- **Ağ Güvenliği:** Firewal kuralları ve ağ güvenliği düzenlemeleri yapılacak.