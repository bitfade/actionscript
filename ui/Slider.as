/*

	This class creates a control which has 2 bars
	Used to players seek or volume bars

*/
package bitfade.ui { 
	import flash.display.*
	import flash.events.*
	import flash.geom.*
	
	public class Slider extends Sprite {
		
		// default colors
		private static var styles:Object = {
			dark: [		
					// back
					0x606060,0x404040,0x606060,
					// bar1
					0xA0A0A0,0x707070,0xA0A0A0,
					// bar2
					0xFFFFCD,0xE9A663,0xFFFFCD					
			],
			
			light: [
				0x202020,0x707070,0x606060,
				0x202020,0x909090,0x606060,
				//0xC0A0A0,0x600000,0x911913
				0x202020,0x3B77E2,0x606060
			]
			
		}
		
		public static var conf:Object
		
		// some needed shapes
		private var back:Shape
		private var bar1:Shape
		private var bar2:Shape
		
		// dimentions
		private var w:uint
		private var h:uint
		private var bh:uint
		
		private var pos1:Number = 0
		private var pos2:Number = 0
		
		private var steps:uint
		
		public var startValue:Number = 0
		
		// constructor
		public function Slider(wv:uint,hv:uint,bhv:uint,stepsv:uint = 0) {
			w = wv
			h = hv
			bh = bhv
			steps = stepsv
			super();
			init()
  		}
  		
  		// this is used to set icon style / colors
  		public static function setStyle(s:String = "dark",c:Array = null):void {
  			if (!styles[s]) s = "dark"
  			if (!conf) conf = { colors:[] }
  			conf.style = s
  			
  			if (!c) {
  				conf.colors = styles[s]
  			} else {
  				var i:uint = styles["dark"].length
  				while (i--) {
  					conf.colors[i] = c[i] >= 0 ? c[i] : styles[s][i]
  				}
  			}
  			
  		}
  		
  		// create the slider
  		public function init():void {
  			
  			if (!conf) setStyle()
  			
  			buttonMode = true
  			
  			// draws a rect
  			with (graphics) {
  				beginFill(0,0)
  				drawRect(0,0,w,h)
  			}
  			
  			// draws the 2 bar using gradients
  			var mat:Matrix = new Matrix()
			
			mat.createGradientBox(w,bh, Math.PI/2,0,0);
  			
  			var colors:Array = conf.colors
  			var start:uint = 0;
  			
  			for each (var p:String in ["back","bar1","bar2"]) {
  				this[p] = new Shape();
  			
  				with (this[p].graphics) {
  					beginGradientFill(GradientType.LINEAR, [colors[start],colors[start+1],colors[start+2]], [1,1,1], [0,32,255], mat);
					drawRect(0,0,w,bh)
					endFill()
  				}
  				this[p].y = uint((h-bh)/2+.5)
  				addChild(this[p])
  				start += 3
  			}
  			
  			bar2.width = bar1.width = steps > 0 ? uint(.5+width/(steps)) : 0
  			
  		}
  		
  		public function start(value:Number) {
  			pos1 = pos2 = startValue = value
  			
  		}
  		
  		// set bars position
  		public function pos(p1:Number=-2,p2:Number=-2):void {
  			if (steps == 0) {
  			
  				//start = Math.max(0,Math.min(start,Math.min(p1,p2)))
  			
  				if (p1>=0) pos1 = p1
  				if (p2>=0) pos2 = p2
  				
  				bar1.width = uint(w*Math.abs(pos1-startValue)+.5)
  	  			
  	  			if (pos1<startValue) {
					bar1.x = uint(pos1*w+.5)
				} else {
					bar1.x = uint(startValue*w+.5)
				}
			
				bar2.width = uint(w*Math.abs(pos2-startValue)+.5)
				if (pos2<startValue) {
					bar2.x = uint(pos2*w+.5)
				} else {
					bar2.x = uint(startValue*w+.5)
				}
			
	  			
  			} else {
  				if (p1>=-1) {
  					if (p1 == -1) {
  						bar1.visible = false
  					} else {
  	 					bar1.visible = true
 	 					bar1.x = int(w*p1/steps+.5)
  					}
  				}
  				if (p2>=-1) {
  					if (p2 == -1) {
  						bar2.visible = false
  					} else {
  	 					bar2.visible = true
 	 					bar2.x = int(w*p2/steps+.5)
  					}
  				} 
  				
  			}
  		}
  		
	}
}
/* commentsOK */