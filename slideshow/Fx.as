/*

	Pure actionscript 3.0 slideshow with enlight effect 
	this extends bitfade.slideshow.effect which has common functions

*/
package bitfade.slideshow {

	import flash.display.*
	import flash.events.*
	import flash.filters.*
	import flash.geom.*
	
	import bitfade.utils.*
	import bitfade.easing.*
	import bitfade.transitions.advanced
	import bitfade.slideshow.slideshow
	
	public class fx extends bitfade.slideshow.slideshow {
	
		protected var effectsDefaults:Object = {
			scanlines : {
				enabled: true,
				hiAlpha: 1,
				lowAlpha: 0.9
			},
			background: {
				enabled:true,
				color: 0,
				alpha: 1
			},
			color: {
				enabled:true,
				scheme: "sepia"
			},
			reflection: {
				enabled: true,
				size: 50,
				hiAlpha: 0.7,
				lowAlpha: 0.0,
				drawControls: true,
				drawCaption: true
			},
			corners: {
				enabled: false,
				vertical: 32,
				horizontal: 32
			},
			original: {
				enabled: true
			}
		}
		
		
		// some more bitmapDatas needed for effects
		protected var bScanLines:BitmapData
		protected var bRef:BitmapData
		protected var bAlpha:BitmapData
		protected var bMask:BitmapData;
		
		protected var colorMap:Array
		protected var cM:ColorMatrixFilter
		
		protected var bRefPoint:Point
		
		public function fx(conf) {
			// call parent constructor
			super(conf)
		}
		
		override protected function init(e:Event=null) {
		
			// set effects defaults
			if (!conf.effects) {
				conf.effects = effectsDefaults
			} else {
				conf.effects = misc.setDefaults(conf.effects[0],effectsDefaults)
			}
			
		
			// if reflection is enabled, adjust height
			with (conf.effects.reflection) {
				if (enabled) {
					if (!conf.height) conf.height = stage.stageHeight
					conf.height -= size					
				}
			}
			
			// global settings
			defaults.transition.random = ["fade","slideLeft","hilight","white","compose","hideshow","expandHeight","expandWidth"]
			
			// call parent init
			super.init(e)
		}
		
		// custom init
		override protected function customInit() {
		
			var yp:uint,ha:uint,la:uint
			var r = new Rectangle(0,0,w,1)
			
			with (conf.effects.reflection) {
				// if reflection is enabled, adjust bitmaps sizes
				if (enabled) {
					bData = new BitmapData(w,h+size,true,0);
					bMap.bitmapData = bData
					
					conf.effects.corners.rh = h+size
			
					bRef = new BitmapData(w,size,true,0)
					bAlpha = bRef.clone();
					
					bRefPoint = new Point(0,h)
					
					// create the reflection alpha mask
					ha = uint(hiAlpha*0xFF)
					la = uint(lowAlpha*0xFF)
					
					for (yp = 0; yp < size; yp += 1 ) {
						r.y = yp
						bAlpha.fillRect(r,uint(Quad.Out(yp,ha,la-ha,size)) << 24)
					}
					
					if (drawControls) {
						// check if controls needs to be reflected
						drawControls = conf.controls.show != "never" && ((controls.y + controls.height) > (h-size))
						
						if (drawControls) {
							// controls needs to be reflected, create some stuff needed later
							conf.effects.reflection.drawControlsY = controls.y-h+size
							conf.effects.reflection.drawControlsBox = new Rectangle(0,h-size,w,size)
							conf.effects.reflection.drawControlsCT = new ColorTransform(1,1,1,0,0,0,0,0)
						
						}
					}
				} else {
					conf.effects.corners.rh = h
				}
				
			}
			
			with (conf.effects.scanlines) {
				if (enabled) {
					// scanlines are one of early effects
					conf.effects.early = true
					
					// create the scanlines mask
					bScanLines = bData.clone()
					
					ha = uint(hiAlpha*0xFF) << 24
					la = uint(lowAlpha*0xFF) << 24
			
					for (yp = 0; yp < h; yp += 2 ) {
						r.y = yp
						bScanLines.fillRect(r,ha)
						r.y = yp+1
						bScanLines.fillRect(r,la)
					}
				}
			}
			
			with (conf.effects.color) {
				if (enabled) {
					// color is one of early effects
					conf.effects.early = true
				
					// build the colormap
					colorMap = colors.buildColorMap(scheme,0xFF,true)
						
					// create the color filter
					cM = new ColorMatrixFilter([
						0,0,0,0,0,
						0,0,0,0,0,
						.33,.33,.34,0,0,
						0,0,0,1,0,
    	 				 
					])
				}
			}
			
			with (conf.effects.corners) {
				if (enabled) {
				
					bMask = bData.clone()
			
					// create a shape
					var sh:Shape = new Shape()
					
					// draw a rectangle
					with (sh.graphics) {
						beginFill(0,1)
						drawRoundRect(0,0,w,rh,horizontal,vertical)
					}
			
					// convert to bitmapData and blur it
					bMask.fillRect(box,0)
					bMask.draw(sh)
				
				}
			}
			
			with (conf.effects.background) {
				color = (enabled) ? (uint(alpha*0xFF) << 24) + color : 0
			}
			
			// advanced transition manager
			transition = new advanced(bDraw,bBuffer)
			
			if (captionTransition) captionTransition = new advanced(bCaptionBuffer)
		}
		
		public function buildColorMap(color) {
			colorMap = colors.buildColorMap(color,0xFF,true)
		}
		
		// this will apply some early effects
		public function earlyEffects(bd:BitmapData) {
			var target:BitmapData = bd
			
			// fill background
			bData.fillRect(box,conf.effects.background.color)
			
			if (conf.effects.color.enabled) {
				// apply the color filter
				bBuffer.applyFilter(bd,box,origin,cM)
				bBuffer.paletteMap(bBuffer,box,origin,null,null,colorMap,null)
				target = bBuffer
			}
			
			if (conf.effects.scanlines.enabled) {
				bData.copyPixels(target,box,origin,bScanLines,origin,true)
			} else {
				bData.copyPixels(target,box,origin,null,null,true)
			}
			
			
		}
		
		// render function, overrides parent one
		override protected function render(bd:BitmapData=null) {
			if (!bd) {
				if (!pz) return
				pz.update()
				bd = pz.bData
			} 
			
			
			var showOriginal:Boolean = conf.effects.original.enabled
			
			if (!(conf.effects.early)) {
				// if no early effects, show original item
				bData.copyPixels(bd,box,origin)
			} else if (showOriginal && overCounter > 0 && overCounter < overCounterMax) {
				// apply early effects
				earlyEffects(bd)
			
				// add (faded) original image
				bBuffer.fillRect(box,uint(overCounter/overCounterMax*0xFF) << 24)
				bData.copyPixels(bd,box,origin,bBuffer,origin,true)
			} else {
				if (!showOriginal || overCounter == 0) {
					// if no mouse over, early effects only
					earlyEffects(bd)
				} else {
					// no enlight, just the original
					bData.copyPixels(bd,box,origin)
				}
			}
			
			// render caption and controls
			if (conf.effects.reflection.enabled && conf.effects.reflection.drawCaption) renderCaption();
			renderControls();
			
			// deal with reflection
			with (conf.effects.reflection) {
			if (enabled) {
					bRef.fillRect(bRef.rect,0)
				
					if (drawControls && controls.alpha > 0) {
						// controls needs to be reflected
						bBuffer.copyPixels(bData,drawControlsBox,origin)
						drawControlsCT.alphaMultiplier = controls.alpha
						bBuffer.draw(controls,geom.getTranslateMatrix(controls.x,drawControlsY),drawControlsCT,null,bRef.rect)
						bRef.draw(bBuffer,geom.createBox(1,-1,0, 0,size),null,null,bRef.rect)
					} else {
						// no need to reflect controls
						bRef.draw(bData,geom.createBox(1,-1,0, 0,h),null,null,bRef.rect)
					}
					bData.copyPixels(bRef,bRef.rect,bRefPoint,bAlpha,origin)					
				}
			}
			
			if (!conf.effects.reflection.enabled || !conf.effects.reflection.drawCaption) renderCaption();
			
			if (conf.effects.corners.enabled) bData.copyPixels(bData,bData.rect,origin,bMask,origin)
			
			
			
		}
	
	}

}
	