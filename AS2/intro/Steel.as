import flash.display.*
import flash.geom.*
import flash.filters.*


class bitfade.AS2.intro.steel extends bitfade.AS2.intro.particles {
	
	// default conf, look at example FLA for parameters
	public var conf:Object = {
		useLogoColors: false,
		persistence: 30,
		fadeInFrames: 150,
		waitFrames: 50,
		fadeOutFrames: 25,
		mcControl: true,
		multipleInstances: false,
		loop: false
	};
	
	// some other bitmaps
	public var bColor:BitmapData;
	public var bBuffer2:BitmapData;
	public var bMask:BitmapData;
		
	// light box variables
	public var lPos:Number;
	public var lIncr:Number;
	public var lMin:Number;
	public var lMax:Number;
	public var lRect:Rectangle;
	public var lP:Point
		
	// some counters 
	public var countdown:Number = 0;
	public var pStart:Number = 0;
		
	// drop shadow filter
	public var dsF;
		
	// bevel filter
	public var bevF;
		
	// default identity matrix and color transform
	public var idM:Matrix;
	public var defCT:ColorTransform;
	
	public function steel(opts:Object){
		super(opts)		
	}
	
	public static function create(canvas,opts) {
		opts.canvas = canvas
		return new steel(opts)
	}
	
		
	public function customInit() {
		// call parent customInit
		super.customInit();
			
		// create bitmapDatas
		bColor = bData.clone();
		bBuffer2 = bData.clone();
		bMask = bData.clone();
		
		conf.canvas.blendMode = "add"
			
		// create drop shadow filter
		dsF = new DropShadowFilter(0,0,0,1,8,8,3,2,false,false,true)
		// create the bevel filter
		bevF = new BevelFilter(1,45,0xFFFFFF,1,0,1,1,1,1,3,"inner",false)
				
		// stuff for light box
		lRect = new Rectangle(0,0,0,h)
		lP = new Point()
						
		// default color trasform and matrix 
		defCT = new ColorTransform();
		idM = new Matrix(); 
		
		// let's compute some timings to respect transition duration
		lPos = pt.x
		lIncr = int((hitR.width)/conf.fadeInFrames)
		lMax = hitR.width+pt.x
		
		cT.alphaMultiplier = conf.persistence/100;
		
		renderColorItem()
	}	
	
	public function renderColorItem() {
		
		
		if (conf.useLogoColors) {
			bColor.copyPixels(bDraw,hitR,pt)
			return
		}
		
		// clean up
		bColor.fillRect(box,0)
			
		// use noise + blur for steel effect
		bBuffer2.noise(1,0,0xFF,7, true)
		bBuffer.applyFilter(bBuffer2,box,origin,new BlurFilter(64,2,2))
			
		// draw item (1st pass)
		bBuffer2.fillRect(box,0)
		bBuffer2.copyPixels(bBuffer,hitR,pt,bDraw,origin)
			
		// some stuff needed
		var hh:Number = hitR.height 
		var r = new Rectangle(0,0,w,1)
		var minI:Number = 0
		var maxI:Number = 0xFF
		var I:Number = minI
		var iI:Number = 0
		var step:Number = 4*(maxI - minI)/hh
			
		// draw the color mask
		for (var yp:Number=0;yp<hh;yp++) {
			r.y = yp
			I += step
			if (I > maxI) {
				I = maxI
				step = -Math.abs(step)
			} else if (I < minI) {
				I = minI
				step = Math.abs(step)
			} 
			iI = int(I)
			bMask.fillRect(r,0xFF000000 + (iI << 16) + (iI << 8) + iI)
				
		}
			
		// draw item (2nd pass) - add the color mask
		bBuffer.fillRect(box,0)
		bBuffer.copyPixels(bMask,hitR,pt,bDraw,origin)
		bBuffer2.draw(bBuffer,idM,defCT,"lighten")
			
			
		bBuffer.applyFilter(bBuffer2,box,origin,bevF)
		// final drawing step
		bColor.copyPixels(bBuffer,box,origin)
			
	}
	
