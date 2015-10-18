package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;

import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;
import flixel.group.FlxGroup;

import text.TextBox;

class World extends FlxState
{
	public var player : Player;

	public var ground : FlxGroup;

	public var elements : FlxGroup;

	override public function create():Void
	{
		super.create();
		
		// bgColor= 0xFF222202;
		
		TextBox.Init(this);
		GamePad.init();
		
		FlxG.scaleMode = new flixel.system.scaleModes.PixelPerfectScaleMode();
		// FlxG.fixedTimestep = false;
		// FlxG.scaleMode = new flixel.system.scaleModes.StageSizeScaleMode();
		
		player = new Player(FlxG.width / 2, 0, this);
		add(player);
		
		FlxG.watch.add(player, "x");
		FlxG.watch.add(player, "y");
		FlxG.watch.add(player, "velocity");
		FlxG.watch.add(player, "onAir");
		FlxG.watch.add(FlxG, "worldBounds");

		elements = new FlxGroup();
		add(elements);

		var g : FlxSprite = new FlxSprite(0, FlxG.height - 48).makeGraphic(4000, 2, 0xFF83769C);
		g.solid = true;
		g.immovable = true;
		
		ground = new FlxGroup();
		ground.add(g);

		g = new FlxSprite(0, 0).makeGraphic(96, FlxG.height, 0xFF83769C);
		g.immovable = true;
		ground.add(g);

		g = new FlxSprite(FlxG.width - 96, 0).makeGraphic(96, FlxG.height, 0xFF83769C);
		g.immovable = true;
		ground.add(g);

		add(ground);

		FlxG.camera.setBounds(0, 0, 4000, FlxG.height + 48, true);
		// FlxG.camera.follow(player, FlxCamera.STYLE_PLATFORMER, null, 14);
	}
	
	override public function destroy():Void
	{
		super.destroy();
	}

	override public function update():Void
	{
		GamePad.update();
		
		FlxG.collide(ground, player);
		FlxG.collide(elements, player);

		super.update();

		debugRoutines();
	}	

	function debugRoutines()
	{
		var mousePos : FlxPoint = FlxG.mouse.getWorldPosition();

		if (FlxG.mouse.justPressed)
		{
			elements.add(new Balloon(mousePos.x, mousePos.y, this));
		}
	}
}