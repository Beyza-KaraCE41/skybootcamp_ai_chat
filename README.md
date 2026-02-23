# A.R.I.A. - AI Chat Assistant

A.R.I.A., benim geliştirdiğim Flutter tabanlı bir yapay zeka sohbet asistanı. Groq API'sini kullanarak LLaMA modellerini çalıştırıyor ve Türkçe konuşma tanıma, sesli çıktı ve resim analizi gibi özelliklere sahip.

---

## Özellikler

• Sesli komut - Türkçe konuşarak yazı gönderebilirsiniz  
• Sesli çıktı - AI yanıtlarını Türkçe sesle dinleyebilirsiniz  
• Resim analizi - Resimleri gönderin, AI analiz etsin  
• Not defteri - Önemli yanıtları kaydedip organize edin  
• Metin kopyalama - Cevapları panoya kopyalayın  
• Modern arayüz - Glassmorphism tasarımı  
• Koyu tema - Gözler için rahat dark mode  

---

## Ekran Görüntüleri

### Hoş Geldin Ekranı
![Welcome](https://raw.githubusercontent.com/your-username/ARIA-ChatApp/main/docs/screenshots/1-welcome.png)

### Chat Arayüzü
![Chat](https://raw.githubusercontent.com/your-username/ARIA-ChatApp/main/docs/screenshots/2-chat.png)

### Resim Analizi
![Image Analysis](https://raw.githubusercontent.com/your-username/ARIA-ChatApp/main/docs/screenshots/3-image.png)

### İçerik Menüsü
![Context Menu](https://raw.githubusercontent.com/your-username/ARIA-ChatApp/main/docs/screenshots/4-menu.png)

### Sesli Dinle
![Audio](https://raw.githubusercontent.com/your-username/ARIA-ChatApp/main/docs/screenshots/5-audio.png)

### Not Defteri
![Notes](https://raw.githubusercontent.com/your-username/ARIA-ChatApp/main/docs/screenshots/6-notes.png)

---

## Teknoloji Stack

• Flutter 3.0+  
• Dart  
• Groq API (LLaMA modelleri)  
• Speech to Text (Türkçe)  
• Flutter TTS (Türkçe)  
• Google Fonts  
• Lottie Animasyonları  
• SharedPreferences  
• Image Picker  

---

## Kurulum

### Gereksinimler

• Flutter 3.0 veya üzeri  
• Dart 3.0 veya üzeri  
• Groq API anahtarı  

### Adımlar

1. Repoyu klonlayın
```bash
git clone https://github.com/your-username/ARIA-ChatApp.git
cd ARIA-ChatApp
```

2. Bağımlılıkları yükleyin
```bash
flutter pub get
```

3. .env dosyası oluşturun (proje kökünde)
```
GROQ_API_KEY=your_api_key_here
```

Groq API anahtarını [console.groq.com](https://console.groq.com) adresinden alabilirsiniz.

4. Uygulamayı çalıştırın
```bash
flutter run
```

---

## Proje Yapısı

```
ARIA-ChatApp/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   └── chat_screen.dart
│   ├── services/
│   │   └── chat_service.dart
│   └── models/
│       └── chat_message.dart
├── assets/
│   └── animations/
│       └── ai_chat.json
├── docs/
│   └── screenshots/
│       ├── 1-welcome.png
│       ├── 2-chat.png
│       ├── 3-image.png
│       ├── 4-menu.png
│       ├── 5-audio.png
│       └── 6-notes.png
├── pubspec.yaml
├── .env
└── README.md
```

---

## Nasıl Kullanılır?

### Sesli Komut

Aşağı kısımdaki mikrofon ikonuna tıklayın. Türkçe konuşun ve otomatik olarak metne dönüşür. Tekrar tıklayarak dinlemeyi durdurun.

### Resim Gönderme

Ek ikonu (paperclip) tıklayarak galeriden resim seçin. AI resimi analiz edip açıklaması gönderecek.

### Yanıtları Dinleme

AI'nin mesajının altında "Sesli Dinle" butonuna tıklayın. Yanıt Türkçe sesle okunacak.

### Not Defterine Kaydetme

Mesaja uzun basın. Açılan menüden "Not Defterine Kaydet" seçin. Kaydedilen notlar not defteri ekranında görüntülenir.

---

## API Konfigürasyonu

Uygulama şu Groq API modellerini kullanır:

• `llama-3.3-70b-versatile` - Normal metin yanıtları için  
• `meta-llama/llama-4-scout-17b-16e-instruct` - Resim analizi için  

### .env Dosyası

Proje kökünde `.env` dosyası oluşturun. `.gitignore` içinde zaten var olduğu için GitHub'a yüklenmeyecek:

```
GROQ_API_KEY=gsk_your_api_key_here
```

---

## Bağımlılıklar

```yaml
dependencies:
  flutter: sdk: flutter
  google_fonts: ^6.0.0
  lottie: ^2.6.0
  shared_preferences: ^2.2.0
  image_picker: ^1.0.0
  speech_to_text: ^6.2.0
  flutter_tts: ^0.14.0
  http: ^1.1.0
  flutter_dotenv: ^5.1.0
```

---

## Sorun Giderme

### API Anahtarı hatası

`.env` dosyasının proje kökünde olduğundan ve doğru anahtarı içerdiğinden emin olun.

### Ses izni hatası

Ayarlardan uygulamaya mikrofon ve hoparlör izni verin.

### Resim seçilemiyor

Galeri izninizi kontrol edin.

---


## İletişim

• GitHub: [@Beyza-KaraCE41](https://github.com/Beyza-KaraCE41)  
