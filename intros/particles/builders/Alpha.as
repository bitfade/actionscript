/*

	Particles builder: Alpha

*/
package bitfade.intros.particles.builders {

	public class Alpha {
	
		import flash.display.*
		import flash.geom.*
	
		import bitfade.easing.*
			
			
		public static function build(minPSize:uint = 2,maxPSize:uint = 64,pRangeMax:uint = 32,maxAlpha:Number = 1,solid:Boolean = false,color:uint = 0):Vector.<BitmapData> {
		
			var half:uint = pRangeMax >> 1
  			
  			var pGfx:Vector.<BitmapData> = new Vector.<BitmapData>(pRangeMax+1,true)
  		
  			var circle:Shape = new Shape();
			var cg:Graphics = circle.graphics
			
			
			var gradM = new Matrix();
			var ps:uint
			
			var alpha:Number = 0
			
			var ratio:Number
			
			for (var idx:uint = 0;idx<=pRangeMax;idx++) {
  			
				ps = uint(bitfade.easing.Cubic.In(idx,minPSize,maxPSize-minPSize,pRangeMax))
				
				pGfx[idx] = new BitmapData(ps,ps,true,0x000000);
				
				gradM.createGradientBox(ps,ps,0,0,0);
				
				if (idx < half) {
					alpha = 0.3+0.7*(idx/half)
				} else {
					alpha = 0.1+0.9*(pRangeMax-idx)/half
				}
				
				
				alpha *= maxAlpha
				ratio = uint(bitfade.easing.Quad.Out(idx,255,-254,pRangeMax))
				
				if (solid) ratio = 255
				
				cg.clear()
				cg.lineStyle(1,0,0);
				cg.beginGradientFill(
					GradientType.RADIAL, 
					[color,color,color], 
					[alpha,alpha,0],
					[0,ratio,255], 
					gradM, 
					SpreadMethod.PAD
				);
				cg.drawCircle(ps/2,ps/2,ps/2)
				cg.endFill()
			
				
				pGfx[idx].draw(circle,null,null,null,pGfx[idx].rect)
				
			}
			
			return pGfx
		
		
		}
	}

}