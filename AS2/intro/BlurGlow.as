/*

	Motion blur light glow intro
	
*/
import flash.display.*
import flash.geom.*
import flash.filters.*

class bitfade.AS2.intro.blurGlow extends bitfade.AS2.intro.base {
	
	// default conf, look at example FLA for parameters
	public var conf:Object = {
		useLogoColors: false,
		glow: 80,
		persistence: 80,
		fadeInFrames: 10,
		glowFrames: 25,
		waitFrames: 25,
		fadeOutFrames: 25,
		mcControl: true,
		multipleInstances: false,
		loop: false
	};
	
	// some other bitmaps
	public var bColor:BitmapData;
	public var bMask:BitmapData;
	public var bBuffer2:BitmapData;
		
	// color transform 
	public var cT:ColorTransform
		
	// used to scale content
	public var refM:Matrix
	public var scaleIncr:Number
	public var scale:Number
		
	// default identity matrix and color transform
	public var idM:Matrix;
	public var defCT:ColorTransform;
		
	// drop shadow filter
	public var dsF;
	// blur filter
	public var bF;
	// bevel filter
	public var bevF;
	
	// light box variables
	public var lPos:Number;
	public var lIncr:Number;
	public var lRect:Rectangle;
	public var lP:Point
		
	public var countdown:Number
	
	public function blurGlow(opts:Object){
		super(opts)
	}
	
	// create an instance
	public static function create(canvas,opts) {
		opts.canvas = canvas
		return new blurGlow(opts)
	}
	
	// custom init
	public function customInit() {
		// create bitmapDatas
		bColor = bData.clone();
		bBuffer2 = bData.clone();
		bMask = bData.clone();
			
		// create drop shadow filter
		dsF = new DropShadowFilter(0,0,0,1,1,1,0.8,3,false,false,true)
			
		// create the blur filter
		bF = new BlurFilter(24,24,3)
			
		// create the bevel filter
		bevF = new BevelFilter(1,45,0xFFFFFF,1,0,1,1,1,1,3,"inner",false)
			
			
		// create the mask
		var sh:MovieClip = conf.canvas.createEmptyMovieClip("sh",-1)
		sh._visible = false;
			
		with (sh) {
			beginFill(0,100) 
			drawRect(40,40,w-80,h-80)
		}
			
		bMask.draw(sh)
		
		sh.removeMovieClip()
		
		bMask.applyFilter(bMask,box,origin,bF)
			
		// color transform
		cT = new ColorTransform(1,1,1,conf.persistence/100,0,0,0,0)
		defCT = new ColorTransform();
		
		// used to scale
		refM = new Matrix();
		idM = new Matrix(); 
				
		// stuff for light box
		lRect = new Rectangle(0,0,0,h)
		lP = new Point()
		
		var duration = 2*25
		
		// compute scaling speed 
		scale = 3
		scaleIncr = -2/(conf.fadeInFrames)
			
		// compute light glow box speed
		lIncr = (w+100)/(conf.glowFrames)
			
		// compute countdown to fade out
		countdown = conf.waitFrames;
			
		// render colored text
		renderColorItem()
	}
	
	// destructor
	public function destroy() {
		bColor.dispose();
		bMask.dispose();
		bBuffer2.dispose();
		super.destroy();
	}
	
	// this will render a colored version of item
	public function renderColorItem() {
			
		// clean up
		bColor.fillRect(box,0)
		bBuffer2.fillRect(box,0)
			
		// draw item
		if (conf.useLogoColors) {
			bBuffer2.copyPixels(bDraw,hitR,pt)
		} else {
		
			// some stuff needed
			var r = new Rectangle(0,0,w,1)
			var h:Number = hitR.height
			var h2:Number = h/2
			var ci:Number
			var minI:Number = 0x40
			var maxI:Number = 0xFF-minI
			
			// draw the color mask
			for (var yp:Number=0;yp<h;yp++) {
				r.y = yp
				ci = int((yp > h2) ? maxI*(h-yp)/h2 : maxI*yp/h2)+minI
				bBuffer.fillRect(r,colorMap[ci])
			}
				
			bBuffer2.copyPixels(bBuffer,hitR,pt,bDraw,origin)
		}
		
		// add glow, if used
		if (conf.glow) {
			
			dsF.blurX = dsF.blurY = 1
			dsF.strength = conf.glow/100
			dsF.quality = 3
			
			
			bColor.applyFilter(bBuffer2,box,origin,dsF)
			
			with (bF) {
				blurX = blurY = 8
				quality = 3
			}
				
			bColor.applyFilter(bColor,box,origin,bF)
			bColor.paletteMap(bColor,box,origin,null,null,null,colorMap)
		} 
			
		bBuffer.applyFilter(bBuffer2,box,origin,bevF)
			
		// final drawing step
		bColor.draw(bBuffer,idM,defCT,conf.glow ? "add" : "normal",box,true)
			
	}
	
