# nova-vehicleinteract

In-vehicle menu for seats, doors, windows, hood, trunk, engine, and neon. It does not require QBCore, ESX, or another Nova script. You can keep driving while it is open. The mouse controls the menu.

The menu is a short icon bar. Engine and neon toggle with one click. Seats, doors, windows, and hood or trunk open a small list above the icon. Only parts the vehicle actually has are shown.

## Features

- **Engine** — one click. Only the driver, unless `Config.EngineDriverOnly` is false. The icon stays lit while the engine is on.
- **Seats** — a list of the real seats. Move to a free one.
- **Doors** — a list of the real doors. Bikes do not get car doors.
- **Hood and trunk** — one icon. The list shows whichever of those parts the vehicle has.
- **Windows** — a list of the real windows. Open or closed is read from the vehicle.
- **Neon** — the model must have a neon bone (`neon_l`, `neon_r`, `neon_f`, or `neon_b`). `Config.NeonMode` is `verified` by default: the lights toggle only after the server confirms a purchased kit. `free` skips that check. `disabled` removes the control. A bone is not proof of purchase.
- **Notifications** — `nova-ui` if it is started, then ox_lib, then the framework, then the game ticker.
- **Drag** — drag the name to move the bar. The place is remembered.
- **Version check** — on start, `version.json` is compared with `main` on `github.com/msaber07/nova-vehicleinteract`. A newer version prints a line in the server console.
- **Icons** — Material Design Icons, Apache-2.0. See `THIRD-PARTY-NOTICES.md`.
- **Keys** — if `nova-vehiclekeys`, `qb-vehiclekeys`, `qs-vehiclekeys`, `wasabi_carlock`, or `Renewed-Vehiclekeys` is running, the engine starts only when that script says you have the key. None of them is required. Turning the engine off does not ask for a key.

You are inside the vehicle, so a locked door can still be opened from this menu.

## Installation

1. Copy the folder to `resources/[standalone]/nova-vehicleinteract`.
2. Add `ensure nova-vehicleinteract` to `server.cfg`. Order does not matter.
3. Restart, then sit in a vehicle and press **K** or type `/vehiclemenu`.

G is left for the engine key used by common key scripts. Change `Config.MenuKey` if K is taken. Players can also rebind it under FiveM key binds. The bind name follows `Config.Locale`.

## Configuration

| Option | Default | Description |
| --- | --- | --- |
| `Config.MenuKey` | `'K'` | Key that opens the menu. G stays free for the engine. |
| `Config.Command` | `'vehiclemenu'` | Chat command. |
| `Config.Locale` | `'en'` | `'en'` or `'tr'`. |
| `Config.Notify` | `'auto'` | `'auto'`, `'ox'`, or `'qb'`. |
| `Config.UseNovaUI` | `true` | Use `nova-ui` for notifications when it is started. |
| `Config.EngineDriverOnly` | `true` | Only the driver toggles the engine. |
| `Config.RequireKeys` | `true` | If a known key script is running, the engine starts only with a key. No key script means the driver can start it. |
| `Config.NeonMode` | `'verified'` | `'verified'`, `'free'`, or `'disabled'`. Verified denies neon when no server provider confirms a kit. |
| `Config.Features.*` | `true` | `seats`, `doors`, `windows`, `hood`, `trunk`, `engine`, `neon`. |

## Neon kit API

Other resources call these **server** exports. The client cannot grant itself a kit.

```lua
exports['nova-vehicleinteract']:SetNeonInstalled(plate, true)
exports['nova-vehicleinteract']:IsNeonInstalled(plate)

-- Server only. Do not return true for every plate.
-- true  = this plate has a purchased kit
-- nil   = this provider does not know the plate
-- A copied "return true" marks every vehicle as purchased.
exports['nova-vehicleinteract']:RegisterNeonProvider(function(src, plate)
    local owned = MyKitTable[plate]
    if owned == nil then
        return nil
    end
    return owned == true
end)
```

`verified` allows the toggle when any provider returns `true`, or when `SetNeonInstalled` has recorded that plate. `nil` does not grant a kit. If nobody confirms the plate, the button stays hidden.