	// add particles
	public function addParticles(xstart:Number,xe:Number) {
		
		var xp:Number
		var yp:Number
			
		// starting x,y
		var xs:Number = pt.x
		var ys:Number = pt.y
			
		var xt:Number
		var yt:Number
			
		// ending x,y
		var ye:Number = hitR.height
			
		var pIdx:Number = pStart
			
		var r = new Rectangle(0,0,4,4)
				
		// analyze item for alpha>0 2x2 rectangles
		for (xp=xstart;xp<xe;xp += 4) {
			r.x = xp
			xt = xs+xp
			for (yp=0;yp<ye;yp += 4) {
				r.y = yp
				
				if (bDraw.hitTest(origin,0x01,r)) {
					// yeah! just found one
					yt = ys+yp	
						
					pl[pIdx] = maxLife
					px[pIdx] = xt
					py[pIdx] = yt
						
					// velocity
					pvl[pIdx] = Math.random()*16+4
					pvx[pIdx] = Math.random()*4-1
					pvy[pIdx] = Math.random()*4-2
						
					pay[pIdx] = 0.2
														
					// mode 0 = from 0 to max light
					pm[pIdx] = 0
						
					pIdx ++
					// take care of maxParticles
					if (pIdx > maxParticles) pIdx = 0
				}
			}
		}
		pStart = pIdx
		activeParticles = 1
	}
	
	public function update() {
	
		switch (step) {
			// fade in
			case 0:
				// clean up
				bData.fillRect(box,0)
				
				// starting pos
				lP.x = lP.y = lRect.x = 0 
				// box width
				lRect.width = int(lPos + 0.5)
			
				// copy item (part)
				bData.copyPixels(bColor,lRect,lP,null,null,true)
			
				// add particles
				addParticles(lPos-pt.x,lPos-pt.x+1)
				renderParticles()
			
				lRect.x = lPos-pt.x
				lRect.width = 8
				lP.x = lPos
				lP.y = pt.y
				
				// copy small amount of particles and item
				bBuffer2.fillRect(box,0)
				bBuffer2.copyPixels(bDraw,lRect,lP,null,null,true)
				bBuffer2.copyPixels(bPart,box,origin,bBuffer2,origin,true)
			
				// add a random glow
				with (dsF) {
					blurX = blurY = int(Math.random()*8+4.5)*2
				}
			
				bBuffer.applyFilter(bBuffer2,box,origin,dsF)
				
				// add particles
				bBuffer.copyPixels(bPart,box,origin,null,null,true)
				
				// use our colormap
				bBuffer.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
				bData.draw(bBuffer,idM,defCT,"add")
			
			
				if (lPos < lMax) {
					lPos += lIncr
					// transition end, go to next
				} else {
					step++
					countdown = conf.waitFrames
				}
			break;
			// wait
			case 1:
				// clean up
				bData.fillRect(box,0)
				// copy logo
				bData.copyPixels(bColor,box,origin,null,null,true)
				
				// add particles
				renderParticles()
				bBuffer.fillRect(box,0)
				bBuffer.copyPixels(bPart,box,origin,null,null,true)
				
				// use our colormap
				bBuffer.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
				bData.draw(bBuffer,idM,defCT,"add")
				
				// delay expired ?
				if (countdown > 0) {
					countdown--
				} else {
					// yes, go to next
					countdown = conf.fadeOutFrames
					// save last frame
					bBuffer.copyPixels(bData,box,origin)
					step++
				}
			break;
			// fade out
			case 2:
				// prepare a mask
				bBuffer2.fillRect(box,int((countdown/conf.fadeOutFrames)*0xFF) << 24)
				// use it to fade out
				bData.copyPixels(bBuffer,box,origin,bBuffer2,origin,false)
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
					lPos = pt.x
					step = 0
				} else {
					// otherways, self destruct
					destroy()
				}
		}
	}
		
}