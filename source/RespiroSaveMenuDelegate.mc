using Toybox.WatchUi as Ui;

class RespiroSaveMenuDelegate extends Ui.Menu2InputDelegate {
    private var _view;

    function initialize(view) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item) {
        _view.resolveSaveDecision(item.getId() == 1);
        Ui.popView(Ui.SLIDE_DOWN);
    }

    function onBack() {
        // A session must be explicitly saved or discarded.
    }
}
