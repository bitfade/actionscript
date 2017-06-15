package bitfade.showcase { 
	import flash.display.*
	import flash.events.*;
	import flash.text.*;
	import flash.utils.*
	import flash.geom.*
	import flash.filters.*
	
	import caurina.transitions.Tweener;
	
	import bitfade.ui.*
	
	public class flashden extends MovieClip {
		[Embed(source="../../common/icons/left.png")]
		protected static const leftImg:Class;
		
		[Embed(source="../../common/icons/right.png")]
		protected static const rightImg:Class;
		
		[Embed(source="../../common/icons/menu.png")]
		protected static const menuImg:Class;
		
		protected static const help:Object = {
			open: "Click to open selection menu or use prev/next to change example",
			close: "Click to close and return to current example",
			next: "Click to select next example",
			prev: "Click to select previous example"
		}
		
		protected var description:button;
		protected var head:Sprite
		protected var menu:Sprite
		protected var ads:Sprite
		protected var frame:Sprite
		protected var container:Sprite
		protected var controls:Sprite
		protected var examples:Array
		protected var buttons:Array
		protected var helpMsg:String;
		protected var adLabel:noAAText;
		protected var changeColor:Function
		
		protected var idx:uint=0;
		
		
		protected var w:uint = 590;
		protected var h:uint = 300;
		
		protected var bMap:Bitmap;
		protected var bData:BitmapData;
		
		protected var selectMode:Boolean = false
		protected var doUpdate:Boolean = false
		protected var activeTween:uint = 0
		protected var tim:Timer
		
		protected var fadeCT:ColorTransform;
		protected var bF:BlurFilter;
			
		
		function flashden() {
		
			stage.scaleMode = "noScale";
			stage.align = "TL";
						
			fadeCT = new ColorTransform(1,1,1,.6,0,0,0,0);
			bF = new BlurFilter(8,8,1);
			
						
			frame = new Sprite()
			container = new Sprite();
			head = new Sprite()
			menu = new Sprite()
			ads = new Sprite()
			controls = new Sprite();
			
			addChild(frame)
			
			var gradM = new Matrix();
			
			gradM.createGradientBox(w,h/2, Math.PI/2, 0, 0);
			
			with (frame.graphics) {
				clear();
			
				beginGradientFill(
					GradientType.LINEAR, 
					[0x000000,0x000000,0x202020], 
					[1, 1, 1], 
					[0, 100,254], 
					gradM, 
					SpreadMethod.REFLECT
				);
				  
				drawRect(0, 0,w,h);
			
			}
			
			frame.addChild(container)
			addChild(controls)
			
			
			adLabel = new noAAText("",w,18,0,22)
			adLabel.mouseEnabled = true
			
			with (ads.graphics) {
				beginFill(0xFF0000,.5);			  
				drawRect(0, 20,w,20);
				endFill()
			}
			
            ads.addChild(adLabel);

			ads.visible = false
			addChild(ads)
			
			bMap = new Bitmap()
			bData = new BitmapData(w, h, true,0x000000);
			bMap.bitmapData = bData;
			
			addChild(bMap)
			
			addChild(menu)
			addChild(head)
			
			addEventListener(Event.ENTER_FRAME,update)
			
			buttons = new Array(examples.length)
			
			var hoverColor:uint
			var gradColor:uint
			
			for (var i:uint=0;i<examples.length;i++) {
				if (examples[i][3]) {
					gradColor = 0x400000
					hoverColor = 0x600000
				} else {
					gradColor = 0x404040
					hoverColor = 0x606060
				} 
				buttons[i] = new button(i,title(i,true),250,20,-250,-20,evHandler,gradColor,hoverColor);
				menu.addChild(buttons[i])
			}
			
			tim = new Timer(1200)
			tim.stop()
			tim.addEventListener(TimerEvent.TIMER, updateControl);
			
			drawHead()
			 
  		}
  		
  		protected function title(i=null,small=false):String {
  			if (i === null) i = idx;
  			
  			var msg:String = ""
  			
  			if (examples[i][3]) {
  				msg = "<font color=\"#FF0000\">"+ ((small) ? "AD. " :  " - ADVERTISEMENT - ") + "</font>"
  				ads.visible = true
  				adLabel.htmlText = "NOTE: for this example you also need: " + "<a target=\"_blank\" href=\"" + examples[i][4] + "\">" +  examples[i][3] + "</a>"
  			} else {
  				ads.visible = false
  			}
  			
  			return (
  				(small) ? 
  					((i+1) <= 9 ? "0" : "") + (i+1) + " - " + msg + examples[i][2] : 
  					"Example " + (i+1) + " of " + examples.length + " : " + msg + examples[i][1]
  				)
  		}
  		
  		protected function drawHead() {
  			
  			
			description = new button("title",title(0),w,20,0,0);
            head.addChild(description)	
  			
  			var mImg = new menuImg()
  			var mIcon = new Sprite()
  			
  			with (mIcon) {
  				x = w-mImg.width*3-7
  				y = 2
  				buttonMode = true
  				name = "menu"
  			
  				addChild(mImg)
  				addEventListener(MouseEvent.CLICK,evHandler)
  				addEventListener(MouseEvent.ROLL_OVER,evHandler)
  				addEventListener(MouseEvent.ROLL_OUT,evHandler)
  			}
  			
  			head.addChild(mIcon)
  			
  			var lImg = new leftImg()
  			var left = new Sprite()
  			
  			with (left) {
  				x = w-lImg.width*2-5
  				y = 2
  				buttonMode = true
  				name = "prev"
  			
  				addChild(lImg)
  				addEventListener(MouseEvent.CLICK,evHandler)
  				addEventListener(MouseEvent.ROLL_OVER,evHandler)
  				addEventListener(MouseEvent.ROLL_OUT,evHandler)
  			}
  			
  			head.addChild(left)
  			
  			var rImg = new rightImg()
  			var right = new Sprite()
  			
  			
  			with (right) {
  				x = w-rImg.width-3
  				y = 2
  				
  				buttonMode = true
  				name = "next"
  			
  				addChild(rImg)
  				addEventListener(MouseEvent.CLICK,evHandler)
  				addEventListener(MouseEvent.ROLL_OVER,evHandler)
  				addEventListener(MouseEvent.ROLL_OUT,evHandler)
  			}
  			
  			head.addChild(right)
  			
  		
  		}
  		
  		public function endTween() {
  			activeTween--
  			if (activeTween == 0 ) {
  				if (selectMode)	{
  					menu.visible = true
  				} else {
  					controls.visible = true
  				}
  				tim.start()
  			}
  		}
  		
  		protected function updateControl(e=null) {
  			tim.stop();
  			doUpdate = false
  			if (!selectMode) {
  				bMap.visible = false
  			}
  		}
  		
  		
  		
  		protected function showMenu() {
  			var xp:uint
  			var yp:uint
  		
  			tim.stop()
  			activeTween = examples.length
  			doUpdate = true;
  			bMap.visible = true;
  			
 			if (selectMode) {
 				// hide
 				menu.visible = false;
 				//removeChild(menu) 
 				for (var i:uint=0;i<examples.length;i++) {
 					
 					xp = i % 2 ? w-250 : 0 
					yp = uint(Math.random()*h)
					yp = h
 					
 					Tweener.addTween(buttons[i], {delay:i/(examples.length*2),x:xp,y:yp,alpha:0,time:0.5,transition:"easeOutSine",onComplete:endTween});
				}
 			} else {
 				// show
 				controls.visible = false;
  				for (var i:uint=0;i<examples.length;i++) {
  					yp = uint(i / 2)*25 + 50
  					xp = (i % 2) * 260 + 35
  					
  					with (buttons[i]) {
  						x = i % 2 ? w-250 : 0 
						y = uint(Math.random()*h)
						y = h
						alpha = 0 
  					}
					
					Tweener.addTween(buttons[i], {delay:i/(examples.length*2),x:xp,y:yp,alpha:1, time:0.5,transition:"easeOutSine",onComplete:endTween});
				}
  			}
  			selectMode = !selectMode
  		} 
  		
  		protected function changeExample(cIdx) {
  		
  			if (selectMode) showMenu()
  		
  			if (cIdx == "next") {
  				idx = (idx + 1) % examples.length
  			} else if (cIdx == "prev") {
  				idx = (idx > 0) ? idx - 1 : examples.length - 1
  			} else {
  				if ( idx == cIdx ) return 
  				idx = cIdx
  			}	
 			description.msg(title())
 			eff_reset()
 			this[examples[idx][0]]()
  		}
  		
  		protected function eff_reset() {
  		}
  		
  		protected function evHandler(e) {
  			
  			var target = e.target
  			var name = e.target.name
  		
  			switch (e.type) {
  				case MouseEvent.ROLL_OVER:
  					try { target.hover.visible = true } catch(e) {}
  					
  					if (name == "menu" ) {
  						description.msg(selectMode ? help.close : help.open)
  					} else if (name == "prev" || name == "next") {
  						description.msg(help[name])
  					}
  				break
  				case MouseEvent.ROLL_OUT:
  					try { target.hover.visible = false } catch(e) {}
  					description.msg(title())
  				break
  				case MouseEvent.CLICK:
  					
  					switch (name) {
  						case "menu" :
     						showMenu()
  							description.msg(selectMode ? help.close : help.open)
  						break
  						case "next" :
  							changeExample("next")
  						break
  						case "prev" :
  							changeExample("prev")
  						break
  						default:
  							changeExample(parseInt(name))
  					}
  				break 				
  			}
  		}
  		
  		protected function evColorHandler(e) {
  			var target = e.target
  			var name = e.target.name
  		
  			switch (e.type) {
  				case MouseEvent.ROLL_OVER:
  					target.hover.visible = true
  				break
  				case MouseEvent.ROLL_OUT:
  					target.hover.visible = false
  				break
  				case MouseEvent.CLICK:
  					changeColor(name)
  				break 				
  			}
  		}
  		
  		
  		
  		public function update(e=null) {
  			if (!doUpdate) return
  			bData.lock()
			
			bData.colorTransform(bData.rect,fadeCT);
			
			bData.applyFilter(bData,bData.rect,new Point(), bF);
			
			
			// draw our target using a different colorTrasform, so we can tweak more
			bData.draw(menu,null,null,null,bData.rect)
			// unlock the bitmap
			bData.unlock();
		}
	}
}