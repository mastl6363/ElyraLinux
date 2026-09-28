# ElyraLinux

Nativer Linux-Desktop-Host für [Elyra](https://github.com/mastl6363/elyra) —
einen modernen, werbefreien Musikplayer für lokale Sammlungen (MP3, FLAC).

Das Original-Projekt ist eine .NET MAUI Blazor Hybrid App für Windows/Android/
iOS. .NET MAUI hat kein offizielles Linux-Ziel; dieses Repo bringt dieselbe
Razor-UI und Kernlogik (geteilter Code aus `src/Elyra.Shared`) stattdessen
über **Blazor Server** (Kestrel) auf den Linux-Desktop — die App läuft als
lokaler Server und öffnet sich in einem Chrome-App-Fenster (kein Tab, keine
Adressleiste, echtes Icon in der Taskleiste).

## Tech-Stack

| Schicht        | Technologie                              |
|----------------|-------------------------------------------|
| App-Host       | ASP.NET Core / Blazor Server (Kestrel)    |
| Frontend / UI  | Razor + HTML + Tailwind CSS (npm)         |
| Kern-Logik     | C# / .NET 10                              |
| Audio-Engine   | LibVLCSharp (FLAC + MP3, gapless)         |
| Metadaten/ID3  | TagLib# (TagLibSharp)                     |
| Fenster        | Chrome/Chromium `--app`-Modus              |

## Architektur

```
src/
  Elyra.Shared/     Components (Razor-UI), Models, Services — plattform-
                     unabhängig, geteilt mit der MAUI-App
  Elyra.Desktop/     Blazor-Server-Host (Program.cs, App.razor)
packaging/deb/       .deb-Paketierung (Launcher, .desktop-Eintrag, Icons)
```

`Elyra.Desktop` bindet die Quelldateien aus `Elyra.Shared` per MSBuild-`Link`
ein (kein Git-Submodul, keine NuGet-Abhängigkeit) — beide Projekte kompilieren
unabhängig, Plattform-spezifischer Code in `Services/` ist per
`#if ANDROID || IOS || MACCATALYST || WINDOWS` weggeschaltet.

## Installation (empfohlen: APT-Repository)

Für Debian/Ubuntu/Linux Mint (amd64) gibt es ein signiertes APT-Repository,
gehostet über GitHub Pages:

```bash
sudo curl -fsSL https://mastl6363.github.io/ElyraLinux/apt/elyra-archive-keyring.gpg \
  -o /usr/share/keyrings/elyra-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elyra-archive-keyring.gpg] \
https://mastl6363.github.io/ElyraLinux/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/elyra.list

sudo apt update
sudo apt install elyra
```

Updates kommen danach ganz normal über `apt upgrade`. Alternativ: das `.deb`
manuell von den [Releases](https://github.com/mastl6363/ElyraLinux/releases)
laden und mit `sudo dpkg -i` installieren (siehe unten, „.deb bauen und
installieren").

Abhängigkeiten (werden bei der `apt install`-Installation automatisch
mitgezogen, für manuelle `.deb`-Installation selbst nötig):

```bash
sudo apt install libvlc5 libvlc-dev vlc-plugin-base zenity
```

- `libvlc5`/`vlc-plugin-base` — Audio-Engine (LibVLCSharp)
- `zenity` — nativer Ordnerauswahl-Dialog
- `google-chrome-stable` (oder Chromium/Edge) — fürs App-Fenster; ohne
  Chromium-Browser fällt die App auf den System-Standardbrowser zurück

## Entwickeln

```bash
cd src/Elyra.Desktop
ASPNETCORE_ENVIRONMENT=Development dotnet run
```

## .deb bauen und installieren

```bash
bash packaging/deb/build-deb.sh          # optional: Versionsnummer als Argument
sudo dpkg -i packaging/deb/dist/elyra_1.0.0_amd64.deb
```

Danach erscheint **Elyra** im App-Menü mit eigenem Icon.

## APT-Repository aktualisieren (Maintainer)

Nach `packaging/deb/build-deb.sh` liegt das neue `.deb` in
`packaging/deb/dist/`. Das GitHub-Pages-Repo unter `docs/apt/` daraus neu
erzeugen und signieren:

```bash
GPG_KEY_ID=<fingerprint-des-signierschlüssels> bash packaging/apt/build-apt-repo.sh
git add docs/apt && git commit -m "Update APT repo" && git push
```

Der private Signierschlüssel lebt nur lokal (`gpg --list-secret-keys`), nie im
Repo. `docs/apt/elyra-archive-keyring.{asc,gpg}` enthält nur den öffentlichen
Teil.

## Bekannte Einschränkungen

- Video-/DVD-Wiedergabe (**Filme**) ist auf diesem Host noch nicht
  implementiert — die MAUI-eigene `VideoPlayerPage` lässt sich nicht direkt in
  ein Blazor-Server-Fenster einbetten. Musik, Wiedergabelisten und Radio
  funktionieren vollständig.
- Läuft nur lokal (`127.0.0.1`) — kein Mehrbenutzerbetrieb vorgesehen.

## Lizenz

[MIT](LICENSE) — wie das Hauptprojekt.
