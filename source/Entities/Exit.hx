package;

import flixel.FlxObject;
import flixel.FlxSprite;

class Exit extends Entity
{
	public var direction : Int;
	public var target : String;
	public var hops : Int;

	public var floor : FlxSprite;

	public function new(X : Float, Y : Float, World : World, Width : Float, Height : Float)
	{
		super(X, Y, World);

		visible = false;
		setSize(Width, Height);

		immovable = true;
	}

	public function init(direction : String, target : String, hops : Int)
	{
		this.direction = parseDirection(direction);
		this.target = target;
		this.hops = hops;
	}

	static function parseDirection(dir : String) : Int
	{
		switch (dir)
		{
			case "left":
				return FlxObject.LEFT;
			case "right":
				return FlxObject.RIGHT;
			default:
				return FlxObject.NONE;
		}
	}
}