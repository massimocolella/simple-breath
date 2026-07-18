using Toybox.Application as App;
using Toybox.Activity as Activity;
using Toybox.ActivityRecording as ActivityRecording;
using Toybox.Attention as Attention;
using Toybox.Graphics as Gfx;
using Toybox.Sensor as Sensor;
using Toybox.System as Sys;
using Toybox.Timer as Timer;
using Toybox.WatchUi as Ui;

class RespiroView extends Ui.View {
    private const FRAME_INTERVAL_MS = 100;
    private const BACKLIGHT_REFRESH_MS = 5000;
    private const DEFAULT_PHASE_MS = 5500;
    private const EXHALE_BRIGHTNESS_PERCENT = 55;
    private const VIBRATION_OFF = 0;
    private const VIBRATION_EVERY_CYCLE = 1;
    private const VIBRATION_EVERY_PHASE = 2;
    private const VIBRATION_STRENGTH = 60;
    private const VIBRATION_INHALE_MS = 160;
    private const VIBRATION_EXHALE_MS = 100;
    private const VIBRATION_PAUSE_MS = 90;
    private const VIBRATION_COMPLETE_MS = 500;
    private const SOUND_OFF = 0;
    private const SOUND_EVERY_CYCLE = 1;
    private const SOUND_EVERY_PHASE = 2;
    private const REFERENCE_DISPLAY_SIZE = 240;
    private const MIN_RADIUS_REFERENCE = 24;
    private const MAX_RADIUS_REFERENCE = 82;
    private const READY_RADIUS_REFERENCE = 48;
    private const GLOW_OUTER_REFERENCE = 8;
    private const GLOW_MIDDLE_REFERENCE = 5;
    private const GLOW_INNER_REFERENCE = 2;
    private const GLOW_OUTER_BRIGHTNESS_PERCENT = 22;
    private const GLOW_MIDDLE_BRIGHTNESS_PERCENT = 38;
    private const GLOW_INNER_BRIGHTNESS_PERCENT = 62;

    private var _frameTimer;
    private var _recordingSession;
    private var _recordingStarted = false;
    private var _isRunning = false;
    private var _isAwaitingSave = false;
    private var _lastPhaseIsInhaling = true;
    private var _startedAtMs = 0;
    private var _lastBacklightAtMs = 0;
    private var _backlightAvailable = true;
    private var _inhaleMs = DEFAULT_PHASE_MS;
    private var _exhaleMs = DEFAULT_PHASE_MS;
    private var _sessionDurationMs = 0;
    private var _vibrationMode = VIBRATION_EVERY_PHASE;
    private var _soundMode = SOUND_OFF;
    private var _circleColor = Gfx.COLOR_BLUE;
    private var _readyText;
    private var _inhaleText;
    private var _exhaleText;
    private var _inhaleShortText;
    private var _exhaleShortText;
    private var _activityNameText;
    private var _sessionText;
    private var _unlimitedText;
    private var _minutesShortText;
    private var _menuHintText;

    function initialize() {
        View.initialize();
        _frameTimer = new Timer.Timer();
        loadLocalizedText();
        reloadSettings();
    }

    function onShow() {
        loadLocalizedText();
        reloadSettings();
    }

    function onHide() {
        if (_isRunning) {
            _frameTimer.stop();
            _isRunning = false;
            stopRecordingForDecision();
            finalizeRecording(true);
        } else if (!_isAwaitingSave) {
            disableSessionSensors();
        }
    }

    function handleAppStop() {
        if (_isRunning) {
            _frameTimer.stop();
            _isRunning = false;
            stopRecordingForDecision();
            finalizeRecording(true);
        } else if (_isAwaitingSave) {
            _isAwaitingSave = false;
            finalizeRecording(true);
        }
    }

