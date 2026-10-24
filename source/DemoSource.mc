import Toybox.Lang;

// Fixed synthetic samples. No Spotify account or network access is used.
// Keep the data source independent of the view until a transport is proven.
class DemoSource {
    private var _samples as Array<Array<String>>;
    private var _startedAt as Number;
    private var _index as Number = 0;

    function initialize(startedAt as Number) {
        _startedAt = startedAt;
        _samples = [
            ["Night Ride", "DEMO - Sample Artist"],
            ["A Very Long Track Title for a Long Evening Ride", "DEMO - A Very Long Artist Name"],
            ["夜のサイクリング", "DEMO - サンプルアーティスト"],
            ["Paused", "DEMO - Playback paused"],
            ["No track", "DEMO - Nothing playing"]
        ];
    }

    function tick(now as Number) as Void {
        var elapsed = now - _startedAt;
        if (elapsed < 0) {
            // Recover if the device's millisecond counter wraps.
            _startedAt = now;
            elapsed = 0;
        }
        _index = ((elapsed / 15000).toNumber() % _samples.size());
    }

    function title() as String {
        return _samples[_index][0];
    }

    function artist() as String {
        return _samples[_index][1];
    }
}
