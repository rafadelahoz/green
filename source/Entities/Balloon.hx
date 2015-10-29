package;

import flixel.FlxObject;

class Balloon extends Entity
{
	public var Speed : Float = 35;
	
	public function new(X : Float, Y : Float, World : World)
	{
		super(X, Y, World);

		makeGraphic(14, 18, 0xFFFF004D);

		allowCollisions = FlxObject.UP;

		immovable = true;
	}
	
	override public function update()
	{
		velocity.y = -Speed;
		
		if (!inWorldBounds())
			kill();
			
		super.update();
		
		if (justTouched(FlxObject.UP))
		{
			velocity.y = Speed/2;
		}
	}
}