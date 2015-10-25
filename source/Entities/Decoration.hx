package;

import utils.tiled.TiledImage;

class Decoration extends SceneEntity
{
	public function new(X : Float, Y : Float, World : World, Scene : TiledScene, Image : TiledImage)
	{
		// Correct by the offset
		super(X + Image.offsetX, Y + Image.offsetY, World, Scene);
		
		loadGraphic(Image.imagePath);
		setSize(Image.width, Image.height);
		offset.set(Image.offsetX, Image.offsetY);
		
		solid = false;
		immovable = true;
	}
}