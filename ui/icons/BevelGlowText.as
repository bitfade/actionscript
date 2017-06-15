/*

	This class creates various text icon controls

*/
package bitfade.ui.icons {
 
 	import flash.text.*
	import flash.display.*
	import flash.geom.*
	
	import bitfade.ui.icons.BevelGlow
	import bitfade.ui.frames.*
	import bitfade.ui.text.TextField
	import bitfade.utils.*
			
	
	public class BevelGlowText extends bitfade.ui.icons.BevelGlow {
	
		protected var background:Boolean;
	
		// constructor
		public function BevelGlowText(id:String,type:String,size:uint = 16,w:uint = 32,background:Boolean = true) {
			this.background = background
			super(id,type,size,w)
  		}
  		
  		public static function setStyle(s:String = "dark",c:Array = null):void {
  			bitfade.ui.icons.BevelGlow.setStyle(s,c)
  		}
  		
  		// create the icon
  		override public function init(id:String,type:String,size:uint,w:uint):void {
  		
  			if (!bitfade.ui.icons.BevelGlow.conf) bitfade.ui.icons.BevelGlow.setStyle()
  			
  			var caption = new bitfade.ui.text.TextField({
				defaultTextFormat: new TextFormat("PF Tempesta Seven Condensed_8pt_st",8,conf.colors[0],false),
				maxWidth: w
			})
				
			// set text
			caption.content(type)
			
			// take a bitmap snapshot
			bOver = Snapshot.take(caption,null,w,size)
			bNormal = bOver.clone()
			
			// get the alpha>0 region
			var area:Rectangle = Crop.area(bOver)
			
			bNormal.fillRect(bNormal.rect,0)
			// center the text
			bNormal.copyPixels(bOver,area,new Point((w-area.width) >> 1,(size-area.height) >> 1))
			
			bOver.dispose()
			
			applyStyle()
			addBitmap(id)
			
			
			var bTmp:BitmapData = bNormal.clone()
			
			var bTmpMap:Bitmap = new Bitmap(bTmp)
			
			var sp:Sprite = new Sprite()
			
			if (background) sp.addChild(bitfade.ui.frames.Shape.create("default."+bitfade.ui.icons.BevelGlow.conf.style,w,size,0,0,null,null,0))
			sp.addChild(bTmpMap)
			if (background) sp.addChild(bitfade.ui.frames.Gloss.create(w,size))
			
			bNormal.fillRect(bNormal.rect,0)
			bNormal.draw(sp)
			
			bTmp.copyPixels(bOver,bOver.rect,Geom.origin)
			
			bOver.draw(sp)
			
	
  		}
  		
	}
}
/* commentsOK */