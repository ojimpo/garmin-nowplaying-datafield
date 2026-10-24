import Toybox.Lang;
import Toybox.Test;

(:test)
function demoTiming(logger as Test.Logger) as Boolean {
    var source = new DemoSource(1000);
    Test.assertEqual(source.title(), "Night Ride");
    source.tick(15999, 0);
    Test.assertEqual(source.title(), "Night Ride");
    source.tick(16000, 0);
    Test.assertEqual(source.title(), "A Very Long Track Title for a Long Evening Ride");
    source.tick(31000, 0);
    Test.assertEqual(source.title(), "夜のサイクリング");
    source.tick(76000, 0);
    Test.assertEqual(source.title(), "Night Ride");
    source.tick(0, 0);
    Test.assertEqual(source.title(), "Night Ride");
    return true;
}

(:test)
function fixedDemoSample(logger as Test.Logger) as Boolean {
    var source = new DemoSource(1000);
    source.tick(1000, 3);
    Test.assertEqual(source.title(), "夜のサイクリング");
    source.tick(90000, 3);
    Test.assertEqual(source.title(), "夜のサイクリング");
    source.tick(1000, 99);
    Test.assertEqual(source.title(), "Night Ride");
    return true;
}

(:test)
function textFitsSlot(logger as Test.Logger) as Boolean {
    // Use an off-screen bitmap with real device font metrics.
    var bitmap = new Toybox.Graphics.BufferedBitmap({:width => 246, :height => 80});
    var dc = bitmap.getDc();
    var font = Toybox.Graphics.FONT_XTINY;
    Test.assertEqual(TextFit.ellipsize(dc, "Ride", font, 238), "Ride");
    Test.assertEqual(TextFit.ellipsize(dc, "Ride", font, 0), "");
    Test.assertEqual(TextFit.ellipsize(dc, "Ride", font, 1), "");
    var result = TextFit.ellipsize(dc,
        "夜のサイクリングと長いアーティストの名前", font, 80);
    Test.assert(dc.getTextWidthInPixels(result, font) <= 80);
    Test.assert(result.length() > 0);
    return true;
}
