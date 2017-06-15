/*

	Spectrum intro background

*/
package bitfade.intros.backgrounds {
	
	import flash.display.*
	import flash.geom.*
	import flash.events.*
	import flash.utils.*
	import flash.media.*
	import flash.filters.*
	
	import bitfade.utils.*
	import bitfade.easing.*
	import bitfade.intros.backgrounds.Background
	
	public class CleanSpectrum extends bitfade.intros.backgrounds.Background {
		
		protected var computeLoop:RunNode
		protected var countDown:uint = 25
		
		//public static const MY_BAND:Array = [344, 689, 2756, 5512, 11025];
		//public static const MY_BAND:Array = [86, 172, 344, 689, 1378, 2756, 5512, 11025];
		public static const MY_BAND:Array = [63, 125, 500, 1000, 2000, 4000, 6000, 8000];
		//public static const MY_BAND:Array = [20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000, 20000]; // Behringer 3102
		//public static const MY_BAND:Array = [125, 500, 1000, 2000];
		//public static const MY_BAND:Array = [172, 689, 2756, 11025];
		//public static const MY_BAND:Array = [172, 689, 2756, 8000];
		//public static const MY_BAND:Array = [172, 8000];
		//public static const MY_BAND:Array = [86, 200, 1000, 2000, 8000];
		//public static const MY_BAND:Array = [43, 80, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 8000, 10000]; // Behringer 3102
		
		public static const freqTable:Array = MY_BAND
		public static const stretchFactor:uint = 0
		
		protected const historyLength:uint = 25
		
		protected var offset:Number = 0;
		
		protected var spectrumData:ByteArray = new ByteArray()
		protected var subbands:uint = 0
		protected var subbandLastFreq:Array
		protected var subbandNFreqs:Array
		protected var instant:Array 
		protected var average:Array
		protected var variance:Array 
		protected var history:Array
		protected var previous:Array 
			
		// bmap holding the spectrum
		protected var bMap:Bitmap
		protected var bMap2:Bitmap
		
		// some other bitmapData needed
		protected var bData:BitmapData
		protected var bBuffer:BitmapData
		protected var bBar:BitmapData
		
		protected var sh:Shape;
		
		// constructor
		public function CleanSpectrum(...args) {
			configure.apply(null,args)
		}
		
 
		// init the spectrum
		override protected function init():void {
		
			// create the bitmap
			bMap = new Bitmap()
			addChild(bMap)
		
			bMap2 = new Bitmap()
			addChild(bMap2)
		
		
			ResLoader.load("resources/images/lance.png",loaded)
		
			// create bitmaps
			bData = new BitmapData(w,h,true,0)
			bMap.bitmapData = bData
			
			//bMap2.filters = [ new GlowFilter(0xFFFFFF,1.0,32, 32, 2,  2, false, false) ]
			
			bBuffer = new BitmapData(w,h,true,0)
			
			bBar = new BitmapData(w,h,true,0)
			//bBar.fillRect(Geom.rectangle(32,0,w-64,4),0x20000000)
			//bBar.perlinNoise(64,64,7,1,true,true,8,false)
			
			//bBar.applyFilter(bBar,bBar.rect,Geom.origin,new BlurFilter(4,4,3))
			//bBar.colorTransform(bBar.rect,new ColorTransform(1,1,1,1,0,0,0,-0x40))
			//bBar.colorTransform(bBar.rect,new ColorTransform(1,1,1,10,0,0,0,0))
			
			bBar.fillRect(Geom.rectangle(0,0,w,h),0x20FFFFFF)
			bBar.fillRect(Geom.rectangle(0,0,w,1),0x40FFFFFF)
			
			var ff:uint
			
			for (var xp:uint = 0;xp<h;xp++) {
				ff = uint(Linear.In(xp,0,0xFF,w))
				bBar.fillRect(Geom.rectangle(0,xp,w,1), ff << 24 | 0xFFFFFF)
			}
			
			/*
			for (var xp:uint = 0;xp<w;xp++) {
				if (Math.random() > 0.9) bBar.fillRect(Geom.rectangle(xp,0,Math.random()*3+1,h), 0)
			}
			*/
			
			/*
			for (var xp:uint = 0;xp<w;xp++) {
				if (Math.random() > 0.9) bBar.fillRect(Geom.rectangle(xp,0,Math.random()*3+1,h), 0x80FFFFFF)
			}
			*/
			
			//bBar.fillRect(Geom.rectangle(0,0,w,4),0x00FFFFFF)
			
			/*
			for (var i:uint = 0; i< 64; i++) {
				bBar.fillRect(Geom.rectangle(Math.random()*w,0,Math.random()*4+1,h),0x05FFFFFF)
			}
			*/
			
			bBar.applyFilter(bBar,bBar.rect,Geom.origin,new BlurFilter(4,4,3))
			
			//bBar.paletteMap(bBar,bBar.rect,Geom.origin,null,null,null,Colors.buildColorMap("monoHL",0xFF))
			//bBar.colorTransform(bBar.rect,new ColorTransform(1,1,1,1,0,0,0,-0xA0))
			
			//bBar.fillRect(Geom.rectangle(0,0,w,1),0x85000000)
			//bBar.fillRect(Geom.rectangle(0,3,w,1),0x85000000)
			//bBar.colorTransform(bBar.rect,new ColorTransform(1,1,1,1,0,0,0,-0xA0))
			
			
			
			sh = new Shape()
			addChild(sh)
			
			//addChild(bMap)
			//bMap.blendMode = "subtract"


			
			
			subbands = freqTable.length
			
			subbands = 256
			
			instant = new Array(subbands)
			average = new Array(subbands)
			history = new Array(subbands)
			variance = new Array(subbands)
			previous = new Array(subbands)
			subbandNFreqs = new Array(subbands)
			
			subbandLastFreq = new Array(subbands)
			
			
			var sr:Number = (stretchFactor == 0) ? 44100 : 44100/(stretchFactor*2)
			
			var lastLast:uint = 0;
			/*
			
			for (var i:uint=0;i<subbands;i++) {
				history[i] = new Array(historyLength)
				for (var j:uint=0;j<historyLength;j++) history[i][j] = 0;
				
				subbandLastFreq[i] =  Math.min(Math.round(freqTable[i]/sr * 1024), 255);
				subbandNFreqs[i] = subbandLastFreq[i]-lastLast
				trace(subbandLastFreq[i])
				lastLast = subbandLastFreq[i]
				
			}
			*/
		
			
			
			for (var i:uint=0;i<subbands;i++) {
				history[i] = new Array(historyLength)
				for (var j:uint=0;j<historyLength;j++) history[i][j] = 0;
				
				subbandLastFreq[i] = (i+1)*1-1
				subbandNFreqs[i] = subbandLastFreq[i]-lastLast
				lastLast = subbandLastFreq[i]
				
				//trace(uint(200/Math.pow(2,5*i/subbands)))
				
			}
		

			
		}
		
		protected function loaded(content:*) {
			bMap2.bitmapData = content.bitmapData
			
			bMap2.bitmapData.applyFilter(bMap2.bitmapData,bMap2.bitmapData.rect,Geom.origin,new GlowFilter(0xFFFFFF,0.3,16, 16, 2,  2, false, false))
			
			//bMap2.filters = [ new GlowFilter(0xFFFFFF,1.0,32, 32, 2,  2, false, false) ]
		}
		
		override public function start():void {
			// add the event listener
			computeLoop = Run.every(Run.FRAME,computeSpectrum)
		}
		
		
		override public function burst(...args):void {
		}
		
		// this will draw the spectrum
		protected function computeSpectrum():void {
			// bData is not ready ? do nothing
			if (paused) return
			
			spectrumData.position = 0;
			SoundMixer.computeSpectrum(spectrumData, true, 0);
			
			var sd:Number
			var i:uint = 0;
			var j:uint = 0;
			var ch:uint = 0
			var ad:Number;
			
			var nFreq:uint = 256 / subbands
			
			var current:uint = 0;
			
			for (i=0;i<subbands;i++) {
				instant[i] = 0;
				//subbandNFreqs[i] = 0;
				//instant[i] = v[i]
			}
			
			/*
			for (ch=0;ch<2;ch++)
			for (i=0; i<256; ++i) {
				if (i>subbandLastFreq[current]) current++ 
				sd = instant[current]
				instant[current] = Math.max(sd,spectrumData.readFloat())
            }
            */
            
            for (ch=0;ch<2;ch++) {
				for (i=0; i<256; ++i) {
					if (i>subbandLastFreq[current]) current++ 
					sd = spectrumData.readFloat()*100
					
					//if (sd > 0) subbandNFreqs[current]++
					
					instant[current] += sd
					//instant[current] = Math.max(sd,instant[current])
            	}
			}
			
			
			var vr:Number = 0;
            
			for (i=0;i<subbands;i++) {
				
				instant[i] /= (2*subbandNFreqs[i])
				
				//instant[i] *= (subbandNFreqs[i])/256
				
				//instant[i] /= (subbandNFreqs[i])
				
				//instant[i] /= 2*nFreq
				
				history[i].shift()
				history[i].push(instant[i])
				j = 0
				ad = 0;
				vr = 0;
				
				for (;j<historyLength;j++) {
					ad += history[i][j]
					vr += (instant[i]-history[i][j])*(instant[i]-history[i][j])
				}
				average[i] = ad / historyLength
				variance[i] = vr / historyLength
			}
			
			
			
			//trace(Math.round(average[0]*100),Math.round(instant[0]*100))
			
			
			
			//bData.fillRect(bData.rect,0)
				
			
			/*
			for (i=0;i<subbands;i++) {
				instant[i] /= 100
				bData.fillRect(Geom.rectangle(i*(bh+1),h-instant[i]*h,bh,instant[i]*h),0xFF000080 )
			}
			
			return
			*/
			
			
			var selected:int = -1;
			
			//var thresold:Array = [1500,100,100,100,100,100,100,100,100,100,100,100]
			
			
			var intensity:Number 
			
			var count:uint = 0;
			
			var vT:Number = 0;
			
			
			var pt:Point = new Point()
			var rotAngle:Number = 0;
			
			var power:Number = 0;
			
			for (i=1;i<subbands;i++) {
				power += instant[i]
			}
			
			power /= (5*subbands)
			
			//offset += 1
			//offset += (2 + power)
			
			
			//power = Math.min(2,Math.max(0.5,power))
			
			
			
			for (i=1;i<subbands;i++) {
				intensity = instant[i] / average[i]
				vT = 100+400/Math.pow(2,5*i/subbands)
				
				if (variance[i] > vT && intensity > 1) count++
			}
			
			power = 0.5+4*count/subbands
			
			
			bBuffer.colorTransform(bData.rect,new ColorTransform(1,1,1,Math.max(0.7,Math.min(0.99,1-4*count/subbands)),0,0,0,0))
			//bBuffer.colorTransform(bData.rect,new ColorTransform(1,1,1,0.95,0,0,0,0))
			
			
			offset += 3*power
			
			sh.graphics.clear()
			sh.graphics.lineStyle(uint(Math.random()*7+1),0,.2);
			//sh.graphics.beginFill(0xFFFFFF,0.5)
			//sh.graphics.drawCircle(w/2, h/2, 50);
            //sh.graphics.endFill();
			
			var oldAngle:Number = 0
			
			var temp:Number
			
			var bh:Number = w/subbands
			
			//bBuffer.applyFilter(bBuffer,bBuffer.rect,Geom.origin,new BlurFilter(8,8))
			
			for (i=1;i<subbands;i++) {
				intensity = instant[i] / average[i]
				vT = 100+400/Math.pow(2,5*i/subbands)
				
				//if (i % 4 == 0) {
				if (variance[i] > vT && intensity > 1) {
					
					
					var ff:uint = Math.random()*64
					
					//sh.graphics.drawCircle(w/2, h/2, 50);
					
					sh.graphics.moveTo(0,0.5*h*((i+offset) % subbands)/subbands)
					sh.graphics.curveTo(w/2+Math.sin(offset/64)*(i)/subbands*w, h/2+Math.cos(offset/57)*i/subbands*h, w,h/2+0.5*h*(subbands-((i + count) % subbands))/subbands);

					//sh.graphics.moveTo(0,h*Math.random())


					//sh.graphics.curveTo(w/2+Math.sin(offset/64)*(subbands-i)/subbands*w, h/2+Math.cos(offset/57)*i/subbands*h, w,h*Math.random());
					
					//bBuffer.copyPixels(bBar,Geom.rectangle(0,0,w,64),Geom.point(0,uint(bh*i)),null,null,true)
					//bBuffer.copyPixels(bBar,Geom.rectangle(0,0,8,h-ff),Geom.point(Math.random()*w,ff),null,null,true)
					//bData.fillRect(Geom.rectangle(0,i*(bh),w,1),0x40FFFFFF )
					
					count++
				}
				
				/*
				if (variance[i] > vT && intensity > 1) {
				
					
					var ff:uint = Math.random()*64
					
					
					//bBuffer.copyPixels(bBar,Geom.rectangle(0,0,w,64),Geom.point(0,uint(bh*i)),null,null,true)
					bBuffer.copyPixels(bBar,Geom.rectangle(0,0,8,h-ff),Geom.point(Math.random()*w,ff),null,null,true)
					//bData.fillRect(Geom.rectangle(0,i*(bh),w,1),0x40FFFFFF )
					
					count++
				} 
				*/
			}
			
			
			//bBuffer.scroll(0,count)
			
			sh.visible = false
			
			bBuffer.draw(sh)
			
			//bBuffer.scroll(0,-5)
			
			
			//bBuffer.applyFilter(bBuffer,bBuffer.rect,Geom.origin,new DropShadowFilter(0,0,0,1,2,2,1,1,false,false,true))
			bBuffer.applyFilter(bBuffer,bBuffer.rect,Geom.origin,new BlurFilter(2,2))
			
			//bData.copyPixels(bBar,bData.rect,Geom.origin)
			//bData.copyPixels(bBuffer,bData.rect,Geom.origin)
			//bData.applyFilter(bBuffer,bBuffer.rect,Geom.origin,new BlurFilter(32,2))
			//bBuffer.copyPixels(bBar,bBar.rect,Geom.origin)
			
			bData.paletteMap(bBuffer,bData.rect,Geom.origin,null,null,null,Colors.buildColorMap("oceanHL"))
			
			
			
			bMap2.alpha = (count/subbands) > 0.3 ? 1 : 0.5
			bMap2.alpha = 1
			
			
			/*
			sh.graphics.clear()
			sh.graphics.lineStyle(1,0xFFFFFF,1);
			sh.graphics.beginFill(0xFFFFFF,0.5)
			sh.graphics.drawCircle(w/2, h/2, 400*(count/subbands));
            sh.graphics.endFill();
			*/
			
			/*
			bMap2.scaleX = bMap2.scaleY = 2*count/subbands
			bMap2.x = (w-bMap2.width) / 2
			bMap2.y = (h-bMap2.height) / 2
			*/
			
			//bData.fillRect(Geom.rectangle(0,150-20,w,40),Math.min((0xFF*count/subbands),0xFF) << 24 | 0xFFFFFF)
			
			//bData.fillRect(Geom.rectangle(0,150-(count/128)*150,w,(count/128)*150),Math.min((0xFF*count/64),0xFF) << 24 | 0xFFFFFF)
			
			return
			
			
			//power = freqs[0]
			
			//power = (freqs[1]*peak)
			
			
			
			//power = peak
			
			power = power > 0.5 ? power : 0
			
			
			
			//trace(power)
			
			bData.fillRect(bData.rect,0)
			/*
			power = freqs[0]
			bData.fillRect(Geom.rectangle(0,40,50,20),((0xFF*(power-0.5)/0.5)) << 24 | 0xFFFFFF )
			power *= peak
			bData.fillRect(Geom.rectangle(60,40,50,20),((0xFF*(power-0.5)/0.5)) << 24 | 0xFFFFFF )
			power = freqs[1]
			bData.fillRect(Geom.rectangle(0,70,50,20),((0xFF*(power-0.5)/0.5)) << 24 | 0xFFFFFF )
			power *= peak
			bData.fillRect(Geom.rectangle(60,70,50,20),((0xFF*(power-0.5)/0.5)) << 24 | 0xFFFFFF )
			power = freqs[2]
			bData.fillRect(Geom.rectangle(0,100,50,20),((0xFF*(power-0.5)/0.5)) << 24 | 0xFFFFFF )
			power *= peak
			bData.fillRect(Geom.rectangle(60,100,50,20),((0xFF*(power-0.5)/0.5)) << 24 | 0xFFFFFF )
			power = freqs[3]
			bData.fillRect(Geom.rectangle(0,130,50,20),((0xFF*(power-0.5)/0.5)) << 24 | 0xFFFFFF )
			power *= peak
			bData.fillRect(Geom.rectangle(60,130,50,20),((0xFF*(power-0.5)/0.5)) << 24 | 0xFFFFFF )
			
			power = bitfade.utils.Sound.power
			bData.fillRect(Geom.rectangle(0,170,50,20),((0xFF*(power-0.5)/0.5)) << 24 | 0xFFFFFF )
			power = peak
			bData.fillRect(Geom.rectangle(60,170,50,20),((0xFF*(power-0.5)/0.5)) << 24 | 0xFFFFFF )
			
			power = bitfade.utils.Sound.power * peak * 0.25
			bData.fillRect(Geom.rectangle(0,210,110,20),((0xFF*(power-0.5)/0.5)) << 24 | 0xFFFFFF )
			
			return
			
			power = (freqs[0]*peak)
			*/
			
			//power = peak
			
			power = power > 0.5 ? power : 0
			
			bData.fillRect(Geom.rectangle(0,80,power*250,20),((0xFF*1)) << 24 | 0xFFFFFF )
			
			//trace(power)
			
		}
		
		// clean up
		override public function destroy():void {
			Run.reset(computeLoop)
			super.destroy()
		}
				
	}
}
/* commentsOK */