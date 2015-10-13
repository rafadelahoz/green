package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;
import flixel.group.FlxGroup;

class World extends FlxState
{
	public var player : Player;

	public var ground : FlxGroup;

	override public function create():Void
	{
		super.create();

		player = new Player(FlxG.width / 2, FlxG.height / 2, this);
		add(player);

		var g : FlxSprite = new flixel.FlxSprite(0, FlxG.height - 48).makeGraphic(FlxG.width, 48, 0xFF000000);

		ground = new FlxGroup();
		ground.add(g);

		add(ground);
	}
	
	override public function destroy():Void
	{
		super.destroy();
	}

	override public function update():Void
	{
		FlxG.collide(player, ground);

		super.update();
	}	
}