import Toybox.Graphics;
import Toybox.Lang;

module TextFit {
    // Measurement and drawing use the same font. ASCII dots also work on
    // devices whose built-in fonts lack a typographic ellipsis glyph.
    function ellipsize(dc as Graphics.Dc, text as String,
                       font as Graphics.FontType, width as Number) as String {
        if (width <= 0) {
            return "";
        }
        if (dc.getTextWidthInPixels(text, font) <= width) {
            return text;
        }
        var suffix = "...";
        if (dc.getTextWidthInPixels(suffix, font) > width) {
            return "";
        }
        var low = 0;
        var high = text.length();
        while (low < high) {
            var mid = ((low + high + 1) / 2).toNumber();
            var candidate = text.substring(0, mid) + suffix;
            if (dc.getTextWidthInPixels(candidate, font) <= width) {
                low = mid;
            } else {
                high = mid - 1;
            }
        }
        return text.substring(0, low) + suffix;
    }
}