	// effect routine		
	public function update() {
	
		switch (step) {
			// fade in
			case 0:
				bData.colorTransform(box,cT)
				
				// scale item
				refM.createBox(scale,scale,0,int(w*(1-scale)/2),int(h*(1-scale)/2))
					
				// clean
				bBuffer.fillRect(box,0)
			
				// compute colorTransform alpha
				var oldVal = cT.alphaMultiplier
				cT.alphaMultiplier = (3-scale)/4
				// draw scaled item
				bBuffer.draw(bColor,refM,cT,null,box,true)
				cT.alphaMultiplier = oldVal
				
				// compute blur amount
				with (bF) {
					blurX = int(8*scale)*2
					blurY = int(2*scale)*2
					quality = 1
				}
				
				// apply filter
				bBuffer2.applyFilter(bBuffer,box,origin,bF)
				//bData.copyPixels(bBuffer2,box,origin,bMask,origin,true)
				bData.copyPixels(bBuffer2,box,origin,null,null,true)
				scale += scaleIncr
				
				if (scale < 1) {
					// clean up
					bBuffer.fillRect(box,0)
					// next step
					step++;
					lPos = -100
				}
			break;
			
			// glow
			case 1:
			
				// fade out
				bData.colorTransform(box,cT)	
				bData.copyPixels(bColor,box,origin,null,null,true)
				bBuffer.colorTransform(box,cT)
					
				// starting x 
				lP.x = lRect.x = lPos > 0 ? int(lPos+.5) : 0 
				
				// box width
				lRect.width = int(((lPos < 0) ? lPos+lIncr : lIncr) + 0.5)
		
				bBuffer.copyPixels(bColor,lRect,lP,null,null,true)
					
				// set drop shadow filter
				with (dsF) {
					blurX = 32
					blurY = 2
					strength = 2
					quality = 1
				}
					
				
				// apply drop shadow
				bBuffer2.applyFilter(bBuffer,box,origin,dsF)
				// use our colormap
				bBuffer2.paletteMap(bBuffer2,box,origin,null,null,null,colorMap)
				bBuffer2.copyPixels(bBuffer2,box,origin,bColor,origin)
				
				// add the light glow box to drawed item
				bData.draw(bBuffer2,idM,defCT,"add")
					
				if (lPos < w) {
					lPos += lIncr
				} else {
					countdown = conf.waitFrames
					step++
				}
			break;
			// wait
			case 2:
			
				// fade out glow from previous step
				bData.colorTransform(box,cT)
				bData.copyPixels(bColor,box,origin,null,null,true)
				bBuffer2.colorTransform(box,cT)
				bData.draw(bBuffer2,idM,defCT,"add")
				
				// delay expired ?
				if (countdown > 0) {
					countdown--
				} else {
					// yes
					if (conf.fadeOutFrames == 0) {
						// if no fade out, go to previous step
						lPos = -100;
						step--
					} else {
						// otherways, go to next
						countdown = conf.fadeOutFrames
						// save last frame
						bBuffer.copyPixels(bData,box,origin)
						step++
					}
				}
			break;
			// fade out
			case 3:
				// prepare a mask
				bMask.fillRect(box,int((countdown/conf.fadeOutFrames)*0xFF) << 24)
				// use it to fade out
				bData.copyPixels(bBuffer,box,origin,bMask,origin,false)
				if (countdown > 0) {
					countdown--
				} else {
					step++
				}
			break;
			// destroy
			default:
				if (conf.loop) {
					// if loop, restart
					scale = 3
					step = 0
				} else {
					// otherways, self destruct
					destroy()
				}
		}
					
	}
		
}