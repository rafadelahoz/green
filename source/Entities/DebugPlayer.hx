package;

import flixel.FlxG;
import flixel.FlxObject;

class DebugPlayer extends Player
{
	public var Speed : Float = 200;

	public function new(X : Float, Y : Float, World : World)
	{
		super(X, Y, World);

		makeGraphic(16, 16, 0xFFFFFFFF);
		offset.set(0, 0);

		overridenControl = true;
	}

	override public function update(elapsed : Float)
	{
		if (FlxG.keys.pressed.UP)
			velocity.y = -Speed;
		else if (FlxG.keys.pressed.DOWN)
			velocity.y = Speed;
		else
			velocity.y = 0;

		if (FlxG.keys.pressed.LEFT)
		{
			velocity.x = -Speed;
			facing = FlxObject.LEFT;
		}
		else if (FlxG.keys.pressed.RIGHT)
		{
			velocity.x = Speed;
			facing = FlxObject.RIGHT;
		}
		else
			velocity.x = 0;

		super.update(elapsed);
	}
}
