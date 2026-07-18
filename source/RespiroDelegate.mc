using Toybox.WatchUi as Ui;

class RespiroDelegate extends Ui.BehaviorDelegate {
    private var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Sul Forerunner 245 il comportamento Select corrisponde al tasto START/ENTER.
    function onSelect() {
        _view.toggle();
        return true;
    }

    function onBack() {
        _view.stop();
        return false;
    }
}
