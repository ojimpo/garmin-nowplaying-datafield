import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class NowPlayingView extends WatchUi.DataField {
    private var _source as DemoSource;

    function initialize() {
        DataField.initialize();
        // onUpdate may run before compute, so initialize the source here.
        _source = new DemoSource(System.getTimer());
    }

    function compute(info as Activity.Info) as Void {
        var selectedSample = Application.Properties.getValue("demoSample");
        var sample = 0;
        if (selectedSample instanceof Number) {
            sample = selectedSample;
        }
        _source.tick(System.getTimer(), sample);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var background = getBackgroundColor();
        var foreground = Graphics.COLOR_BLACK;
        if (background == Graphics.COLOR_BLACK) {
            foreground = Graphics.COLOR_WHITE;
        }
        dc.setColor(foreground, background);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var padding = 4;
        var availableWidth = width - 2 * padding;
        var titleFont = Graphics.FONT_MEDIUM;
        var artistFont = Graphics.FONT_XTINY;
        var gap = 2;
        var titleHeight = dc.getFontHeight(titleFont);
        var artistHeight = dc.getFontHeight(artistFont);

        if (titleHeight + artistHeight + gap > height - 4) {
            titleFont = Graphics.FONT_SMALL;
            titleHeight = dc.getFontHeight(titleFont);
        }
        if (titleHeight + artistHeight + gap > height - 4) {
            titleFont = Graphics.FONT_XTINY;
            titleHeight = dc.getFontHeight(titleFont);
        }

        // A one-line fallback prevents overlapping text in very short slots.
        if (titleHeight + artistHeight + gap > height - 4) {
            if (height < artistHeight || availableWidth <= 0) {
                return;
            }
            var combined = "DEMO: " + _source.title();
            dc.drawText(width / 2, (height - artistHeight) / 2, artistFont,
                TextFit.ellipsize(dc, combined, artistFont, availableWidth),
                Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var top = ((height - titleHeight - artistHeight - gap) / 2).toNumber();
        dc.drawText(width / 2, top, titleFont,
            TextFit.ellipsize(dc, _source.title(), titleFont, availableWidth),
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, top + titleHeight + gap, artistFont,
            TextFit.ellipsize(dc, _source.artist(), artistFont, availableWidth),
            Graphics.TEXT_JUSTIFY_CENTER);
    }
}
