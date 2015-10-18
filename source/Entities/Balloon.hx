package;

import flixel.FlxObject;

class Balloon extends Entity
{
	public function new(X : Float, Y : Float, World : World)
	{
		super(X, Y, World);

		makeGraphic(16, 24, 0xFFFF004D);

		allowCollisions = FlxObject.UP;

		immovable = true;
	}
}