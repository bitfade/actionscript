/*

	Particles structure builder: DNA

*/
package bitfade.intros.particles.structures {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Dna {
		public static function build(MAX_PARTICLES:uint):LinkedListPool {
		
			var p3dList:LinkedListPool = new LinkedListPool(Particle3dLife,Single.instance("Particle3dStack",Stack))
				
			var node: Particle3dLife 
  			
  			var dy : Number = 800/(MAX_PARTICLES)
  			var py : Number = -400
  			var angle: Number = 0
  			
  			var rnd:Number 
  			
  			
  			for (var i:uint = 0;i<MAX_PARTICLES; i++,py += dy) {
  				node = p3dList.create()
  				
  				angle = (i*Math.PI)/MAX_PARTICLES
  				
  				rnd = 20+30*i/MAX_PARTICLES
  				
  				node.x = rnd*Math.sin(2*angle+(i % 4)*(2/4)*Math.PI)+Math.random()*10-5
  				node.y = py
  				node.z = rnd*Math.cos(2*angle+(i % 4)*(2/4)*Math.PI)+Math.random()*10-5
  				
  				
  				node.life = Math.random()*400+100
  				
  			
  				  				
  				p3dList.append(node)
  			}
			
			
			
			return p3dList
		}
	}

}