# Kalandjáték-motor

Egy Fighting Fantasy stílusú 2D kalandjáték-motor integrált szerkesztővel, amely lehetővé teszi saját interaktív kalandok létrehozását és lejátszását.

## Tartalomjegyzék

- [Áttekintés](#áttekintés)
- [Funkciók](#funkciók)
- [Követelmények](#követelmények)
- [Telepítés](#telepítés)
- [Használat](#használat)
- [Mappastruktúra](#mappastruktúra)
- [Modulok](#modulok)
- [Közösségi platform](#közösségi-platform)

## Áttekintés

A projekt egy háromrétegű rendszer része, amely a következő komponensekből áll:
- **Játékmotor** - Kalandmodulok lejátszása szerepjátékos mechanikákkal
- **Kalandszerkesztő** - Vizuális felület saját modulok létrehozásához
- **Közösségi platform** - Modulok megosztása és letöltése (külön repository)

Ez a repository a Godot Engine-ben készült játékmotort és szerkesztőt tartalmazza.

## Funkciók

### Játékmotor
- Döntésalapú történetvezetés
- Karakterstatisztikák kezelése (élet, mana, arany)
- Kockadobás-alapú próbák és küzdelmek
- Szövegfelolvasás (TTS) támogatás
- Modul-specifikus mentési rendszer
- Modulok letöltése a közösségi platformról

### Kalandszerkesztő
- Vizuális jelenetszerkesztő
- 1-3 választási lehetőség jelenetekenként
- Kockadobás tesztek és követelmények beállítása
- Statisztika módosítók (buff-ok)
- Projekt mentés és betöltés (.advproj)
- Modul exportálás (.gdz)
- Automatikus mentés (5 percenként)

## Követelmények

- **Godot Engine 4.5** vagy újabb
- **Operációs rendszer:** Windows / Linux / macOS
- **Backend szerver** (opcionális, csak modul letöltéshez szükséges)

## Telepítés

### Futtatható verzió (ajánlott)

1. Töltsd le a legújabb kiadást a [Releases](../../releases) oldalról
2. Csomagold ki a letöltött fájlt
3. Indítsd el a `Text_Based_Adventure.exe` fájlt (Windows) vagy a megfelelő futtatható fájlt

### Fejlesztői verzió

1. Klónozd a repository-t:
```bash
git clone [repository-url]
```

2. Nyisd meg a projektet Godot Engine 4.5-tel:
   - Indítsd el a Godot Engine-t
   - Kattints az "Import" gombra
   - Navigálj a projekt mappájához és válaszd ki a `project.godot` fájlt

3. Futtasd a projektet az F5 billentyűvel vagy a lejátszás gombbal

## Használat

### Játékmotor

1. Indítsd el az alkalmazást
2. A főmenüben válaszd ki a játszani kívánt modult
3. Olvasd el a jelenetek szövegét és válassz a felkínált lehetőségek közül
4. A játékállás automatikusan mentésre kerül

**Billentyűparancsok:**
- `Esc` - Visszatérés a főmenübe
- TTS be/kikapcsolása a beállításokban

### Kalandszerkesztő

1. A főmenüből válaszd a "Szerkesztő" opciót
2. Hozz létre új projektet vagy nyiss meg egy meglévőt
3. Adj hozzá jeleneteket és állítsd be a választási lehetőségeket
4. Mentsd el a projektet (.advproj)
5. Exportáld a kész modult (.gdz)

**Jelenet beállítások:**
- **Key:** Egyedi azonosító (pl. "start", "forest_path")
- **Title:** A jelenet címe
- **Narr_text:** A jelenet narratív szövege
- **Choices:** Választási lehetőségek (1-3 darab)

**Választás beállítások:**
- Céljelenet megadása
- Kockadobás teszt (opcionális)
- Követelmények (élet, mana, arany)
- Buff-ok (statisztika módosítók)
- Sikertelen kimenet (kockadobás esetén)

## Mappastruktúra

Az alkalmazás a következő helyen tárolja az adatokat:

```
%appdata%/Godot/Text_Based_Adventure/
├── modules/           # Letöltött és exportált modulok (.gdz)
├── saves/             # Mentett játékállások
└── projects/          # Szerkesztő projektek (.advproj)
```

## Modulok

### .gdz fájlformátum

A modulok .gdz kiterjesztésű csomagolt fájlok, amelyek a következőket tartalmazzák:

```
modul.gdz (ZIP archívum)
├── story_data.json    # Jelenetek és választások
└── module_info.json   # Modul metaadatok (cím, leírás)
```

### Modul telepítése

1. Másold a .gdz fájlt a `%appdata%/Godot/Text_Based_Adventure/modules/` mappába
2. Indítsd újra az alkalmazást
3. A modul megjelenik a főmenüben

### Modul létrehozása

1. Nyisd meg a szerkesztőt
2. Hozz létre jeleneteket és kapcsold össze őket
3. Állítsd be a játékmechanikákat (kockadobás, követelmények, buff-ok)
4. Exportáld a projektet .gdz formátumban

## Közösségi platform

A modulok letöltéséhez szükséges a backend szerver futtatása. A közösségi platform lehetővé teszi:

- Modulok böngészését és letöltését
- Saját modulok feltöltését
- Értékelések és vélemények írását

A backend és frontend külön repository-ban található.

**Kapcsolódó repository-k:**
- Backend: [link a backend repo-hoz]
- Frontend: [link a frontend repo-hoz]

## Technológiák

- **Godot Engine 4.5** - Játékmotor
- **GDScript** - Programozási nyelv
- **JSON** - Adattárolás

## Szerző

Gerencir Leon

Készült a Pécsi Tudományegyetem Műszaki és Informatikai Karán, szakdolgozat keretében (2025).