    function reloadSettings() {
        _inhaleMs = secondsToMilliseconds(
            App.Properties.getValue("InhaleSeconds"),
            DEFAULT_PHASE_MS
        );
        _exhaleMs = secondsToMilliseconds(
            App.Properties.getValue("ExhaleSeconds"),
            DEFAULT_PHASE_MS
        );

        var configuredColor = App.Properties.getValue("CircleColor");
        if (configuredColor != null) {
            _circleColor = configuredColor;
        }

        var configuredVibration = App.Properties.getValue("VibrationMode");
        if (configuredVibration != null) {
            _vibrationMode = configuredVibration;
        }

        var configuredSound = App.Properties.getValue("SoundMode");
        if (configuredSound != null) {
            _soundMode = configuredSound;
        }

        var configuredSessionDuration = App.Properties.getValue(
            "SessionDurationMinutes"
        );
        _sessionDurationMs = minutesToMilliseconds(configuredSessionDuration);

        // Una modifica delle durate fa ripartire il ritmo dall'inspirazione.
        if (_isRunning) {
            _startedAtMs = Sys.getTimer();
            _lastPhaseIsInhaling = true;
        }
    }

    function toggle() {
        if (_isRunning) {
            stop();
        } else {
            start();
        }
    }

    function isRunning() {
        return _isRunning;
    }

    function getSessionDurationMinutes() {
        return _sessionDurationMs / 60000;
    }

    function setSessionDurationMinutes(minutes) {
        App.Properties.setValue("SessionDurationMinutes", minutes);
        reloadSettings();
        Ui.requestUpdate();
    }

    function start() {
        if (_isRunning) {
            return;
        }

        reloadSettings();
        startRecording();
        _startedAtMs = Sys.getTimer();
        _lastBacklightAtMs = _startedAtMs;
        _backlightAvailable = true;
        _lastPhaseIsInhaling = true;
        _isRunning = true;
        requestBacklight();
        _frameTimer.start(method(:onFrame), FRAME_INTERVAL_MS, true);
        Ui.requestUpdate();
    }

    function stop() {
        if (!_isRunning) {
            return;
        }

        _frameTimer.stop();
        _isRunning = false;
        _isAwaitingSave = true;
        stopRecordingForDecision();

        var menu = new Ui.Menu2({
            :title => Rez.Strings.EndSessionTitle,
            :focus => 0
        });
        menu.addItem(new Ui.MenuItem(
            Rez.Strings.SaveSession,
            null,
            1,
            null
        ));
        menu.addItem(new Ui.MenuItem(
            Rez.Strings.DiscardSession,
            null,
            0,
            null
        ));
        Ui.pushView(
            menu,
            new RespiroSaveMenuDelegate(self),
            Ui.SLIDE_UP
        );
    }

    function resolveSaveDecision(shouldSave) {
        if (!_isAwaitingSave) {
            return;
        }

        _isAwaitingSave = false;
        finalizeRecording(shouldSave);
        Ui.requestUpdate();
    }

    function onFrame() {
        if (_isRunning) {
            var now = Sys.getTimer();
            var elapsed = now - _startedAtMs;

            if (elapsed < 0) {
                _startedAtMs = now;
                _lastPhaseIsInhaling = true;
                elapsed = 0;
            }

            if (_sessionDurationMs > 0 && elapsed >= _sessionDurationMs) {
                playCompletionCues();
                stop();
                return;
            }

            var sinceBacklightRefresh = now - _lastBacklightAtMs;

            if (_backlightAvailable && (sinceBacklightRefresh < 0
                    || sinceBacklightRefresh >= BACKLIGHT_REFRESH_MS)) {
                requestBacklight();
                _lastBacklightAtMs = now;
            }

            updatePhaseCues(elapsed);
        }

        Ui.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        if (_isRunning) {
            drawBreathingState(dc);
        } else {
            drawIdleState(dc);
        }
    }

