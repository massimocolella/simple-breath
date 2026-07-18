using Toybox.WatchUi as Ui;

class RespiroSessionDurationMenuDelegate extends Ui.Menu2InputDelegate {
    private var _view;

    function initialize(view) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item) {
        _view.setSessionDurationMinutes(item.getId());
        Ui.popView(Ui.SLIDE_DOWN);
    }
}
