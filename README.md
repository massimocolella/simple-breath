# Simple Breath (Respiro) for Garmin

Simple Breath is a Connect IQ watch app that guides slow, paced breathing on a
Garmin Forerunner 245 or Forerunner 245 Music. The app uses an animated circle:
it expands while you inhale and contracts while you exhale.

The default rhythm is 5.5 seconds in and 5.5 seconds out. Both durations and
the circle color can be changed from the app settings.

## Features

- Separate, configurable inhale and exhale durations.
- Smooth circle animation updated every 100 milliseconds.
- Current phase (`INSPIRA` or `ESPIRA`) shown at the top of the screen.
- Remaining phase time shown inside the circle in tenths of a second.
- Session timer shown as `MM:SS`, or `H:MM:SS` after one hour.
- Backlight kept active during a running session at the watch's configured
  brightness level.
- Heart-rate sensor enabled only while the exercise is running.
- Each completed session saved as a FIT activity named `Respiro` and synced by
  Garmin Connect.
- Automatic save when leaving the app during an active session.
- High-contrast countdown text selected automatically for the chosen circle
  color.

## Using the app

1. Open **Respiro** from the activity/app list on the watch.
2. Review the configured inhale and exhale durations on the ready screen.
3. Press the physical **START/ENTER** button to begin.
4. Follow the circle:
   - breathe in while it grows;
   - breathe out while it shrinks.
5. Press **START/ENTER** again to stop and save the session.

Pressing **BACK** during a session also stops and saves it before leaving the
app.

## Screen information

While a session is running, the top line contains the current breathing phase
and total elapsed exercise time. The number inside the circle is the time left
in the current inhale or exhale phase.

The circle reaches its maximum size at the end of inhalation and its minimum
size at the end of exhalation. A new cycle then starts automatically.

## Settings

Open the app details in Garmin Connect, the Connect IQ app, or Garmin Express,
then select **Settings**. Availability of each settings interface depends on
the phone and desktop software being used.

| Setting | Default | Allowed values |
| --- | ---: | --- |
| Inhale duration | 5.5 seconds | 1–30 seconds |
| Exhale duration | 5.5 seconds | 1–30 seconds |
| Circle color | Light blue | Light blue, green, yellow, orange, red, purple, pink, or white |

Decimal values are supported. The decimal separator may follow the phone's
locale, so the default can appear as either `5.5` or `5,5`.

The current on-watch interface and settings labels are in Italian.

## Garmin Connect activity recording

Starting the breathing exercise also starts a generic FIT recording. Stopping
the exercise saves the recording under the name `Respiro`. After the next watch
sync, Garmin Connect should show it as a generic or **Other** activity with its
duration and heart-rate data when available.

The app requests only these Connect IQ permissions:

- `Fit`, to create and save the activity;
- `Sensor`, to read heart rate during the exercise.

It does not request positioning or network access. More information is
available in Garmin's [Activity Recording documentation][activity-recording].

## Backlight and battery use

During an active session, the app periodically requests the backlight so the
display remains easy to read. Brightness still follows the system setting on
the watch. Keeping the backlight active uses more battery than the normal
timeout behavior.

After the session stops or the app closes, the app stops requesting the
backlight and normal watch behavior resumes.

## Supported devices

- Garmin Forerunner 245 (`fr245`)
- Garmin Forerunner 245 Music (`fr245m`)

The minimum declared Connect IQ API version is 3.1.0.

## Building from source

### Requirements

- [Garmin Connect IQ SDK][connect-iq-sdk]
- Forerunner 245 and/or Forerunner 245 Music device definitions
- A Connect IQ developer key
- Optional: Visual Studio Code with Garmin's Monkey C extension

Clone the repository:

```sh
git clone git@github.com:massimocolella/simple-breath.git
cd simple-breath
```

With the Monkey C extension, run **Monkey C: Build for Device** and select the
required watch model.

To build from a configured command line:

```sh
monkeyc \
  -f monkey.jungle \
  -d fr245 \
  -y /path/to/developer-key.der \
  -o bin/Respiro-fr245.prg
```

For the Music model, replace `fr245` with `fr245m` and use a corresponding
output filename.

Compiler output, PRG packages, debug files, and developer keys are excluded
from Git by `.gitignore`.

## Manual installation

Until the app is distributed through the Connect IQ Store, it can be
side-loaded:

1. Build the PRG for the exact watch model.
2. Connect the watch to the computer with a USB data cable.
3. Open the watch storage and locate `GARMIN/APPS`.
4. Copy the generated PRG into that directory.
5. Safely eject the watch and disconnect the cable.

Garmin also documents this process in [Side Loading an App][side-loading].

## Project structure

```text
manifest.xml                  App metadata, devices, and permissions
monkey.jungle                 Connect IQ build configuration
source/                       Monkey C application code
resources/drawables/          Launcher icon
resources/settings/           Configurable properties and setting definitions
resources/strings/            Interface and settings strings
```

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

[activity-recording]: https://developer.garmin.com/connect-iq/core-topics/activity-recording/
[connect-iq-sdk]: https://developer.garmin.com/connect-iq/sdk/
[side-loading]: https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/#side-loading-an-app