    private function drawIdleState(dc) {
        var centerX = dc.getWidth() / 2;
        var centerY = getCircleCenterY(dc);
        var readyRadius = scaleToDisplay(dc, READY_RADIUS_REFERENCE);

        drawCenteredText(
            dc,
            scaleToDisplay(dc, 30),
            Gfx.FONT_XTINY,
            _menuHintText,
            Gfx.COLOR_LT_GRAY
        );

        drawGlowingCircle(dc, centerX, centerY, readyRadius, _circleColor);
        drawCenteredText(
            dc,
            centerY,
            Gfx.FONT_SMALL,
            _readyText,
            getContrastColor(_circleColor)
        );

        var phaseSummary = _inhaleShortText + " " + formatDuration(_inhaleMs)
            + "  " + _exhaleShortText + " " + formatDuration(_exhaleMs);
        drawCenteredText(
            dc,
            scaleToDisplay(dc, 193),
            Gfx.FONT_XTINY,
            phaseSummary,
            Gfx.COLOR_LT_GRAY
        );

        var sessionSummary = _sessionText + ": " + formatSessionDuration();
        drawCenteredText(
            dc,
            scaleToDisplay(dc, 214),
            Gfx.FONT_XTINY,
            sessionSummary,
            getSessionSummaryColor(dc)
        );
    }

    private function drawBreathingState(dc) {
        var now = Sys.getTimer();
        var elapsed = now - _startedAtMs;

        // System.getTimer() cambia segno periodicamente: ricomincia senza creare
        // un salto visivo se il rollover avviene durante una sessione.
        if (elapsed < 0) {
            _startedAtMs = now;
            elapsed = 0;
        }

        var cycleDuration = _inhaleMs + _exhaleMs;
        var cycleElapsed = elapsed % cycleDuration;
        var isInhaling = cycleElapsed < _inhaleMs;
        var phaseElapsed;
        var phaseDuration;

        if (isInhaling) {
            phaseElapsed = cycleElapsed;
            phaseDuration = _inhaleMs;
        } else {
            phaseElapsed = cycleElapsed - _inhaleMs;
            phaseDuration = _exhaleMs;
        }

        var progress = phaseElapsed.toFloat() / phaseDuration.toFloat();
        var radiusProgress = isInhaling ? progress : (1.0 - progress);
        var minRadius = scaleToDisplay(dc, MIN_RADIUS_REFERENCE);
        var maxRadius = scaleToDisplay(dc, MAX_RADIUS_REFERENCE);
        var radius = minRadius
            + ((maxRadius - minRadius) * radiusProgress).toNumber();
        var remainingMs = phaseDuration - phaseElapsed;
        var centerX = dc.getWidth() / 2;
        var centerY = getCircleCenterY(dc);
        var phaseName = isInhaling ? _inhaleText : _exhaleText;
        var elapsedText = formatElapsed(elapsed);
        if (_sessionDurationMs > 0) {
            elapsedText += "/" + formatElapsed(_sessionDurationMs);
        }
        var sessionStatus = phaseName + "  " + elapsedText;
        var phaseColor = getPhaseColor(isInhaling);

        drawCenteredText(
            dc,
            scaleToDisplay(dc, 28),
            Gfx.FONT_XTINY,
            sessionStatus,
            Gfx.COLOR_WHITE
        );

        drawGlowingCircle(dc, centerX, centerY, radius, phaseColor);
        drawCenteredText(
            dc,
            centerY,
            Gfx.FONT_SMALL,
            formatRemaining(remainingMs),
            getContrastColor(phaseColor)
        );

    }

    private function drawCenteredText(dc, y, font, text, color) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            y,
            font,
            text,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    private function getCircleCenterY(dc) {
        return dc.getHeight() / 2 + scaleToDisplay(dc, 8);
    }

    private function scaleToDisplay(dc, referencePixels) {
        var minimumDimension = dc.getWidth();
        if (dc.getHeight() < minimumDimension) {
            minimumDimension = dc.getHeight();
        }

        return minimumDimension * referencePixels / REFERENCE_DISPLAY_SIZE;
    }

    private function getSessionSummaryColor(dc) {
        // The Forerunner 55 palette has only eight colors, so dark gray can
        // collapse to the black background. Other supported displays retain
        // the subtler secondary text color used by the original 240px layout.
        return dc.getWidth() <= 208 && dc.getHeight() <= 208
            ? Gfx.COLOR_LT_GRAY
            : Gfx.COLOR_DK_GRAY;
    }

