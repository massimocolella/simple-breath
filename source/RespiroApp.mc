using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class RespiroApp extends App.AppBase {
    private var _view;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        _view = new RespiroView();
        return [ _view, new RespiroDelegate(_view) ];
    }

    function onSettingsChanged() {
        if (_view != null) {
            _view.reloadSettings();
            Ui.requestUpdate();
        }
    }
}
