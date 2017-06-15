/*

	Base class for effects

*/
package bitfade.effects {
	
	import flash.display.*
	import flash.utils.*
	
	import bitfade.core.*
	import bitfade.intros.Intro
	import bitfade.utils.*
	import bitfade.easing.*
	import bitfade.data.*
	import bitfade.effects.queue.*
	
	public class Effect extends Sprite implements bitfade.core.IDestroyable {
	
		// effect target
		public var target:DisplayObject
		
		// effects queue
		protected var queue:LinkedListPool
		protected var item: EffectQueueNode
		protected var active: Effect
		protected var firstRun: Boolean = false
		
		// worker function
		protected var worker: Function
		
		// call on effect's end
		protected var onCompleteCallback:Function
		
		// compute pause timings
		protected var paused:Boolean
		protected var pauseStart:uint = 0
		protected var pausedFor:uint = 0
		
		// effect manager
		protected var managerLoop:RunNode
	
		// ease function
		public var ease: Function = bitfade.easing.Linear.In
	
		public var duration:Number = 0
		public var begin:Number = 0
	
		// constructor
		public function Effect(t:DisplayObject = null) {
			super()
			target = t
			build()
		}
		
		// build the effect
		protected function build():void {
			if (target) addChild(target)
		}
		
		// static creator
		public static function create(...args):Effect {
			return Effect.factory(Effect,args)
		}
		
		// create an effect's instance 
		protected static function factory(effectClass:Class,args:Array):Effect {
			var t : DisplayObject
			if (args[0] is DisplayObject) {
				t = args.shift()
			}
			// pool ?
			return (new effectClass(t)).actions.apply(null,args)
		}
		
		// call next effect in queue
		protected function next() {
			if (queue.empty) {
				if (onCompleteCallback != null) onCompleteCallback(this)
				destroy()
			} else {	
				// get node
				queue.shift(item)
				// set worker
				worker = null_worker
				// initialize
				active = item.method.apply(null,item.params)
				active.duration = item.params[0]*1000
				active.begin = getTimer()
				pausedFor = 0
				active.firstRun = true
			}
		}
		
		// start the queue
		public function start(...args):Effect {
			if (queue.empty) return this
			item = queue.create()
			next()
			managerLoop = Run.every(Run.FRAME,manager)
			return this
		}
		
		// handle effect queue
		protected function manager():void {
			
			// do nothing
			if (paused || !active) return
			
			// compute current time
			var elapsed:Number = getTimer() - active.begin - pausedFor
			var time:Number 
			
			if (active.firstRun) {
				time = 0
				active.firstRun = false
			} else {
				time = elapsed/active.duration
				time = ease(time,0,1,1)
				if (time > 0.98) time = 1
			}
			
			if (time < 1) {
				active.worker(time)
			} else {
				active.worker(1)
				//if (active.onCompleteCallback) active.onCompleteCallback(this)
				next()
			}
			
		}
		
		// do nothing
		public function wait(...args):Effect {
			return this
		}
		
		// set callBack
		public function onComplete(callBack:Function):Effect {
			onCompleteCallback = callBack
			return this
		}
		
		// do nothing
		protected function null_worker(t:Number) {
		}
		
		// get effect queue
		public function getQueue():LinkedListPool {
			return queue
		}
		
		// reset queue
		public function reset():void {
			if (queue) {
				queue.destroy()
				queue = undefined
			}
		}
		
		// build the queue
		public function actions(...args):Effect {
			
			if (!queue) queue = new LinkedListPool(EffectQueueNode,"method","params")
			
			var qNode:EffectQueueNode;
			var current:*
			var params:*
				
			while (current = args.shift()) {
				
				if (current is Effect) {
					// merge the effect's queues
					queue.merge(current.getQueue())
					current.reset()
				} else if (hasOwnProperty(current)) {
					// add effect node
					params = args.shift()
					if (!(params is Array)) params = [params]
				
					qNode = queue.create()
					qNode.method = this[current]
					qNode.params = params
					queue.append(qNode)
				}
			}
				
		
			return this
		}
		
		public function get realWidth():uint {
			return target.width
		} 
		
		public function get realHeight():uint {
			return target.height
		}
		
		// pause
		public function pause():void {
			paused = true
			pauseStart = getTimer()
		}
		
		// resume
		public function resume():void {
			paused = false
			pausedFor += (getTimer()-pauseStart)
		}
		
		// destruct effect
		public function destroy():void {
			if (managerLoop) managerLoop = Run.reset(managerLoop)
			if (target && contains(target)) removeChild(target)
			Gc.destroy(this)
		}
		
		
		
	}
}
/* commentsOK */