    private function drawGlowingCircle(dc, centerX, centerY, radius, color) {
        if (dc.getWidth() <= 208 && dc.getHeight() <= 208) {
            // Eight-color displays cannot represent a smooth dark gradient.
            // A sparse ring keeps the halo visible without enlarging the
            // solid breathing circle.
            dc.setColor(color, Gfx.COLOR_BLACK);
            dc.drawCircle(
                centerX,
                centerY,
                radius + scaleToDisplay(dc, GLOW_MIDDLE_REFERENCE)
            );
            dc.fillCircle(centerX, centerY, radius);
            return;
        }

        dc.setColor(
            applyBrightness(color, GLOW_OUTER_BRIGHTNESS_PERCENT),
            Gfx.COLOR_BLACK
        );
        dc.fillCircle(
            centerX,
            centerY,
            radius + scaleToDisplay(dc, GLOW_OUTER_REFERENCE)
        );

        dc.setColor(
            applyBrightness(color, GLOW_MIDDLE_BRIGHTNESS_PERCENT),
            Gfx.COLOR_BLACK
        );
        dc.fillCircle(
            centerX,
            centerY,
            radius + scaleToDisplay(dc, GLOW_MIDDLE_REFERENCE)
        );

        dc.setColor(
            applyBrightness(color, GLOW_INNER_BRIGHTNESS_PERCENT),
            Gfx.COLOR_BLACK
        );
        dc.fillCircle(
            centerX,
            centerY,
            radius + scaleToDisplay(dc, GLOW_INNER_REFERENCE)
        );

        dc.setColor(color, Gfx.COLOR_BLACK);
        dc.fillCircle(centerX, centerY, radius);
    }

    private function requestBacklight() {
        if (!_backlightAvailable) {
            return;
        }

        try {
            Attention.backlight(true);
        } catch (exception) {
            // Some AMOLED devices limit prolonged backlight requests. Continue
            // the session normally if the platform declines further requests.
            _backlightAvailable = false;
        }
    }

    private function secondsToMilliseconds(value, fallback) {
        if (value == null) {
            return fallback;
        }

        var milliseconds = (value * 1000).toNumber();
        return milliseconds > 0 ? milliseconds : fallback;
    }

    private function minutesToMilliseconds(value) {
        if (value == null || value <= 0) {
            return 0;
        }

        return (value * 60 * 1000).toNumber();
    }

    private function formatDuration(milliseconds) {
        var tenths = (milliseconds + 50) / 100;
        return (tenths / 10).toString() + "," + (tenths % 10).toString() + "s";
    }

    private function formatRemaining(milliseconds) {
        // Arrotondamento verso l'alto per evitare di mostrare 0,0 troppo presto.
        var tenths = (milliseconds + 99) / 100;
        return (tenths / 10).toString() + "," + (tenths % 10).toString();
    }

    private function formatElapsed(milliseconds) {
        var totalSeconds = milliseconds / 1000;
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds / 60) % 60;
        var seconds = totalSeconds % 60;

        if (hours > 0) {
            return hours.toString() + ":" + padTwo(minutes) + ":" + padTwo(seconds);
        }

