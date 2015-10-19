package;

import utils.tiled.TiledImage;

class Decoration extends Entity
{
	public function new(X : Float, Y : Float, World : World, Image : TiledImage)
	{
		// Correct by the offset
		super(X + Image.offsetX, Y + Image.offsetY, World);
		
		loadGraphic(Image.imagePath);
		setSize(Image.width, Image.height);
		offset.set(Image.offsetX, Image.offsetY);
		
		solid = false;
		immovable = true;
	}
}