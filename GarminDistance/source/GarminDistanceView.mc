using Toybox.WatchUi;

class GarminDistanceViewBehaviorDelegate extends WatchUi.BehaviorDelegate {

    hidden var distanceView;

    function initialize(dv) {
        BehaviorDelegate.initialize();
        distanceView = dv;
    }

    function onSelect() {
        distanceView.updateDistance();
        return true;
    }
}

class GarminDistanceView extends WatchUi.View {

    hidden var distance;

    function initialize() {
        View.initialize();
        distance = 0;
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {        
    }

    function updateDistance() {
        distance = distance + 1;
        WatchUi.requestUpdate();
    }

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // Set our distance text
        var distanceText = View.findDrawableById("distanceText");
        distanceText.setText(distance.toString());
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
