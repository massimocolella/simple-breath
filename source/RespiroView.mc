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
    private const MIN_RADIUS = 24;
    private const MAX_RADIUS = 82;

    private var _frameTimer;
    private var _recordingSession;
    private var _recordingStarted = false;
    private var _isRunning = false;
    private var _startedAtMs = 0;
    private var _lastBacklightAtMs = 0;
    private var _inhaleMs = DEFAULT_PHASE_MS;
    private var _exhaleMs = DEFAULT_PHASE_MS;
    private var _circleColor = Gfx.COLOR_BLUE;

    function initialize() {
        View.initialize();
        _frameTimer = new Timer.Timer();
        reloadSettings();
    }

    function onShow() {
        reloadSettings();
    }

    function onHide() {
        if (_isRunning) {
            _frameTimer.stop();
            _isRunning = false;
            stopRecordingAndSave();
        } else {
            disableSessionSensors();
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

        // Una modifica delle durate fa ripartire il ritmo dall'inspirazione.
        if (_isRunning) {
            _startedAtMs = Sys.getTimer();
        }
    }

    function toggle() {
        if (_isRunning) {
            stop();
        } else {
            start();
        }
    }

    function start() {
        if (_isRunning) {
            return;
        }

        reloadSettings();
        startRecording();
        _startedAtMs = Sys.getTimer();
        _lastBacklightAtMs = _startedAtMs;
        _isRunning = true;
        Attention.backlight(true);
        _frameTimer.start(method(:onFrame), FRAME_INTERVAL_MS, true);
        Ui.requestUpdate();
    }

    function stop() {
        if (!_isRunning) {
            return;
        }

        _frameTimer.stop();
        _isRunning = false;
        stopRecordingAndSave();
        Ui.requestUpdate();
    }

    function onFrame() {
        if (_isRunning) {
            var now = Sys.getTimer();
            var sinceBacklightRefresh = now - _lastBacklightAtMs;

            if (sinceBacklightRefresh < 0
                    || sinceBacklightRefresh >= BACKLIGHT_REFRESH_MS) {
                Attention.backlight(true);
                _lastBacklightAtMs = now;
            }
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
        var centerY = dc.getHeight() / 2 + 8;

        drawCenteredText(dc, 30, Gfx.FONT_XTINY, "RESPIRO", Gfx.COLOR_LT_GRAY);

        dc.setColor(_circleColor, Gfx.COLOR_BLACK);
        dc.fillCircle(centerX, centerY, 48);
        drawCenteredText(
            dc,
            centerY,
            Gfx.FONT_SMALL,
            "PRONTO",
            getContrastColor(_circleColor)
        );

        var phaseSummary = "IN " + formatDuration(_inhaleMs)
            + "  OUT " + formatDuration(_exhaleMs);
        drawCenteredText(dc, 193, Gfx.FONT_XTINY, phaseSummary, Gfx.COLOR_LT_GRAY);
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
        var radius = MIN_RADIUS
            + ((MAX_RADIUS - MIN_RADIUS) * radiusProgress).toNumber();
        var remainingMs = phaseDuration - phaseElapsed;
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2 + 8;
        var phaseName = isInhaling ? "INSPIRA" : "ESPIRA";
        var sessionStatus = phaseName + "  " + formatElapsed(elapsed);

        drawCenteredText(dc, 28, Gfx.FONT_XTINY, sessionStatus, Gfx.COLOR_WHITE);

        dc.setColor(_circleColor, Gfx.COLOR_BLACK);
        dc.fillCircle(centerX, centerY, radius);
        drawCenteredText(
            dc,
            centerY,
            Gfx.FONT_SMALL,
            formatRemaining(remainingMs),
            getContrastColor(_circleColor)
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

    private function secondsToMilliseconds(value, fallback) {
        if (value == null) {
            return fallback;
        }

        var milliseconds = (value * 1000).toNumber();
        return milliseconds > 0 ? milliseconds : fallback;
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

    private function padTwo(value) {
        return value < 10 ? "0" + value.toString() : value.toString();
    }

    private function startRecording() {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        _recordingSession = ActivityRecording.createSession({
            :name => "Respiro",
            :sport => Activity.SPORT_GENERIC,
            :subSport => Activity.SUB_SPORT_GENERIC
        });
        _recordingStarted = _recordingSession.start();
    }

    private function stopRecordingAndSave() {
        if (_recordingSession != null) {
            if (_recordingSession.isRecording()) {
                _recordingSession.stop();
            }

            if (_recordingStarted) {
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
