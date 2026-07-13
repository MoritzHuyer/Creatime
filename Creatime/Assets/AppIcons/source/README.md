# Creatime App Icons

Drei Varianten passend zum Liquid-Glass-Look der App. **Master ist `default.svg`** — alle anderen Varianten kann der User später via `UIApplication.setAlternateIconName(...)` umschalten (Settings → „App-Icon wechseln").

## Variants

| Datei | Hintergrund | Passend für |
|---|---|---|
| `default.svg` | Blau-Lila Gradient (#5B7FFF → #9774E8) + Glass-Sheen | Standard-Light, Default-iOS-Look |
| `dark.svg` | Tiefes Navy-Dunkel (#1A1D33 → #06081C) | Dark-Mode / Always-On-Displays |
| `clear.svg` | Helles, fast weißes Glass (#F2F3FB → #D9DCF2) | iOS 18+ Light-Tint-User, Minimalismus-Fans |

Alle drei haben das gleiche Motiv: oranger Progress-Ring (75% Bogen, Lücke unten) + weißer Kreatin-Scoop mittig. Nur der Hintergrund variiert.

## Export zu PNGs

`rsvg-convert` ist auf deinem Mac installiert (`/opt/homebrew/bin/rsvg-convert`, v2.62.3). Ein Terminal-Einzeiler:

```bash
cd Creatime/Assets/AppIcons/source
rsvg-convert -w 1024 -h 1024 -b '#0000' default.svg -o ../AppIcon.appiconset/AppIcon-1024.png
rsvg-convert -w 1024 -h 1024 -b '#0000' dark.svg   -o ../AppIconDark.appiconset/AppIconDark-1024.png
rsvg-convert -w 1024 -h 1024 -b '#0000' clear.svg  -o ../AppIconClear.appiconset/AppIconClear-1024.png
```

`-b '#0000'` setzt Background auf transparent — wichtig für die korrekte Squircle-Wirkung im Asset-Catalog.

## Asset-Catalog Setup (bereits erledigt)

- `Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` ← Master (Default)
- `Assets.xcassets/AppIconDark.appiconset/AppIconDark-1024.png` ← Alt-Icon „Dark"
- `Assets.xcassets/AppIconClear.appiconset/AppIconClear-1024.png` ← Alt-Icon „Clear"
- Jedes Set hat eine `Contents.json`, die auf die PNG-Datei zeigt.

### Alt-Icon in der App umschalten

In `Info.plist` einmalig registrieren:

```xml
<key>CFBundleIcons</key>
<dict>
    <key>CFBundlePrimaryIcon</key>
    <dict>
        <key>CFBundleIconName</key>
        <string>AppIcon</string>
    </dict>
    <key>CFBundleAlternateIcons</key>
    <dict>
        <key>AppIconDark</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array><string>AppIconDark</string></array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
        <key>AppIconClear</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array><string>AppIconClear</string></array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
    </dict>
</dict>
```

Im Code:
```swift
UIApplication.shared.setAlternateIconName("AppIconDark") { error in ... }
UIApplication.shared.setAlternateIconName(nil)           // zurück zu Default
```

Im Settings-Tab eine Sektion „App-Icon" mit 3 Choices dafür anlegen — kann ich gern als nächstes einbauen.
