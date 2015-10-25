package;

class SceneEntity extends Entity
{
	public var scene : TiledScene;
	
	public function new(X : Float, Y : Float, World : World, Scene : TiledScene)
	{
		super(X, Y, World);
		
		scene = Scene;

		trace("New SceneEntity@" + scene.name);
	}
}