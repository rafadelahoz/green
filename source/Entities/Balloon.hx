package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;

class Balloon extends Entity
{
	public var SlowedTime : Float = 0.25;
	public var Speed : Float = 35;

	public var slowed : Bool;
	public var timer : FlxTimer;

	public function new(X : Float, Y : Float, World : World)
	{
		super(X, Y, World);

		makeGraphic(14, 18, 0xFFFF004D);

		allowCollisions = FlxObject.UP;

		immovable = true;

		slowed = false;
		timer = null;
	}

	override public function update(elapsed : Float)
	{
		if (!inWorldBounds() && y < FlxG.camera.scroll.y)
			kill();

		// Float away
		if (!slowed)
			velocity.y = -Speed;

		// If we have load, center it on yourself
		if (isTouching(FlxObject.UP) && overlapsAt(x, y-1, world.player))
		{
			var lerpedX : Float = FlxMath.lerp(world.player.getMidpoint().x, getMidpoint().x, 0.5);
			var deltaX : Float = lerpedX - world.player.getMidpoint().x;

			world.player.x += deltaX;
		}

		// If the load just arrived, pause a bit
		if (justTouched(FlxObject.UP))
		{
			slowed = true;
			velocity.y = 0;
			if (timer == null)
			{
				timer = new FlxTimer();
				timer.start(SlowedTime, function(_t:FlxTimer) {
					timer = null;
					slowed = false;
				});
			}
		}

		super.update(elapsed);
	}
}
