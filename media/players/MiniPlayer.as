/*

	Mini video player with basic controls

*/
package bitfade.media.players {
	
	import flash.display.*
	import flash.events.*
	import flash.geom.*
	
	import bitfade.ui.core.*
	import bitfade.media.players.*
	import bitfade.media.streams.*
	import bitfade.ui.icons.*
	import bitfade.ui.*
	import bitfade.utils.*
	import bitfade.easing.*
	
	public class MiniPlayer extends SimpleVideo {
	
		protected var controlsLayer:Sprite;
		protected var playControl:bitfade.ui.icons.BevelGlow
		protected var pauseControl:bitfade.ui.icons.BevelGlow
		protected var closeControl:bitfade.ui.icons.BevelGlowText
		protected var seekControl:bitfade.ui.Slider
		protected var hideControlsRun:RunNode;
			
		public function MiniPlayer(w:uint,h:uint,startPaused:Boolean = false,useSpinner:Boolean = true) {
			super(w,h,startPaused,useSpinner)
		}
		
		override protected function init(w:uint,h:uint,startPaused:Boolean = false,useSpinner:Boolean = true):void {
			super.init(w,h,startPaused,useSpinner)
			buildControls()
		}
		
		protected function buildControls() {
			controlsLayer = new Sprite();
			controlsLayer.blendMode = "layer"
			
			addChild(controlsLayer)
			swapChildren(topLayer,controlsLayer)
 			
			
			bitfade.utils.Events.add(controlsLayer,[
					MouseEvent.ROLL_OUT,
					MouseEvent.ROLL_OVER,
					MouseEvent.MOUSE_DOWN,
					MouseEvent.MOUSE_OVER,
					MouseEvent.MOUSE_OUT
			],evHandler,this)
			
			
			playControl = new bitfade.ui.icons.BevelGlow("play","play",16)
			pauseControl = new bitfade.ui.icons.BevelGlow("pause","pause",16)
			playControl.visible = false
			
			
			seekControl = new bitfade.ui.Slider(200,20,4)
			seekControl.x = playControl.width + 2
			seekControl.y = (playControl.height - seekControl.height) >> 1
			
			seekControl.name = "seek"
			
			controlsLayer.addChild(playControl)
			controlsLayer.addChild(pauseControl)
			
			var ch:uint = controlsLayer.height
			
			controlsLayer.addChild(seekControl)
			
			closeControl = new bitfade.ui.icons.BevelGlowText("exit","EXIT",16,24,false)
			closeControl.x = controlsLayer.width+8
			controlsLayer.addChild(closeControl)
			
			var gfx:Graphics = controlsLayer.graphics
			
			gfx.beginFill(0,.5) 
			gfx.drawRoundRect(-8,(ch - controlsLayer.height) >> 1,controlsLayer.width+16,controlsLayer.height,8,8)
			gfx.endFill()
			
			scrollRect = new Rectangle(0,0,w,h)
			
			controlsLayer.x = (w-controlsLayer.width) >> 1
			controlsLayer.y = (h - ch)
			
			var empty:bitfade.ui.Empty = new bitfade.ui.Empty(controlsLayer.width+16,controlsLayer.height+8,true)
			empty.mouseEnabled = false
			empty.x = (controlsLayer.width - empty.width) >> 1
			empty.y = (controlsLayer.height - empty.height) 
			controlsLayer.addChild(empty)
			
			
			FastTw.tw(this).params(.5,Linear.In)
			FastTw.tw(controlsLayer).params(.5,Linear.In,false)
		}
		
		// add event listeners
		override protected function addEventListeners():void {
			super.addEventListeners()
			bitfade.utils.Events.add(controlStream,StreamEvent.GROUP_PROGRESS,updateBar,this)
		}
		
		override protected function setVisual():void {
			super.setVisual()
			if (vid) {
				vid.mouseChildren = vid.mouseEnabled = true
				//swapChildren(vid,controlsLayer)
			}
		}
		
		override protected function streamEventHandler(e:StreamEvent):void {
			super.streamEventHandler(e)
			
			switch (e.type) {
				case StreamEvent.PLAY: 
					dispatchEvent(new PlayerEvent(PlayerEvent.PLAY))
				break;
				case StreamEvent.STOP:
					// check for loop
					onStreamEnd()
				break;
				
			}			
		}
		
		// toggle pause / play
		public function toggle():void {
			if (controlStream && controlStream.paused) {
				resume()
			} else {
				pause()
			}
		}
		
		override public function load(url:String):void {
			super.load(url)
			seekControl.start(0)
			seekControl.pos(0,0)
		} 
		
		
		// pause playback
		override public function pause():void {
			super.pause()
			togglePlayControl()
		}
		
		// resume playback
		override public function resume():void {
			super.resume()
			togglePlayControl()
		}
		
		public function toggleVisibility(s:Boolean = true):void {
			if (s) {
				controlsLayer.alpha = 0
				showControls()
				if (!visible) alpha = 0
				FastTw.tw(this).alpha = 1
			} else {
				FastTw.tw(this).alpha = 0
			}
		}
		
		public function toggleControls(s:Boolean):void {
			if (s) {
				if (controlsLayer.alpha < 1) FastTw.tw(controlsLayer).alpha = 1
			} else {
				if (controlsLayer.alpha > 0) FastTw.tw(controlsLayer).alpha = 0
			}
			if (s) {
				Run.reset(hideControlsRun)
				hideControlsRun = Run.after(2,hideControls)
			}
		}
		
		public function showControls():void {
			toggleControls(true)
		}
		
		public function hideControls():void {
			toggleControls(false)
		}
		
		public function show() {
			toggleVisibility(true)
		}
		
		public function hide() {
			toggleVisibility(false)
		}
		
		// toggle play/pause controls
		protected function togglePlayControl():void {
			var isPaused:Boolean = false
			var isBuffering:Boolean = false
			
			if (controlStream) {
				isPaused = controlStream.paused || controlStream.stopped 
				isBuffering = controlStream.buffering
			}
			
			playControl.visible = !isBuffering && isPaused
			pauseControl.visible = !playControl.visible
			
		}
		
		protected function evHandler(e:MouseEvent) {
			var mouseOver:Boolean
			var id:String = e.target.name;
			
			e.stopPropagation()
			e.stopImmediatePropagation()
			
			switch (e.type) {
				case MouseEvent.ROLL_OUT:
				case MouseEvent.ROLL_OVER:
					if (e.type == MouseEvent.ROLL_OVER) {
						showControls()
						Run.pause(hideControlsRun)
					} else {
						Run.resume(hideControlsRun)
					}
				break;
				case MouseEvent.MOUSE_OVER:
				case MouseEvent.MOUSE_OUT:
					mouseOver = (e.type == MouseEvent.MOUSE_OVER)
					
					if (e.target is bitfade.ui.core.IMouseOver) {
						e.target.over(mouseOver)
					}
				break;
				case MouseEvent.MOUSE_DOWN:
					switch (id) {
						case "play":
						case "pause":
							toggle()
						break;
						case "seek":
							seek(e.localX/seekControl.width)
						break;
						case "exit":
							hide()
							Run.after(.5,close)
							dispatchEvent(new PlayerEvent(PlayerEvent.CLOSE))
						break;
					}
				break;
			}
			
			
		}
		
		// update progress bar
		protected function updateBar(e:StreamEvent):void {
			switch (e.type) {
				case StreamEvent.START_POS:
					seekControl.start(e.value)
				break;
				case StreamEvent.PROGRESS:
					seekControl.pos(e.value)
				break;
				case StreamEvent.POSITION:
					//if (dragging != SEEK) {
						seekControl.pos(-1,e.value)
					//}
				break;
			}
		}
		
		//fireEvent(PlayerEvent.PLAY,0)
		
	}
}
/* commentsOK */