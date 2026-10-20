آیکون‌های Flutter Web ترازیار

فایل‌ها را در پوشه web/ پروژه کپی کنید:
- favicon.png  -> web/favicon.png
- favicon-16.png و favicon-32.png -> در صورت نیاز برای faviconهای چندسایزی
- icons/Icon-192.png -> web/icons/Icon-192.png
- icons/Icon-512.png -> web/icons/Icon-512.png
- manifest.json -> web/manifest.json

در web/index.html بررسی کنید که این ارجاعات وجود داشته باشند:
<link rel="icon" type="image/png" href="favicon.png"/>
<link rel="manifest" href="manifest.json"/>

پس از کپی:
flutter clean
flutter pub get
flutter build web

اگر index.html فعلی پروژه را بفرستید، می‌توانم دقیقاً همان فایل را با ساختار فعلی پروژه اصلاح کنم.
