/*

	This class creates a slider control with a draggable button 

*/
package bitfade.ui.sliders { 
	import flash.display.*
	import flash.events.*
	import flash.geom.*
	
	import bitfade.core.*
	import bitfade.ui.Empty
	import bitfade.ui.frames.Shape
	import bitfade.ui.text.TextField
	
	import bitfade.utils.*
	import bitfade.easing.*
	
	public class Index extends Sprite implements bitfade.core.IResizable {
		
		// default colors
		private static var styles:Object = {
			dark: 	[0x202020,0x252525,0x202020],
			light: 	[0xD0D0D0,0xE0E0E0,0xD0D0D0]
		}
		
		public static var conf:Object
		
		protected var back:flash.display.Shape
		protected var cursor:Sprite
		protected var caption:bitfade.ui.text.TextField
		
		protected var dragArea:bitfade.ui.Empty
		
		protected var seekCallBack:Function
		
		protected var textStyle:String
		
		// dimentions
		protected var w:uint
		protected var tw:uint
		protected var h:uint
		
		protected var seeking:Boolean = false
		protected var mouseOver:Boolean = false
		
		protected var autoHide:Number
		
		protected var cursorTw:bitfade.utils.Tw
		protected var alphaTw:bitfade.utils.Tw
		
		// constructor
		public function Index(w:uint,h:uint,tw:uint,textStyle:String,seekCallBack:Function,autoHide:Number = 1) {
			super();
			this.w = w
			this.h = h
			this.tw = tw
			this.textStyle = textStyle
			this.seekCallBack = seekCallBack
			this.autoHide = autoHide
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
  		
  		// resize layout
  		public function resize(nw:uint = 0,nh:uint = 0):void {
  			w = back.width = nw
  			dragArea.resize(w,h*7)
  			dragArea.y = -3*h
  		}
  		
  		// always return 16 as height
  		override public function get height():Number {
  			return 16
  		}
  		
  		// create the slider
  		public function init():void {
  			
  			if (!conf) setStyle()
  			
  			alpha=0
  			buttonMode = true
  			
  			var mat:Matrix = new Matrix()
			
			mat.createGradientBox(w,h, Math.PI/2,0,0);
  			
  			var colors:Array = conf.colors
  			
  			back = new flash.display.Shape();
  			var dg:Graphics = back.graphics
 
  			dg.beginGradientFill(GradientType.LINEAR, [colors[0],colors[1],colors[1],colors[2]], [1,1,1,1], [0,64,255-64,255], mat);
			dg.drawRect(0,0,w,h)
			dg.endFill()
  			
  			addChild(back)
  			
  			cursor = new Sprite();
			
			bitfade.ui.frames.Shape.create("default."+conf.style,50,16,0,0,null,cursor.graphics)
			
			caption = new bitfade.ui.text.TextField({
				styleSheet:	textStyle,
				width: 		tw,
				//thickness:	-100,
				thickness: 150,
				sharpness: -100,
				mouseEnabled: false
			})
			
			cursor.addChild(caption)
			cursor.blendMode = conf.style == "dark" ? "add" : "overlay"
			cursor.mouseEnabled = false
			addChild(cursor)
  			
  			back.y = int((height-h)/2)
  			
  			cursorTw = bitfade.utils.Tw.to(cursor,0.5,null,{ease:Quad.Out})
  			alphaTw = bitfade.utils.Tw.to(this,0.5,null,{ease:Quad.Out,delay:100})
			
			dragArea = new Empty(w,h*3)
			dragArea.mouseEnabled = false
			dragArea.y = -3*h
			addChild(dragArea)
			
			bitfade.utils.Events.add(this,[
				MouseEvent.MOUSE_OVER,
				MouseEvent.MOUSE_OUT,
				MouseEvent.MOUSE_UP,
				MouseEvent.MOUSE_DOWN,
				MouseEvent.MOUSE_MOVE
			],evHandler)
  		}
  		
  		// set cursor text
  		public function content(msg:String,shw:Boolean = true) {
  			caption.content(msg)
  			caption.x = int((cursor.width-caption.width)/2)
  			if (shw) show()
  		}
  		
  		// hide scrollbar
  		public function hide(t:bitfade.utils.Tw = null) {
  			if (!mouseOver) show(false)
  		}
  		
  		// show scrollbar
  		public function show(sw:Boolean = true) {
  			if (sw) {
  				alphaTw.proxy.alpha = 1
	  			alphaTw.onComplete = hide
	  			alphaTw.delay = 0
  			} else {
  				if (alpha == 0) return
  				alphaTw.proxy.alpha =  0
  				alphaTw.onComplete = null
  				alphaTw.delay = autoHide

  			}
  		}
  		
  		// set cursor position
  		public function pos(p:Number,useTween:Boolean = true) {
  			var px:int = int(p*(w-cursor.width));
  			if (useTween) {
  				cursorTw.proxy.x = px
  			} else {
  				cursor.x = px
  			}
  		}
  		
  		// seek to click or drag cursor
  		protected function seek(p:Number,over:Boolean = true) {
  			cursor.blendMode = over ? "normal" : (conf.style == "dark" ? "add" : "overlay")
  			dragArea.visible = seeking = over
  			p = p/w
  			if (seeking) {
  				if (alpha < 1) {
  					alphaTw.proxy.alpha = alpha =1
  				}
  				cursor.x = Math.min(Math.max(0,p*w-int(cursor.width/2)),w-cursor.width)
  				seekCallBack(p)
  			} else {
  			}
  		}
  		
  		// handles all events
  		protected function evHandler(e:MouseEvent) {
  			e.stopPropagation()
  			switch (e.type) {
  				case MouseEvent.MOUSE_UP:
  				case MouseEvent.MOUSE_DOWN:
  					seek(e.localX,e.type == MouseEvent.MOUSE_DOWN)
  				break;
  				case MouseEvent.MOUSE_OVER:
  				case MouseEvent.MOUSE_OUT:
  					mouseOver = (e.type == MouseEvent.MOUSE_OVER)
  					show(mouseOver)  				
  					if (!mouseOver) seek(0,false)
  				break
  				case MouseEvent.MOUSE_MOVE:
  					if (seeking) seek(e.localX)
  				break
  			}
  		}
  		
	}
}
/* commentsOK */