Standard garage props (`neonEnabled`) only store whether the lights are on. They are not used as purchase proof.

## Exports

```lua
exports['nova-vehicleinteract']:OpenMenu()
exports['nova-vehicleinteract']:CloseMenu()
exports['nova-vehicleinteract']:ToggleMenu()
local open = exports['nova-vehicleinteract']:IsOpen()
```

## License

You may use and edit this resource on your own FiveM server. You may not sell it, bundle it into a paid package, or redistribute it under another name. The Nova name stays on the resource.

---

## Türkçe

Araç içi menü: koltuk, kapı, cam, kaput, bagaj, motor ve neon. QBCore, ESX veya başka bir Nova scripti gerekmez. Menü açıkken sürüş sürer. Fare menüye gider.

Menü kısa bir ikon şeridi. Motor ve neon tek tık. Koltuk, kapı, cam, kaput ve bagaj ikonun üstünde küçük bir liste açar. Yalnız araçta olan parçalar görünür.

### Özellikler

- **Motor** — tek tık. `Config.EngineDriverOnly` false değilse yalnız şoför. Motor açıkken ikon yanık kalır.
- **Koltuk** — gerçek koltukların listesi. Boş olana geçilir.
- **Kapılar** — gerçek kapıların listesi. Motosiklette araba kapısı çıkmaz.
- **Kaput ve bagaj** — tek ikon. Listede araçta olan parça durur.
- **Camlar** — gerçek camların listesi. Açık veya kapalı hali araçtan okunur.
- **Neon** — modelde neon kemiği şart. Varsayılan `verified`: sunucu satın alınmış kiti doğrulamazsa açılmaz. `free` bu kontrolü atlar. `disabled` neonu kapatır. Kemik, satın alma kanıtı değildir. Sağlayıcı örneği yukarıdaki İngilizce bölümde. Bilinmeyen plakada `nil` dönülür. Düz `return true` her aracı kitli sayar.
- **Bildirim** — `nova-ui` açıksa o, yoksa ox_lib, yoksa framework, yoksa oyunun kendi bildirimi.
- **Sürükleme** — adı tutup şeridi taşı. Yer hatırlanır.
- **Sürüm kontrolü** — açılışta `version.json`, `github.com/msaber07/nova-vehicleinteract` üzerindeki `main` ile karşılaştırılır.
- **İkonlar** — Material Design Icons, Apache-2.0. Ayrıntı `THIRD-PARTY-NOTICES.md` dosyasında.
- **Anahtar** — `nova-vehiclekeys`, `qb-vehiclekeys`, `qs-vehiclekeys`, `wasabi_carlock` veya `Renewed-Vehiclekeys` çalışıyorsa motor yalnız anahtar varsa çalışır. Hiçbiri zorunlu değildir. Motoru kapatmak anahtar istemez.

Menü araçtayken açıldığı için kilitli kapı içeriden yine açılır.

### Kurulum

1. Klasörü `resources/[standalone]/nova-vehicleinteract` altına kopyala.
2. `server.cfg` içine `ensure nova-vehicleinteract` ekle. Sıra fark etmez.
3. Yeniden başlat. Araca bin, **K** tuşuna bas veya `/vehiclemenu` yaz.

G, yaygın anahtar scriptlerinde motor tuşu olduğu için boş bırakıldı. K doluysa `Config.MenuKey` değiştir. Oyuncu tuşu FiveM kısayollarından da değiştirebilir.

### Exportlar

```lua
exports['nova-vehicleinteract']:OpenMenu()
exports['nova-vehicleinteract']:CloseMenu()
exports['nova-vehicleinteract']:ToggleMenu()
local open = exports['nova-vehicleinteract']:IsOpen()
```

### Lisans

Kendi FiveM sunucunda kullanabilir ve düzenleyebilirsin. Bu kaynağı satamazsın, ücretli bir pakete koyamazsın ve başka bir adla dağıtamazsın. Nova adı resource üzerinde kalır.
