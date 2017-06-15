/*

	This class is used draw background

*/
package bitfade.ui.backgrounds.engines { 
	
	import flash.geom.*
	import flash.display.*
	import flash.utils.*
	
	public class Engine {
	
		protected var mat:Matrix
		protected var sh:Shape
		protected var dg:Graphics
		protected var w:uint
		protected var h:uint
		protected var type:String
		protected var colors:Array
		
		protected function build(type:String,w:uint,h:uint,custom:Array = null):Shape {
			mat = new Matrix()
			sh = new Shape()
			dg = sh.graphics
			
			this.w = w
			this.h = h
			this.type = type
			
			var conf:Object = getDefinitionByName(getQualifiedClassName(this)).conf	
			
			if (!conf[type]) type = "dark"
  			
  			if (!custom) {
				colors = conf[type]
			} else {
				colors = conf[type].concat()
				for (var i:uint=0;i<custom.length;i++) {
					if (custom[i] >= 0 ) colors[i] = custom[i]
				}
			}
			
			draw()
			
			return sh
		}
		
		public function draw():void {}  		
	}
}
/* commentsOK */