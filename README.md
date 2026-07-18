# Simple Breath (Respiro) for Garmin

Simple Breath is a Connect IQ watch app that guides slow, paced breathing on
compatible Garmin Forerunner watches. The app uses an animated circle: it
expands while you inhale and contracts while you exhale.

The default rhythm is 5.5 seconds in and 5.5 seconds out. Phase durations,
session duration, circle color, vibration cues, and sound cues can be changed
from the app settings.

## Inspiration

The idea for this app came while reading James Nestor's book *Breath*. It
inspired a simple tool for practicing slow, regular breathing without having to
keep count or watch a clock.

## Features

- Separate, configurable inhale and exhale durations.
- Smooth circle animation updated every 100 milliseconds.
- Full-brightness circle while inhaling and the same color at 55% brightness
  while exhaling.
- Current phase (`INHALE` or `EXHALE`) shown at the top of the screen.
- Remaining phase time shown inside the circle in tenths of a second.
- Free sessions or automatic completion after 5, 10, 15, or 20 minutes.
- Session duration selectable directly on the watch and saved for the next run.
- Session timer shown as `MM:SS`, or `H:MM:SS` after one hour. A timed session
  also shows its target duration.
- Configurable vibration cues at every phase change, once per complete cycle,
  or disabled.
- Distinct vibration patterns: one pulse for inhalation and two pulses for
  exhalation.
- Optional short beep at each configured breathing cue, plus a distinct
  completion tone at the end of a timed session.
- Best-effort backlight requests during a running session, respecting platform
  limits and the watch's configured brightness level.
- Heart-rate sensor enabled only while the exercise is running.
- Each completed session saved as a localized FIT activity and synced by Garmin
  Connect.
- Automatic save when leaving the app during an active session.
- English and Italian interface selected automatically from the watch language.
- High-contrast countdown text selected automatically for the chosen circle
  color.

## Using the app

1. Open **Simple Breath** (or **Respiro** in Italian) from the activity/app list
   on the watch.
2. Review the configured inhale, exhale, and session durations on the ready
   screen.
3. To change the session duration, press **DOWN**, select `Unlimited`, 5, 10,
   15, or 20 minutes, and press **START/ENTER** to confirm.
4. Press the physical **START/ENTER** button to begin.
5. Follow the circle:
   - breathe in while it grows at full brightness;
   - breathe out while it shrinks in a darker shade;
   - follow the configured vibration cues without needing to watch the display.
6. Press **START/ENTER** again to stop and save the session. A timed session
   stops and saves automatically when it reaches its configured duration.

Pressing **BACK** during a session also stops and saves it before leaving the
app.

## Screen information

While a session is running, the top line contains the current breathing phase
and total elapsed exercise time. Timed sessions show elapsed and target time as
`MM:SS/MM:SS`. The number inside the circle is the time left in the current
inhale or exhale phase.

The circle reaches its maximum size at the end of inhalation and its minimum
size at the end of exhalation. Its brightness changes immediately at each phase
boundary, and a new cycle starts automatically.

## Settings

Session duration can be changed directly on the ready screen by pressing
**DOWN**. All settings are also defined for Garmin Connect, the Connect IQ
app, or Garmin Express once the app is distributed through the Connect IQ
Store. Availability of each external settings interface depends on how the app
was installed and on the phone or desktop software being used.

| Setting | Default | Allowed values |
| --- | ---: | --- |
| Inhale duration | 5.5 seconds | 1–30 seconds |
| Exhale duration | 5.5 seconds | 1–30 seconds |
| Session duration | Unlimited | Unlimited, 5, 10, 15, or 20 minutes |
| Circle color | Light blue | Light blue, green, yellow, orange, red, purple, pink, or white |
| Vibration | Every phase | Off, every cycle, or every phase |
| Sound cues | Off | Off, every cycle, or every phase |

Decimal values are supported. The decimal separator may follow the phone's
locale, so the default can appear as either `5.5` or `5,5`.

The vibration and sound modes behave as follows:

- **Off**: no cues of that type.
- **Every cycle**: a cue when exhalation ends and the next inhalation begins.
- **Every phase**: cues at both inhale-to-exhale and exhale-to-inhale
  transitions.

Vibration uses one pulse for inhalation and two pulses for exhalation. Sound
uses the same short beep at each configured transition. When a timed session
completes, each enabled cue type also provides a distinct completion signal.

The app currently includes English and Italian translations. English is used as
the fallback for other system languages.

## Garmin Connect activity recording

Starting the breathing exercise also starts a generic FIT recording. Stopping
the exercise saves the recording under the localized name `Breathing` or
`Respiro`. After the next watch sync, Garmin Connect should show it as a generic
or **Other** activity with its duration and heart-rate data when available.

The app requests only these Connect IQ permissions:

- `Fit`, to create and save the activity;
- `Sensor`, to read heart rate during the exercise.

It does not request positioning or network access. More information is
available in Garmin's [Activity Recording documentation][activity-recording].

## Backlight and battery use

During an active session, the app periodically requests the backlight so the
display remains easy to read. Brightness still follows the system setting on
the watch. Some AMOLED devices can limit prolonged backlight requests; the app
continues the breathing session normally if the platform declines one. Keeping
the display active uses more battery than the normal timeout behavior.

After the session stops or the app closes, the app stops requesting the
backlight and normal watch behavior resumes.

## Supported devices

| Family | Models |
| --- | --- |
| Forerunner 55 | 55 |
| Forerunner 245 | 245, 245 Music |
| Forerunner 255 | 255, 255 Music, 255S, 255S Music |
| Forerunner 265 | 265, 265S |
| Forerunner 745 | 745 |
| Forerunner 945 | 945, 945 LTE |

The interface scales automatically from the 208×208, eight-color Forerunner 55
display to the 416×416 AMOLED Forerunner 265 display. Device-specific launcher
icons are included where Garmin requires a different native size.

The minimum declared Connect IQ API version is 3.1.0.

## Building from source

### Requirements

- [Garmin Connect IQ SDK][connect-iq-sdk]
- Device definitions for the watch models you want to build
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

Replace `fr245` with another product ID from `manifest.xml` to build for a
different supported model.

To create the signed multi-device package used by the Connect IQ Store:

```sh
monkeyc \
  -e \
  -f monkey.jungle \
  -y /path/to/developer-key.der \
  -o bin/SimpleBreath.iq
```

Keep the developer key safe: the same key is required to publish future
updates of the app.

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
resources-fr*/drawables/      Device-specific launcher icon sizes
resources/settings/           Configurable properties and setting definitions
resources/strings/            Default English strings
resources-ita/strings/        Italian strings
store/                        Store listing copy and tested screenshots
```

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

[activity-recording]: https://developer.garmin.com/connect-iq/core-topics/activity-recording/
[connect-iq-sdk]: https://developer.garmin.com/connect-iq/sdk/
[side-loading]: https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/#side-loading-an-app
