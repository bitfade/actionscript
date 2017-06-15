package bitfade.ui { 
	import flash.display.*
	import flash.events.*
	import flash.geom.*
	import bitfade.ui.noAAText
	
	public class button extends Sprite {
		public var label:noAAText
		public var hover:Shape;
		
		public function button(id,txt,w,h,xp,yp,evHandler=null,gradColor =  0x404040,hoverColor = 0x606060) {
		
			name = id
		
			label = new noAAText(txt,w,16,0,Math.max(h-17,0))
			
			var gradM = new Matrix();	
			
			gradM.createGradientBox(w,h, Math.PI/2, 0, 0);
			
			
			with (graphics) {
				beginGradientFill(
					GradientType.LINEAR, 
					[gradColor,0x101010], 
					[1, 1], 
					[0, 255], 
					gradM, 
					SpreadMethod.PAD
				);
				  
				drawRect(0, 0,w,h);
				endFill()
				lineStyle(1,0x303030,1)
				moveTo(0,h)
				lineTo(w,h)
				lineTo(w,0)
				lineStyle(1,0x606060,1)
				lineTo(0,0)
				lineTo(0,h)
			}
			
			hover = new Shape();
			hover.visible = false;
			
			with (hover.graphics) {
				beginGradientFill(
					GradientType.LINEAR, 
					[hoverColor,0x101010], 
					[1, 1], 
					[0, 255], 
					gradM, 
					SpreadMethod.PAD
				);
				  
				drawRect(1, 1,w-2,h-2);
				endFill()
			}
		
			addChild(hover)
		
			addChild(label)
  			
  			x = xp
  			y = yp
  			
  			if (evHandler) {
  				addEventListener(MouseEvent.CLICK,evHandler)
  				addEventListener(MouseEvent.ROLL_OVER,evHandler)
  				addEventListener(MouseEvent.ROLL_OUT,evHandler)
  				buttonMode = true
  			}
  		}
  		
  		public function msg(txt) {
  			label.htmlText = txt
  		}
	}
}