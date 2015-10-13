package;

import flixel.FlxObject;

class Player extends Entity
{
	public var Gravity : Float = 600;

	public function new(X : Float, Y : Float, World : World)
	{
		super(X, Y, World);

		makeGraphic(16, 16, 0xFF8AF507);
	}

	override public function update()
	{
		acceleration.y = Gravity;

		if (isTouching(FlxObject.DOWN)) {
			acceleration.y = 0;
		}

		super.update();
	}
}