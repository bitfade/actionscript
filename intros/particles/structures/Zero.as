/*

	Particles structure builder: Zero

*/
package bitfade.intros.particles.structures {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Zero {
		public static function build(MAX_PARTICLES:uint):LinkedListPool {
		
			var p3dList:LinkedListPool = new LinkedListPool(Particle3dLife,Single.instance("Particle3dStack",Stack))
				
			var node: Particle3dLife 
  			
  			for (var i:uint = 0;i<MAX_PARTICLES; i++) {
  				node = p3dList.create()
  				
  				node.x = 0
  				node.y = 0
  				node.z = 0 				
  				node.life = 0
 	
  				p3dList.append(node)
  			}
			
			
			
			return p3dList
		}
	}

}
/* commentsKO */