# MacScrollFix'e Katkıda Bulunma

Katkınız için teşekkürler. MacScrollFix küçük ve odaklı bir macOS yardımcı
uygulamasıdır; değişikliklerin mevcut davranışı ve trackpad güvenliğini koruması
önemlidir.

## Geliştirme ortamı

- macOS 13 veya daha yeni bir sürüm
- Xcode 14 veya daha yeni bir sürüm
- Üçüncü taraf bağımlılık gerekmez

Projeyi `ScrollFix.xcodeproj` ile açın ve **ScrollFix** scheme'ini kullanın.

## Katkı akışı

1. Değişiklik yapmadan önce ilgili bir issue açın veya mevcut issue'yu inceleyin.
2. Kendi fork'unuzda açıklayıcı isimli bir branch oluşturun.
3. Değişikliklerinizi küçük ve tek amaçlı tutun.
4. Mevcut kod stilini ve Türkçe kullanıcı metinlerini koruyun.
5. Yeni davranış ekliyorsanız uygun XCTest kapsamı ekleyin.
6. Debug ve Release derlemelerini, ardından birim testlerini çalıştırın.
7. Açıklayıcı bir pull request oluşturun.

## Kontrol komutları

```sh
xcodebuild \
  -project ScrollFix.xcodeproj \
  -scheme ScrollFix \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project ScrollFix.xcodeproj \
  -scheme ScrollFix \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project ScrollFix.xcodeproj \
  -scheme ScrollFix \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Pull request kontrol listesi

- [ ] Mouse scroll düzeltme davranışı korunuyor.
- [ ] Continuous trackpad olayları değiştirilmeden geçiriliyor.
- [ ] Accessibility ve Launch at Login akışları bozulmadı.
- [ ] Menü çubuğu uygulamasına gereksiz pencere veya bağımlılık eklenmedi.
- [ ] Debug ve Release derlemeleri başarılı.
- [ ] Birim testleri başarılı.
- [ ] Hassas bilgi, kişisel dosya yolu veya derleme çıktısı eklenmedi.
