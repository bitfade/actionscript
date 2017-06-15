/*

	This class creates various icon controls

*/
package bitfade.ui.icons {
 
	import flash.display.*
	import flash.filters.*
	import flash.geom.*
	
	import bitfade.ui.core.*
	import bitfade.utils.*
	
	public class BevelGlow extends Sprite implements bitfade.ui.core.IMouseOver {
	
		// hilight color
		public static var conf:Object
		
		private static var styles:Object = {
			dark: [0xC0C0C0,0xFF9832],
			light: [0x303030,0x337CFE]
			//0x284FB1
			//0x911913
		}
		
		// some bitmaps needed
		protected var bMap:Bitmap
		protected var bNormal:BitmapData
		protected var bOver:BitmapData
		
		// constructor
		public function BevelGlow(id:String,type:String,size:uint = 16,w:uint = 16) {
			super();
			init(id,type,size,w)
  		}
  		
  		// this is used to set icon style / colors
  		public static function setStyle(s:String = "dark",c:Array = null):void {
  			if (!styles[s]) s = "dark"
  			if (!conf) conf = { colors:[] }
  			conf.style = s
  			
  			if (!c) {
  				conf.colors = styles[s]
  			} else {
	  			conf.colors[0] = c[0] >= 0 ? c[0] : styles[s][0]
				conf.colors[1] = c[1] >= 0 ? c[1] : styles[s][1]
  			}
  			
  		}
  		
  		// show hilighted version when mouse is over
  		public function over(mouseHover:Boolean):void {
  			bMap.bitmapData = mouseHover ? bOver : bNormal 
  		}
  		
  		// create the icon
  		public function init(id:String,type:String,size:uint,w:uint):void {
  			if (!conf) setStyle()
  			
  			
  			bNormal = Snapshot.take(bitfade.ui.icons.Shape.create(type,size,w,conf.colors[0]))
  					
			applyStyle()
			addBitmap(id)
  		}
  		
  		protected function addBitmap(id:String) {

			// set some values
  			buttonMode = true
  			name = id
  			
			// add the bitmap
			bMap = new Bitmap(bNormal) 
			addChild(bMap)
  		}
  		
  		protected function applyStyle() {
  			var origin:Point = new Point()
			var box:Rectangle = bNormal.rect
			
			var bTmp:BitmapData = bNormal.clone();
			
			// draw the non highlighted version
			//bNormal.draw(sp,null,null,null,null,true)
			
			if (conf.style == "dark") {
				bNormal.applyFilter(bNormal,box,origin,new BevelFilter(1,45,0xFFFFFF,1,0x202020, 0.5,1,1,1,3,"inner"))
				bNormal.applyFilter(bNormal,box,origin,new GlowFilter(0, 1,2,2,1,2,false))
				bOver = bNormal.clone();
				// draw the highlighted version
				bTmp.fillRect(box,(0xFF << 24) + conf.colors[1])
				bTmp.copyPixels(bTmp,box,origin,bNormal,origin)
				if (conf.style == "dark") bTmp.applyFilter(bTmp,box,origin,new BlurFilter(2,2,2))
				bOver.draw(bTmp,null,null,conf.style == "dark" ? "add" : "add")
			} else {
				bOver = bNormal.clone();
				bTmp.fillRect(box,(0xFF << 24) + conf.colors[1])
				bOver.copyPixels(bTmp,box,origin,bNormal,origin)
				
				for each (var b:BitmapData in [bOver,bNormal]) {
					b.applyFilter(b,box,origin,new BevelFilter(1,45,0xA0A0A0,1,0x202020, 0.2,1,1,1,3,"inner"))
					b.applyFilter(b,box,origin,new GlowFilter(0xFFFFFF, 1,2,2,1,2,false))			
				}
								
			}
			
			bTmp.dispose()
  		}
  		
	}
}
/* commentsOK */