# MacScrollFix

<p align="center">
  <img src="MacScrollFix/AppIcon.icon/Assets/MacScrollFixIcon.png" alt="MacScrollFix uygulama ikonu" width="180">
</p>

MacScrollFix, standart USB veya Bluetooth mouse tekerleğinin yönünü Windows'taki
alışılmış hisse göre düzeltmek için çalışan küçük, yerel bir macOS menü çubuğu
uygulamasıdır. macOS'in genel Natural Scrolling ayarını değiştirmez.

## What MacScrollFix does

- Harici mouse'lardan gelen kesikli (**discrete**) scroll olaylarının yönünü tersine çevirir.
- Trackpad ve trackpad-benzeri aygıtlardan gelen sürekli (**continuous**) scroll olaylarına dokunmaz.
- Dikey, yatay ve üçüncü eksen scroll deltalarını destekler.
- İnternet bağlantısı veya üçüncü taraf bağımlılık kullanmaz.

## Requirements

- macOS 13 Ventura veya daha yeni bir sürüm
- Xcode 26 veya daha yeni bir sürüm
- Scroll olaylarını işlemek için macOS **Accessibility** izni
- Standart tekerlekli USB veya Bluetooth mouse

## Build & Run

Normal geliştirme akışı Apple hesabı veya Team seçimi gerektirmez.

1. Repoyu clone edin:

   ```bash
   git clone https://github.com/ozanyuksel07/MacScrollFix.git ~/Downloads/MacScrollFix
   cd ~/Downloads/MacScrollFix

2. Xcode projesini açın:

   ```bash
   open MacScrollFix.xcodeproj
   ```

3. Xcode'da scheme olarak **MacScrollFix**, hedef olarak **My Mac** seçin.

4. Run (`⌘R`) çalıştırın.

5. İstendiğinde Accessibility iznini verin:

   `System Settings → Privacy & Security → Accessibility → MacScrollFix`

6. Menü çubuğunda MacScrollFix simgesi göründüğünde uygulama kullanıma hazırdır. 
**Kaydırma Düzeltmesi** durumunun `Aktif` olduğunu doğrulayın.

7. Uygulamayı Xcode'dan bağımsız ve kalıcı kullanmak isterseniz Xcode menüsünden
   **Product → Show Build Folder in Finder** seçeneğini açın.
   Ardından `Products/Debug/MacScrollFix.app` dosyasını bulun ve `/Applications`
   klasörüne taşıyın. `/Applications` içindeki **MacScrollFix.app** dosyasını açın.
   macOS Accessibility iznini yeniden isterse bu kopya için bir kez izin verin.
   **Girişte Başlat** özelliğini kullanacaksanız uygulamayı `/Applications`
   klasörüne taşıdıktan sonra etkinleştirmeniz önerilir.

## Accessibility

İlk kullanımda macOS izni onaylamanızı ister. İzin verilmemişse şu yolu izleyin:

1. **System Settings > Privacy & Security > Accessibility** bölümünü açın.
2. **MacScrollFix**'i etkinleştirin.
3. Uygulama izni düzenli olarak kontrol eder ve algıladığında düzeltmeyi etkinleştirir.

### Rebuild troubleshooting

Bu yalnızca sık sık local/ad-hoc build alan geliştiriciler için bir edge case'tir.
macOS, yeniden derlenen bazı uygulamaları yeni bir Accessibility identity olarak
değerlendirebilir. System Settings'te MacScrollFix etkin görünmesine rağmen
uygulama hâlâ izin istiyorsa eski MacScrollFix kaydını Accessibility listesinden
kaldırın ve mevcut build'e bir kez yeniden izin verin.

## Optional Development Signing

Normal clone/build/run akışı için Team seçmek gerekmez; ücretsiz Apple hesabı
veya ücretli Apple Developer Program üyeliği bu local source kullanımı için şart
değildir. Sık rebuild sırasında Accessibility iznini daha stabil tutmak isteyen
geliştiriciler, Xcode'da **TARGETS > MacScrollFix > Signing & Capabilities > Team**
altından kendi Personal Team'ini seçebilir. Bu isteğe bağlı bir development
troubleshooting adımıdır. Developer ID ile imzalanmış ve notarized public dağıtım
ayrı bir konudur.

## Menu bar behavior

Menü çubuğundaki MacScrollFix simgesinden:

- **Kaydırma Düzeltmesi** özelliği açar veya kapatır.
- **Girişte Başlat** uygulamanın kullanıcı oturumu açıldığında başlamasını ister.
- **Erişilebilirlik Ayarları…** gerekli macOS ayarlarını açar.
- **Menü Çubuğundan Gizle** önce bir confirmation gösterir. Onaylandığında simge
  restart ve login launch sonrasında da gizli kalır; uygulama ve scroll düzeltmesi
  çalışmaya devam eder. Gizli çalışan uygulamayı Finder veya Applications üzerinden
  tekrar açmak simgeyi geri getirir ve bu tercihi temizler.

## Tests

Xcode'da `⌘U` kullanabilir veya şunu çalıştırabilirsiniz:

```sh
xcodebuild \
  -project MacScrollFix.xcodeproj \
  -scheme MacScrollFix \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Testler discrete/continuous scroll sınıflandırmasını, delta dönüşümünü, Launch at
Login durum eşlemesini ve menu bar visibility state'ini doğrular. Gerçek mouse,
trackpad ve uygulama davranışı ayrıca elle test edilmelidir.

## Privacy

MacScrollFix:

- İnternet bağlantısı, kullanıcı hesabı veya uzak servis kullanmaz.
- Kullanıcı verisi toplamaz, saklamaz veya paylaşmaz.
- Scroll olaylarını yalnızca cihaz üzerinde ve anlık olarak işler.
- Yerel teknik günlüklerde scroll değerlerini veya kullanıcı içeriğini kaydetmez.
- macOS'in genel Natural Scrolling ayarını değiştirmez.

## Limitations

- Standart, kesikli scroll olayı üreten fiziksel USB/Bluetooth mouse'lar hedeflenir.
- Magic Mouse ve bazı yüksek çözünürlüklü mouse'lar continuous olay üretebilir.
  Bunlar trackpad gibi değerlendirilir ve yönleri değiştirilmez.
- Fiziksel aygıt davranışı yalnızca otomatik birim testleriyle tamamen doğrulanamaz.

## Project layout

```text
MacScrollFix.xcodeproj/                 Xcode project and shared scheme
MacScrollFix/                           App sources, Info.plist, and AppIcon.icon
MacScrollFixTests/                      XCTest sources
```

## Contributing

Katkı akışı ve pull request beklentileri için [CONTRIBUTING.md](CONTRIBUTING.md)
dosyasına bakın.

## License

Bu proje [MIT Lisansı](LICENSE) ile sunulmaktadır.
