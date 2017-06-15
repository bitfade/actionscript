/*
	
	Extend textfield with some defaults and usefoul methods

*/
package bitfade.ui.text { 

	import flash.text.*
	import bitfade.utils.*
		
	public class TextField extends flash.text.TextField {
		
		
		protected static const noFilters:Array = []
		
		protected static var defaults:Object = {
			selectable: false,
			multiline: true,
			wordWrap: true,
			condenseWhite: true,
			autoSize: TextFieldAutoSize.LEFT
			//autoSize: TextFieldAutoSize.NONE
		}
		
		public var realFilters:Array
		
		public var maxWidth:uint = 0
		public var maxHeight:uint = 0
		
		public function TextField(conf:Object = null) {
			super()
			init(conf)
		}
		
		public function init(conf:Object = null) {
			var p:String
			
			if (conf["styleSheet"] is String) {
			
				var sheet = new StyleSheet();
				sheet.parseCSS(conf["styleSheet"])
				conf["styleSheet"] = sheet
			}
			
			if (conf.filters) { 
				realFilters = conf.filters
			}
			
			for (p in defaults) this[p] = defaults[p]
			for (p in conf) this[p] = conf[p]
			
			if (!maxWidth) {
				maxWidth = width
			} 
			
			bitfade.utils.Text.setEmbedded(this)
		}
		
		
		// set TextField Content
		public function content(msg:String):void {
			
			// new
			autoSize = TextFieldAutoSize.LEFT
			
			if (msg == null) {
				msg = htmlText ? htmlText : ""
			} 
			
			width = maxWidth
			wordWrap = false
			
			/*
				[rant]
				
				this *CRAP* is needed to fix a FP9 bug which prevents text display
				if a filters are used with empty content..
			
				[/rant]
			*/
			filters = msg == "" ? noFilters : realFilters
			
			htmlText = msg
			
			if (textWidth > maxWidth) {
				wordWrap = true
				htmlText = msg
			}
			width = int(textWidth+5)
			
			autoSize = TextFieldAutoSize.NONE
			
			if (maxHeight > 0) height = maxHeight
			
		}
		 		
	}
}
/* commentsOK */