        return padTwo(totalSeconds / 60) + ":" + padTwo(seconds);
    }

    private function formatSessionDuration() {
        if (_sessionDurationMs <= 0) {
            return _unlimitedText;
        }

        return (_sessionDurationMs / 60000).toString() + " " + _minutesShortText;
    }

    private function padTwo(value) {
        return value < 10 ? "0" + value.toString() : value.toString();
    }

    private function loadLocalizedText() {
        _readyText = Ui.loadResource(Rez.Strings.Ready);
        _inhaleText = Ui.loadResource(Rez.Strings.Inhale);
        _exhaleText = Ui.loadResource(Rez.Strings.Exhale);
        _inhaleShortText = Ui.loadResource(Rez.Strings.InhaleShort);
        _exhaleShortText = Ui.loadResource(Rez.Strings.ExhaleShort);
        _activityNameText = Ui.loadResource(Rez.Strings.ActivityName);
        _sessionText = Ui.loadResource(Rez.Strings.SessionShort);
        _unlimitedText = Ui.loadResource(Rez.Strings.SessionUnlimitedShort);
        _minutesShortText = Ui.loadResource(Rez.Strings.MinutesShort);
        _menuHintText = Ui.loadResource(Rez.Strings.SessionMenuHint);
    }

    private function updatePhaseCues(elapsed) {
        var cycleElapsed = elapsed % (_inhaleMs + _exhaleMs);
        var isInhaling = cycleElapsed < _inhaleMs;

        if (isInhaling == _lastPhaseIsInhaling) {
            return;
        }

        if (_vibrationMode != VIBRATION_OFF
                && (_vibrationMode == VIBRATION_EVERY_PHASE
                || (_vibrationMode == VIBRATION_EVERY_CYCLE && isInhaling))) {
            playPhaseVibration(isInhaling);
        }

        if (_soundMode != SOUND_OFF
                && (_soundMode == SOUND_EVERY_PHASE
                || (_soundMode == SOUND_EVERY_CYCLE && isInhaling))) {
            playPhaseTone();
        }

        _lastPhaseIsInhaling = isInhaling;
    }

    private function playPhaseVibration(isInhaling) {
        if (isInhaling) {
            Attention.vibrate([
                new Attention.VibeProfile(
                    VIBRATION_STRENGTH,
                    VIBRATION_INHALE_MS
                )
            ]);
            return;
        }

        Attention.vibrate([
            new Attention.VibeProfile(
                VIBRATION_STRENGTH,
                VIBRATION_EXHALE_MS
            ),
            new Attention.VibeProfile(0, VIBRATION_PAUSE_MS),
            new Attention.VibeProfile(
                VIBRATION_STRENGTH,
                VIBRATION_EXHALE_MS
            )
        ]);
    }

    private function playPhaseTone() {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_KEY);
        }
    }

    private function playCompletionCues() {
        if (_vibrationMode != VIBRATION_OFF) {
            Attention.vibrate([
                new Attention.VibeProfile(
                    VIBRATION_STRENGTH,
                    VIBRATION_COMPLETE_MS
                )
            ]);
        }

        if (_soundMode != SOUND_OFF && Attention has :playTone) {
            Attention.playTone(Attention.TONE_SUCCESS);
        }
    }

    private function getPhaseColor(isInhaling) {
        if (isInhaling) {
            return _circleColor;
        }

        return applyBrightness(_circleColor, EXHALE_BRIGHTNESS_PERCENT);
    }

    private function applyBrightness(color, brightnessPercent) {
        var red = ((color >> 16) & 0xff) * brightnessPercent / 100;
        var green = ((color >> 8) & 0xff) * brightnessPercent / 100;
        var blue = (color & 0xff) * brightnessPercent / 100;
        return (red << 16) | (green << 8) | blue;
    }

    private function startRecording() {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        _recordingSession = ActivityRecording.createSession({
            :name => _activityNameText,
            :sport => Activity.SPORT_GENERIC,
            :subSport => Activity.SUB_SPORT_GENERIC
        });
        _recordingStarted = _recordingSession.start();
    }

    private function stopRecordingForDecision() {
        if (_recordingSession != null) {
            if (_recordingSession.isRecording()) {
                _recordingSession.stop();
            }
        }

        disableSessionSensors();
    }

    private function finalizeRecording(shouldSave) {
        if (_recordingSession != null) {
            if (_recordingSession.isRecording()) {
                _recordingSession.stop();
            }

            if (shouldSave && _recordingStarted) {
                _recordingSession.save();
            } else {
                _recordingSession.discard();
            }

            _recordingSession = null;
            _recordingStarted = false;
        }

        disableSessionSensors();
    }

    private function disableSessionSensors() {
        Sensor.setEnabledSensors([]);
    }

    private function getContrastColor(color) {
        var red = (color >> 16) & 0xff;
        var green = (color >> 8) & 0xff;
        var blue = color & 0xff;
        var brightness = (red * 299) + (green * 587) + (blue * 114);
        return brightness >= 128000 ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE;
    }
}
