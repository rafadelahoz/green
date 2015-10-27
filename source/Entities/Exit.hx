package;

import flixel.FlxObject;
import flixel.FlxSprite;

class Exit extends SceneEntity
{
	public var name : String;
	public var direction : Int;

	public var floor : FlxSprite;

	public function new(X : Float, Y : Float, World : World, Scene : TiledScene, Width : Float, Height : Float)
	{
		super(X, Y, World, Scene);

		visible = true;
		makeGraphic(Std.int(Width), Std.int(Height), 0x00000001);
		setSize(Width, Height);

		immovable = true;
	}

	public function init(name : String, direction : String)
	{
		this.name = name;
		this.direction = parseDirection(direction);
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