Config = Config or {}

-- The key that opens the menu (the player can also change it from FiveM key binds)
Config.MenuKey = 'G'

-- Chat command. Default is English. Example: 'aracmenu'
Config.Command = 'vehiclemenu'

-- Language: 'tr' or 'en'
Config.Locale = 'en'

-- 'auto' uses nova-ui, then ox_lib, then the framework, then the game notification.
-- 'ox' forces ox_lib when it is started. 'qb' forces the framework notification.
Config.Notify = 'auto'

-- If you have nova-ui installed, use it for notifications (otherwise it will be default as above).
Config.UseNovaUI = true

-- Openable and closing features
Config.Features = {
    seats = true, -- Changing seats
    doors = true, -- Doors (4 doors)
    windows = true,  -- Camlar
    hood    = true,  -- Kaput
    trunk   = true,  -- Bagaj
    engine = true, -- Engine on/off
    neon = true, -- Neon lights on/off
}

-- Only allow engine control while in the driver's seat
Config.EngineDriverOnly = true

Config.Locales = {
    tr = {
        notInVehicle = 'Araç içinde olmalısın.',
        seatTaken    = 'Bu koltuk dolu.',
        seatSwitched = 'Koltuğa geçtin.',
        doorOpened   = 'Kapı açıldı.',
        doorClosed   = 'Kapı kapatıldı.',
        doorLocked   = 'Kapı kilitli.',
        windowDown   = 'Cam açıldı.',
        windowUp     = 'Cam kapatıldı.',
        hoodOpened   = 'Kaput açıldı.',
        hoodClosed   = 'Kaput kapatıldı.',
        trunkOpened  = 'Bagaj açıldı.',
        trunkClosed  = 'Bagaj kapatıldı.',
        engineOn     = 'Motor çalıştırıldı.',
        engineOff    = 'Motor durduruldu.',
        neonOn       = 'Neon açıldı.',
        neonOff      = 'Neon kapatıldı.',
        notDriver    = 'Sadece şoför motoru kontrol edebilir.',
        keybind      = 'Araç etkileşim menüsü',
        seatLabels   = { [-1] = 'Şoför', [0] = 'Ön yolcu', [1] = 'Arka sol', [2] = 'Arka sağ', [3] = 'Arka orta' },
        doorLabels   = { [0] = 'Ön sol', [1] = 'Ön sağ', [2] = 'Arka sol', [3] = 'Arka sağ' },
        windowLabels = { [0] = 'Ön sol', [1] = 'Ön sağ', [2] = 'Arka sol', [3] = 'Arka sağ' },
        ui = {
            title      = 'ARAÇ MENÜ',
            secEngine  = 'MOTOR',
            secSeats   = 'KOLTUK',
            secDoors   = 'KAPILAR',
            secAccess  = 'KAPUT / BAGAJ',
            secWindows = 'CAMLAR',
            secLights  = 'IŞIKLAR',
            close      = 'Çık',
            footer     = 'Sürmeye devam edebilirsin — kapatmak için tuşa tekrar bas',
            hood       = 'Kaput',
            trunk      = 'Bagaj',
            engineOn   = 'Motor: Açık',
            engineOff  = 'Motor: Kapalı',
            neonOn     = 'Neon: Açık',
            neonOff    = 'Neon: Kapalı',
            stOpen     = 'Açık',
            stClosed   = 'Kapalı',
            stYou      = 'Sen',
            stTaken    = 'Dolu',
        },
    },
    en = {
        notInVehicle = 'You must be in a vehicle.',
        seatTaken    = 'That seat is taken.',
        seatSwitched = 'Switched seat.',
        doorOpened   = 'Door opened.',
        doorClosed   = 'Door closed.',
        doorLocked   = 'The door is locked.',
        windowDown   = 'Window rolled down.',
        windowUp     = 'Window rolled up.',
        hoodOpened   = 'Hood opened.',
        hoodClosed   = 'Hood closed.',
        trunkOpened  = 'Trunk opened.',
        trunkClosed  = 'Trunk closed.',
        engineOn     = 'Engine started.',
        engineOff    = 'Engine stopped.',
        neonOn       = 'Neon lights turned on.',
        neonOff      = 'Neon lights turned off.',
        notDriver    = 'Only the driver can control the engine.',
        keybind      = 'Vehicle interaction menu',
        seatLabels   = { [-1] = 'Driver', [0] = 'Front Passenger', [1] = 'Rear Left', [2] = 'Rear Right', [3] = 'Rear Middle' },
        doorLabels   = { [0] = 'Front Left', [1] = 'Front Right', [2] = 'Rear Left', [3] = 'Rear Right' },
        windowLabels = { [0] = 'Front Left', [1] = 'Front Right', [2] = 'Rear Left', [3] = 'Rear Right' },
        ui = {
            title      = 'VEHICLE MENU',
            secEngine  = 'ENGINE',
            secSeats   = 'SEATS',
            secDoors   = 'DOORS',
            secAccess  = 'HOOD / TRUNK',
            secWindows = 'WINDOWS',
            secLights  = 'LIGHTS',
            close      = 'Exit',
            footer     = 'You can keep driving — press the key again to close',
            hood       = 'Hood',
            trunk      = 'Trunk',
            engineOn   = 'Engine: On',
            engineOff  = 'Engine: Off',
            neonOn     = 'Neon: On',
            neonOff    = 'Neon: Off',
            stOpen     = 'Open',
            stClosed   = 'Closed',
            stYou      = 'You',
            stTaken    = 'Taken',
        },
    },
}
