package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;

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
		
		FlxG.scaleMode = new flixel.system.scaleModes.PixelPerfectScaleMode();
		
		player = new Player(FlxG.width / 2, FlxG.height / 2, this);
		add(player);
		
		FlxG.watch.add(player, "x");
		FlxG.watch.add(player, "y");
		FlxG.watch.add(FlxG, "worldBounds");

		var g : FlxSprite = new flixel.FlxSprite(0, FlxG.height - 48).makeGraphic(4000, 48, 0x00141114);
		g.immovable = true;
		
		ground = new FlxGroup();
		ground.add(g);

		add(ground);
		
		FlxG.camera.setBounds(0, 0, 4000, FlxG.height + 48, true);
		FlxG.camera.follow(player, FlxCamera.STYLE_PLATFORMER, null, 14);
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