/*

	Dna particles intro background

*/
package bitfade.intros.backgrounds {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	
	import bitfade.data.*
	
	import bitfade.intros.backgrounds.Background
	
	import bitfade.intros.particles.builders.*
	import bitfade.intros.particles.structures.*
	import bitfade.intros.particles.renderers.*
	import bitfade.intros.particles.transformations.*

	import bitfade.easing.*

	import bitfade.utils.*
	
	public class DnaParticles extends bitfade.intros.backgrounds.Background {
		
		// bmap holding the spectrum
		protected var bMap:Bitmap
		
		// some other bitmapData needed
		protected var bData:BitmapData
		protected var bParticles:BitmapData
		protected var bBoost:BitmapData
		
		// colormaps used for gradients
		protected var colorMap:Array
		protected var colorMapFrom:Array
		protected var colorMapTo:Array
		protected var colorMix:Number = 0;
		
		// geom stuff
		protected var box:Rectangle
		protected var origin:Point
		
		// particles stuff
		protected const MAX_PARTICLES:uint = 2500
		protected var pMat:Matrix3D
		protected var pGfx:Vector.<BitmapData>
		protected var pGfx2:Vector.<BitmapData>
		protected var pList:LinkedListPool;
		protected var pListTransformed:LinkedListPool;
		protected var pListDNA:LinkedListPool;
		protected var pListHelix:LinkedListPool;
		protected var pListRandom:LinkedListPool;
		protected var pListStarfield:LinkedListPool;
		protected var pListSpeed:LinkedListPool;
		protected var pRenderer:bitfade.intros.particles.renderers.BitmapRenderer

		protected var computeLoop:RunNode
		
		protected var angle:Number = 0;
		
		// particles motion stuff
		protected var pMotionBlur:Number = 0;
		
		protected var pMoveXCMax:Number = 150
		protected var pMoveXCFrom:Number = pMoveXCMax
		protected var pMoveXCTo:Number = pMoveXCMax
		protected var pMoveXC:Number = pMoveXCMax
		
		protected var pRotXFrom:Number = 50
		protected var pRotXTo:Number = 50
		protected var pRotX:Number = 50
		
		protected var pRotZFrom:Number = 0
		protected var pRotZTo:Number = 0
		protected var pRotZ:Number = 0
		
		protected var pScaleFrom:Number = 1
		protected var pScaleTo:Number = 1
		protected var pScale:Number = 1
		
		protected var pMorphRatio: Number = 0;
		
		protected var burstIncrement:Number
		protected var burstType:String = "ended"
		protected var burstRatio: Number;
		
		protected var starfield:Boolean = false
		protected var keepMoving:Boolean = false
		
		// constructor
		public function DnaParticles(...args) {
			configure.apply(null,args)
		}
		
		// init the spectrum
		override protected function init():void {
		
			// create the bitmap
			bMap = new Bitmap()
			
			addChild(bMap)
			
			colorMap = colorMapTo = colorMapFrom = Colors.buildColorMap("monoHL")
			
			// create bitmaps
			bData = Bdata.create(w,h)
			bParticles = bData.clone()
			bBoost = bData.clone()
			
			box = bData.rect
			
			origin = Geom.origin
			
			bMap.bitmapData = bData
			
			// create structures
			pListDNA = bitfade.intros.particles.structures.Dna.build(MAX_PARTICLES)
			pListHelix = bitfade.intros.particles.structures.Helix.build(MAX_PARTICLES)
			pListRandom = bitfade.intros.particles.structures.Zero.build(MAX_PARTICLES)
			pListStarfield = bitfade.intros.particles.structures.Random.build(MAX_PARTICLES)
			pListSpeed = bitfade.intros.particles.structures.Speed.build(MAX_PARTICLES)
			pListTransformed = bitfade.intros.particles.structures.Zero.build(MAX_PARTICLES)
			pList = bitfade.intros.particles.transformations.Clone.from(pListDNA)
			
			// create particles bitmapDatas
			pGfx = bitfade.intros.particles.builders.Alpha.build(conf.minSize,conf.maxSize,32,conf.maxAlpha,conf.solid,conf.solid ? conf.color : 0)
			pGfx2 = bitfade.intros.particles.builders.Alpha.build(32,96,8,conf.solid ? 0.2 : 5,conf.solid,conf.solid ? conf.color : 0)
			
			// create particles renderer
			pRenderer = new bitfade.intros.particles.renderers.BitmapRenderer()
			pRenderer.pGfx = pGfx
			pRenderer.center.x = w >> 1
			pRenderer.center.y = h >> 1
			pRenderer.output = bParticles
			
			pMat = new Matrix3D();
			
			pMoveXCFrom = pMoveXCMax = pMoveXCTo = pMoveXCMax = (w >> 1) - conf.margin
			
		}
		
		override public function start():void {
			
			// handle start with starfield
			if (conf.start == "starfield") {
				burstType = "starfield"
				burstRatio = 1
				starfield = true
				keepMoving = true
				bitfade.intros.particles.transformations.Copy.apply(pListStarfield,pList)
			}
			
			// register render loop
			computeLoop = Run.every(Run.FRAME,renderParticles)	
		}
		
		
		// set a color scheme
		override public function gradient(scheme:String = null,immediate:Boolean = false) {
			if (!scheme) scheme = "oceanHL"
			colorMapTo =  Colors.buildColorMap(scheme)
			colorMix = 0
			if (immediate) {
				colorMapFrom = colorMapTo
			}
		}
		
		// compute global particles movement
		protected function doMove(ratio:Number) {
		
			if (ratio == 0) {
				// set new position
				pMoveXCFrom = pMoveXCTo
				pMoveXCTo = burstType == "left" ? -pMoveXCMax : pMoveXCMax
				
				
				pRotXFrom = pRotXTo 
				pRotXTo = (pRotXTo > 0 ? -50 : 50) + Math.random()*40-20
				
				pRotZFrom = pRotZTo 
				pRotZTo = Math.random()*40-20
				
				pScaleFrom = pScaleTo
				pScaleTo = 1 + Math.random()
				 
			}
			
			ratio = bitfade.easing.Cubic.Out(ratio,0,1,1)
			
			pMotionBlur = bitfade.easing.Expo.In(ratio,1,-1,1)
			pMorphRatio = bitfade.easing.Expo.In(ratio,0,2,1)
			
			
			if (pMorphRatio > 0.8 && burstType == "none") {
				bMap.alpha -= 0.25
			} 
			
			
			pMorphRatio = pMorphRatio <= 1 ? pMorphRatio : 2-pMorphRatio
			
			if (pMorphRatio < 0.8) {
				// don't move for first half of transition
				return
			} 
			
			
			
			starfield = (burstType == "starfield")
			keepMoving = false
			
			pMoveXC = pMoveXCFrom + (pMoveXCTo-pMoveXCFrom)*ratio
			pRotX = pRotXFrom + (pRotXTo-pRotXFrom)*ratio
			pRotZ = pRotZFrom + (pRotZTo-pRotZFrom)*ratio
			pScale = pScaleFrom + (pScaleTo-pScaleFrom)*ratio
			
			
		}
		
		// set transition type
		override public function burst(...args):void {
			burstType = args[0]
			
			burstRatio = 0
			burstIncrement = 1/(Boot.stage.frameRate*1.1)
			
			// fade out if "none"
			if (burstType != "none") {
				if (bMap.alpha == 0) {
					bMap.alpha = 1
					burstRatio = 0.5
					burstIncrement = 1/(2*Boot.stage.frameRate*1.1)
				} 
			} 
			
			keepMoving = false
			
			if (starfield) {
				keepMoving = true
				bitfade.intros.particles.transformations.Shift.apply(pList,pListRandom)
				return
			}
			
			// set particles burst position
			bitfade.intros.particles.transformations.Explode.apply(pListTransformed,pListRandom)
			
		}
		
		// this will render particles
		protected function renderParticles():void {
			
			// if paused or invisible, do nothing
			if (paused || bMap.alpha <= 0) return
			
			if (burstType != "ended") {
				if (burstRatio < 1) {
					// if here, a transition is running
					doMove(burstRatio)
					
				
					burstRatio += burstIncrement
					burstRatio = Math.min(1,burstRatio)
				} else {
					if (burstType == "none") return 
					doMove(burstRatio)
					burstType = "ended"
				}
			}
			
			
			// apply a motion blur filter when transition is running
			if (pMorphRatio > 0) {
				bParticles.colorTransform(box,new ColorTransform(1,1,1,0.6*pMorphRatio,0,0,0,0))
			} else {
				bParticles.fillRect(box,0)
			}
			
			// "starfield" case, move particles
			if (starfield) {
				if (pMorphRatio == 0 || keepMoving) {
					bitfade.intros.particles.transformations.Add.apply(pList,pListSpeed,pList)
				} else {
					bitfade.intros.particles.transformations.Copy.apply(pListStarfield,pList)
				}
				
			} else {
				// transform from Helix to DNA
				bitfade.intros.particles.transformations.Morph.apply(pListDNA,pListHelix,pList,Math.abs(Math.sin(Math.PI*angle/180)))
			}
			
			
			// reset rotation
			pMat.identity();
			
			if (!starfield) {
			
				angle++
				
				// set rotation
				pMat.appendRotation( angle*2, Vector3D.Y_AXIS);
				pMat.appendRotation( pRotX, Vector3D.X_AXIS );
				pMat.appendRotation( pRotZ, Vector3D.Z_AXIS );
				pMat.appendScale(pScale,pScale,pScale)
				
				pRenderer.center.x = int((w >> 1) + pMoveXC)
			} else {
				pRenderer.center.x = w >> 1
			}
			
			
			// apply rotation
			bitfade.intros.particles.transformations.Matrix.apply(pList,pMat,pListTransformed)
			
			
			
			if (pMorphRatio > 0) {
				// bigger particles when near to camera
				pRenderer.pGfx = (!starfield && pMorphRatio > 0.3 && pMotionBlur > 0.5) ? pGfx2 : pGfx
				
				bitfade.intros.particles.transformations.Morph.apply(pListTransformed,pListRandom,pList,pMorphRatio)
				pRenderer.render(pList)
			} else {
				pRenderer.render(pListTransformed)
			}
			
			
			bData.lock()
			
			// draw the particles
			if (conf.glow) {
				bData.applyFilter(bParticles,box,origin,new BlurFilter(32,32,starfield ? 2 : 2))
				bData.copyPixels(bParticles,box,origin,null,null,true)
			} else {
				bData.copyPixels(bParticles,box,origin)
			}
			
			if (conf.glow && pMorphRatio > 0.3 && pMotionBlur > 0.5) {
				bParticles.applyFilter(bData,box,origin,new BlurFilter(uint(pMotionBlur*128),uint(pMotionBlur*128),1))
				bData.copyPixels(bParticles,box,origin)	
			}
			
				
			
			// increase color transition 
			if (colorMapFrom != colorMapTo) {
				colorMix += 1 
				if (colorMix > 20) {
					// set a new gradient
					colorMapFrom = colorMapTo
					colorMix = 0
				} else {
					// mix previous and current gradient
					Colors.mix(colorMapFrom,colorMapTo,colorMap,colorMix*5)
				}
					
			}
			
			if (!conf.solid) {
				bData.paletteMap(bData,box,origin,null,null,null,colorMap)
			}
			
			bData.unlock()

			

		}
		
		// clean up
		override public function destroy():void {
			Run.reset(computeLoop)
			super.destroy()
		}
				
	}
}
/* commentsOK */