# Publicar una versión y firma de release

Guía para quien mantiene la app. Nada de esto es secreto: la llave de firma y
su clave nunca están en el repo.

## Publicar una versión

La app busca versiones nuevas en los
[Releases](https://github.com/jshvargsdev/lukas_sync_app/releases) de este repo
(`releases/latest`), así que publicar es crear un release:

1. Sube `version` en `pubspec.yaml` (p. ej. `2.1.0+3` → `2.2.0+4`; el número
   después de `+` siempre debe subir).
2. `flutter analyze && flutter test`.
3. `scripts/build_release.sh`.
4. Crea el release con tag `v<versión>`, los tres APK con su nombre original
   (`app-<abi>-release.apk`) y las notas en español **en texto plano** (sin
   Markdown: la app las muestra tal cual, así que `**` o `*` se verían). Para
   listas usa `•`:

   ```bash
   gh release create v2.2.0 \
     build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
     build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
     build/app/outputs/flutter-apk/app-x86_64-release.apk \
     --title "Lukas Sync 2.2.0" --notes-file notas.txt
   ```

Las apps instaladas lo detectan en un máximo de 6 horas (o al tocar "Buscar" en
Ajustes > Actualizaciones). No publiques un release como "latest" si no
quieres que todos lo reciban: para pruebas usa `--prerelease`, que la API de
`releases/latest` ignora.

## Firma

El APK release se firma con la llave de release si existe `android/key.properties`
(ignorado por git). Si no existe, se firma con la llave de debug de la máquina.

1. Copia `android/key.properties.example` a `android/key.properties` y completa
   la ruta al keystore y sus claves.
2. El keystore **no va en el repo**. Guárdalo, junto con su clave, en un lugar
   seguro con respaldo: sin él no se pueden publicar actualizaciones que se
   instalen encima de la versión que ya tienen los usuarios.

Huella SHA-256 del certificado de release. Es pública por diseño (viene dentro
de cada APK): sirve para comprobar que un APK lo firmó esta llave y no fue
alterado. Lo que no debe publicarse nunca es el keystore ni su clave.
`41:0C:E2:A2:9F:46:33:DD:B0:9D:EF:9A:5C:E8:C3:3D:61:5E:DE:27:E4:4E:02:86:70:9A:F8:27:7B:10:45:05`

Para comprobar la firma de un APK:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```
