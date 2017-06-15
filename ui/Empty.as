/*

	This class create and empty Sprite with defined size

*/
package bitfade.ui { 
	import flash.display.*
	import flash.geom.*
	
	public class Empty extends Sprite {
		
		public var color:int = 0
		
		// constructor
		public function Empty(w:uint,h:uint,v:Boolean = false,c:int = -1) {
			super();
			init(v,c,w,h)
			resize(w,h)
  		}
  		
  		// set values
  		public function init(v:Boolean,c:int,w:uint,h:uint):void {
  			visible = v
  			color = c
  			buttonMode = true
  			
  			graphics.clear()
  			graphics.beginFill(color >= 0 ? color : 0,color >= 0 ? 1 : 0)
  			graphics.drawRect(0,0,w,h)
  			graphics.endFill()
  						
  		}
  		
  		// resize the sprite
  		public function resize(w:uint,h:uint):void {
  			width = w
  			height = h
  			/*
  			graphics.clear()
  			color = 0xFF0000
  			graphics.beginFill(color >= 0 ? color : 0,color >= 0 ? .3 : 0)
  			graphics.drawRect(0,0,w,h)
  			*/
  		}
  		
	}
}
/* commentsOK */