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

    function onMenu() {
        if (_view.isRunning()) {
            return true;
        }

        var configuredMinutes = _view.getSessionDurationMinutes();
        var focus = 0;

        if (configuredMinutes == 5) {
            focus = 1;
        } else if (configuredMinutes == 10) {
            focus = 2;
        } else if (configuredMinutes == 15) {
            focus = 3;
        } else if (configuredMinutes == 20) {
            focus = 4;
        }

        var menu = new Ui.Menu2({
            :title => Rez.Strings.SessionDurationTitle,
            :focus => focus
        });
        menu.addItem(new Ui.MenuItem(
            Rez.Strings.SessionUnlimited,
            null,
            0,
            null
        ));
        menu.addItem(new Ui.MenuItem(
            Rez.Strings.Session5Minutes,
            null,
            5,
            null
        ));
        menu.addItem(new Ui.MenuItem(
            Rez.Strings.Session10Minutes,
            null,
            10,
            null
        ));
        menu.addItem(new Ui.MenuItem(
            Rez.Strings.Session15Minutes,
            null,
            15,
            null
        ));
        menu.addItem(new Ui.MenuItem(
            Rez.Strings.Session20Minutes,
            null,
            20,
            null
        ));

        Ui.pushView(
            menu,
            new RespiroSessionDurationMenuDelegate(_view),
            Ui.SLIDE_UP
        );
        return true;
    }

    function onNextPage() {
        return onMenu();
    }

    function onBack() {
        if (_view.isRunning()) {
            _view.stop();
            return true;
        }

        return false;
    }
}
