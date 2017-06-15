/*
	this util function for textfield
*/
package bitfade.utils { 

	import flash.text.*
	import flash.utils.Dictionary	

	public class Text {
		
		// set embedFonts = true when each fonts defined in stylesheet (or textFormat) is embedded
		public static function setEmbedded(t:TextField) {
			
			var reqFonts:Dictionary = new Dictionary(true)
			var installedFonts:Dictionary = getInstalledFonts()
			var fontFamily:String
			
			if (t.styleSheet) {
				for each (var style:String in t.styleSheet.styleNames) {
					fontFamily = t.styleSheet.getStyle(style).fontFamily
					if (fontFamily) reqFonts[fontFamily] = true
				}
			} else if (t.defaultTextFormat) {
				reqFonts[t.defaultTextFormat.font] = true
			}
			
			t.embedFonts = true
			for (fontFamily in reqFonts) {
				if (!installedFonts[fontFamily]) {
					t.embedFonts = false
					break;
				}
			}
			t.antiAliasType = t.embedFonts ? flash.text.AntiAliasType.ADVANCED : flash.text.AntiAliasType.NORMAL			
		}
		
		// get a list of installed (embedded) fonts
		public static function getInstalledFonts():Dictionary {
			var installedFonts:Dictionary = new Dictionary(true) 
			
			// this snippet will autodetect embedded fonts
			var fontList:Array = Font.enumerateFonts(false);
			for (var i:uint=0; i<fontList.length; i++) {
				installedFonts[fontList[i].fontName] = true
			}
			
			return installedFonts
		}
 		
	}
}
/* commentsOK */