using Toybox.WatchUi;
using Toybox.Timer;

class GarminDistanceViewBehaviorDelegate extends WatchUi.BehaviorDelegate {

    hidden var distanceView;

    function initialize(dv) {
        BehaviorDelegate.initialize();
        distanceView = dv;
    }

    function onSelect() {
        distanceView.toggleGps();
        return true;
    }
}

class GarminDistanceView extends WatchUi.View {

    hidden var distance;
    hidden var status;
    hidden var gettingLoc;
    hidden var initialPosition;
    hidden var gpsIsOn;
    hidden var setStatusOffTextTimer;

    hidden var qualityText = {
        Position.QUALITY_NOT_AVAILABLE => "NO SIGNAL",
        Position.QUALITY_LAST_KNOWN => "LAST",
        Position.QUALITY_POOR => "POOR",
        Position.QUALITY_USABLE => "USABLE",
        Position.QUALITY_GOOD => "GOOD"
    };

    function initialize() {
        View.initialize();
        distance = 0;
        gettingLoc = false;
        gpsIsOn = false;
        status = "GPS off";
        setStatusOffTextTimer = new Timer.Timer();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        if (!gettingLoc) {
            gettingLoc = true;
            System.println("Getting initial position");
            var view = new WatchUi.ProgressBar("Waiting for GPS", null);
            WatchUi.pushView(view, null, WatchUi.SLIDE_IMMEDIATE);
            getInitialPosition();
        }      
    }

    function getInitialPosition() {
        Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method( :onInitialPosition ) );
    }

    function onInitialPosition(info) {
        if (info == null || info.accuracy == null) {
            System.println("Initial position null");
            getInitialPosition();
            return;
        }

        if (info.accuracy != Position.QUALITY_GOOD) {
            System.println("Invalid initial accuracy " + info.accuracy);
            getInitialPosition();
            return;
        }

        System.println( "Position " + info.position.toGeoString( Position.GEO_DM ) );
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        initialPosition = info;
    }

    function toggleGps() {
        if (initialPosition == null) {
            return;
        }
        
        if(gpsIsOn) {
            gpsIsOn = false;
            Position.enableLocationEvents(Position.LOCATION_DISABLE, method( :onPositionUpdate ) );

            // Seems to have issues if we don't delay this change
            // Probably from the last loc update
            setStatusOffTimed();
        } else {
            gpsIsOn = true;
            status = "GPS on";
            WatchUi.requestUpdate();
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method( :onPositionUpdate ) );            
        }
    }

    function setStatusOffTimed() {
        setStatusOffTextTimer.start(method( :setStatusOff ), 500, false);
    }
    
    function setStatusOff() {
        System.println("status off fired");
        status = "GPS off";
        WatchUi.requestUpdate();
    }

    function onPositionUpdate(updatedPosition) {
        if (updatedPosition == null || updatedPosition.accuracy == null) {
            System.println("Updated position null");
            return;
        }

        status = "GPS " + qualityText[updatedPosition.accuracy];

        System.println( "Updated position " + updatedPosition.position.toGeoString( Position.GEO_DM ) );

        var initPosRad = initialPosition.position.toRadians();
        var updatedPositionRad = updatedPosition.position.toRadians();

        distance = geodeticDistanceRad(initPosRad[0], initPosRad[1], updatedPositionRad[0], updatedPositionRad[1]).toNumber();
        WatchUi.requestUpdate();
    }

    function geodeticDistanceRad(lat1, lon1, lat2, lon2) {
        // Fancy distance formula from the internet
        var dy = (lat2-lat1);
        var dx = (lon2-lon1);

        var sy = Math.sin(dy / 2);
        sy *= sy;

        var sx = Math.sin(dx / 2);
        sx *= sx;

        var a = sy + Math.cos(lat1) * Math.cos(lat2) * sx;

        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

        var R = 6371000; // radius of earth in meters
        return R * c;
    }

    // Update the view
    function onUpdate(dc) {
        // Set our distance text
        var distanceText = View.findDrawableById("distanceText");
        distanceText.setText(distance + " ft");

        // Set our status text
        var statusText = View.findDrawableById("statusText");
        statusText.setText(status);

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
