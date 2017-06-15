/*

	Panzoom display object, display image/swf with ken burns effect

*/
package bitfade.display {

	import flash.display.*
	import flash.events.*
	import flash.geom.*
	import flash.utils.*
	
	import bitfade.utils.*
	
	public class Panzoom extends Sprite {
		
		// here we keep default configuration
		protected var conf:Object = {
			scale: "fill",
			align: "center,center",
			pan: "none",
			zoom: "none",
			
			targetWidth: 0,
			targetHeight: 0,
		
			animated: false,
			
			loop: true,
			
			repeat : 0,
			counter: 0
		}
		
		// some bitmapDatas
		public var bMap:Bitmap;
		public var bData:BitmapData;
			
		// dimentions
		protected var w:uint = 0
		protected var h:uint = 0
		
		// geom stuff
		protected var box:Rectangle
		
		// source image/swf
		public var target
		
		public function Panzoom(item,opts:Object) {
			
			target = {
				item: item
			}
			
			// if target is in opts too, delete it
			if (opts.target) delete opts.target
			
			// get the conf overriding defaults
			conf = Misc.setDefaults(opts,conf)
			
			// fix some stuff in conf
			if (conf.pan == "none") { 
				conf.pan = false
				conf.zoom = false
			} else if (conf.zoom == "none") conf.zoom = false
			
			if (item is Bitmap || !conf.animated ) conf.animated = false
			
			// alignment values
			var valign:Array = ["top","center","bottom"]
			var halign:Array = ["left","center","right"]
				
			with (conf) {
				w = width
				h = height
				
				// if targetWidth / targetHeight, force target size
				target.width = targetWidth ? targetWidth : item.width
				target.height = targetHeight ? targetHeight : item.height
				
				// create stuff
				bData = new BitmapData(w,h,true,0);
				bMap = new Bitmap(bData)
				box = new Rectangle(0,0,w,h)
			
				// add the bitmap
				addChild(bMap)
				
				if (align == "random") {
					// set align to random value
					align = {
						w : halign[uint(Math.random()*2+0.5)],
						h : valign[uint(Math.random()*2+0.5)]
					}
				} else {
					// split align in vert. / horiz.
					align = Geom.splitProps(align)
				}
				
				if (pan) {
					// set pan to random value
					if (pan == "random") {
						pan = {
							w : halign[uint(Math.random()*2+0.5)],
							h : valign[uint(Math.random()*2+0.5)]
						}		
					} else {
						// split pan in vert. / horiz.
						pan = Geom.splitProps(pan)
			
					}
				}
				
				// get the scaler object
				getScaler()
				
				// set smoothing if needed
				if (item is Bitmap && (zoom || scale != "none")) {
					item.smoothing = true
				}
				
				if (!zoom) {
					if (!animated) {
						
						// target is non animated, no zoom used so we can optimize things
						// by replacing target with a bitmap
						
						var bd:BitmapData
						// get the scale matrix
						var sM:Matrix = Geom.getScaleMatrix(scaler)
						
						if (pan) {
							// pan used, create the bitmap with scaled size
							bd = new BitmapData(uint(target.width*scaler.ratio+.5),uint(target.height*scaler.ratio+.5),true,0);
							sM.tx = sM.ty = 0
							
							target.width = bd.width
							target.height = bd.height
							
						} else {
							// pan not used, create the bitmap with window size
							bd = bData.clone()
							
							// no loop, since no pan/zoom
							loop = false
							duration = 0;

						}
							
						// fix the scaler ration
						scaler.ratio = 1
						
						// draw the target
						bd.draw(item,sM,null,null,null)
						
						// replace target with bitmap
						delete item
						delete target.item
						target.item = bd
												
					}
				}
			}
			
		}
		
		// get a scaler object
		protected function getScaler() {
		
			var lastRatio:Number = 0
			
			// deal with loop
			if (conf.repeat == 0) {
				// first run, create the scaler
				conf.scaler = {}
			} else {
				// not first run, save last scale ratio
				lastRatio =  conf.scaler.ratio
			}
			
			with (conf) {
				
				// get the scaler using conf options
				scaler = Geom.getScaler(zoom ? "fill" : scale,align.w,align.h,w,h,target.width,target.height)
					
				if (pan) {
					// pan enabled, fix zoom if disabled
					if (!scaler.zoom) scaler.zoom = 0
					
					var zmode = zoom;
					
					// get the zoom increment using selected zoom mode
					with (scaler) {
						switch (zmode) {
							case "out":
								zoom = (1-ratio)/duration
								conf.zoom = "random"
							break;
							case "in":
								zoom = (ratio-1)/duration
								conf.zoom = "random"
								ratio = 1
							break;
							case "random":
								var zoomTo:Number = Math.random()*(1-ratio)
								if (repeat == 0) {
									zoom = zoomTo/duration
								} else {
									zoom = (zoomTo+ratio-lastRatio)/duration
									ratio = lastRatio							
								}
							break;
							default:
								zoom = 0
						}
					
					}
						
				}
				// save pan settings in scaler
				scaler.pan = pan
				
				// reset counter
				counter = 0
				
				// update runs count
				repeat ++
			}
		}
		
		// this one will invert pan/zoom direction in loop mode
		public function invert() {
			with (conf) {
				
				// new align is previous pan
				align.w = pan.w
				align.h = pan.h
					
				// change one axis at a time
				var d:String = (repeat % 2 == 1 ) ? "w" : "h"
					
				// if no zoom and current axe cannot pan, try other one
				if (!zoom && scaler.diff[d] == 0) d = d == "w" ? "h" : "w";
				
				// set new pan value
				switch (pan[d]) {
					case "bottom":
					case "right":
						pan[d] = d == "w" ? "left" : "top"
					break
					default:
						pan[d] = d == "w" ? "right" : "bottom"
				}
					
			}
			// get the scaler using new values
			getScaler()
		}
		
		// destructor
		public function destroy() {
			bData.dispose();
			if (target.item is BitmapData) {
				target.item.dispose();
			}
		}
		
		// update pan/zoom animation
		public function update() {
			if ((conf.counter > conf.duration)) {
				// animation ended: if no loop, bye 
				if (!conf.loop) return
				// if pan enabled, invert direction
				if (conf.pan) invert()
			}
			
			
			var counter:Number = conf.counter
			var duration:Number = conf.duration
			
			with (conf.scaler) {
				if (pan) {
					// pan enabled
					// if zoom, increment ratio
					if (zoom) ratio += zoom
					
					// max x,y offsets
					var n = {w:w-target.width*ratio,h:h-target.height*ratio}
					
					// compute actual x,y offsets using pan and alignment settings
					for (var d in align) {
						offset[d] = 0
						switch (align[d]) {
							case "top":
							case "left":
								switch (pan[d]) {
									case "center":
										// left -> center
										offset[d] = n[d]*counter*0.5/duration
									break;
									case "bottom":
									case "right":
										// left -> right
										offset[d] = n[d]*counter/duration		
								}
							break;
							case "center":
								switch (pan[d]) {
									case "top":
									case "left":
										// center -> left
										offset[d] = n[d]*(duration-counter)*0.5/duration
									break;
									case "center":
										// center -> center
										offset[d] = n[d]*0.5
									break;
									case "bottom":
									case "right":
										// center -> right
										offset[d] = n[d]*(duration+counter)*0.5/duration
								}
							break;						
							case "bottom":
							case "right":
								switch (pan[d]) {
									case "top":
									case "left":
										// right -> left
										offset[d] = n[d]*(duration-counter)/duration
									break;
									case "center":
										// right -> center
										offset[d] = n[d]*(duration-counter*0.5)/duration										
									break;
									case "bottom":
									case "right":
										// right -> right
										offset[d] = n[d]
								}				
						}
					
					}
					
				}
			}
			
			// lock and clear bitmap
			bData.lock()
			bData.fillRect(bData.rect,0)
			
			if (!(conf.zoom || conf.animated)) {
				// if here, target is bitmap and no zoom requested
				// use the computed offsets to define the copy region
				if (conf.pan) {
					box.x = -int(conf.scaler.offset.w+.5)
					box.y = -int(conf.scaler.offset.h+.5)
				}
				// copy box from target to screen
				bData.copyPixels(target.item,box,Geom.origin);
			} else {
				// if here, we need to redraw item
				bData.draw(target.item,Geom.getScaleMatrix(conf.scaler),null,null,null)
			}
			// unlock bitmap
			bData.unlock()
			
			// update counter
			conf.counter++
		
		}
		
		
		
	
	}

}
	