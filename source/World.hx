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
	public var decoration : FlxGroup;
	public var elements : FlxGroup;
	public var exits : FlxGroup;
	public var scene : TiledScene;
	public var nextScene : TiledScene;

	override public function create():Void
	{
		super.create();
		
		TextBox.Init(this);
		GamePad.init();
		
		FlxG.scaleMode = new flixel.system.scaleModes.PixelPerfectScaleMode();
		
		scene = new TiledScene("assets/scenes/0.tmx");
		add(scene.backgroundTiles);

		player = new Player(FlxG.width / 2, 0, this);
		add(player);
		
		FlxG.watch.add(player, "x");
		FlxG.watch.add(player, "y");
		FlxG.watch.add(player, "velocity");
		FlxG.watch.add(player, "onAir");
		FlxG.watch.add(FlxG, "worldBounds");

		decoration = new FlxGroup();
		add(decoration);

		elements = new FlxGroup();
		add(elements);

		exits = new FlxGroup();
		add(exits);

		scene.loadObjects(this);

		ground = new FlxGroup();
		add(ground);

		add(scene.overlayTiles);

		FlxG.camera.setBounds(-2000, 0, 4000, FlxG.height + 48, true);
		FlxG.camera.follow(player, FlxCamera.STYLE_PLATFORMER, null, 14);
	}
	
	override public function destroy():Void
	{
		super.destroy();
	}

	override public function update():Void
	{
		GamePad.update();
		
		scene.collideWithLevel(player);
		FlxG.collide(ground, player);
		FlxG.collide(elements, player);

		FlxG.overlap(exits, player, onPlayerExitCollision);

		super.update();

		debugRoutines();
	}	

	function onPlayerExitCollision(exit : Exit, player : Player)
	{
		if (player.facing == exit.direction)
		{
			if (exit.floor == null)
			{
				trace("exit");
				var length : Int = exit.hops * 100;

				var floor : FlxSprite = null;
				switch (exit.direction)
				{
					case FlxObject.RIGHT:
						floor = new FlxSprite(exit.x, exit.y + exit.height).makeGraphic(length, 32, 0xFF83769C);
					case FlxObject.LEFT:
						floor = new FlxSprite(exit.x - length, exit.y + exit.height).makeGraphic(length, 32, 0xFF83769C);
				}

				floor.immovable = true;

				exit.floor = floor;
				trace(exit.floor);

				ground.add(floor);

				nextScene = new TiledScene("assets/scenes/" + exit.target + ".tmx");
				nextScene.backgroundTiles.x = exit.x + length;
				add(nextScene.backgroundTiles);
				nextScene.loadObjects(this);

				exits.remove(exit);
			}
		}
	}

	function prepareDebugScene()
	{
		var g : FlxSprite = new FlxSprite(-2000, FlxG.height - 48).makeGraphic(6000, 2, 0xFF83769C);
		g.solid = true;
		g.immovable = true;
		
		ground.add(g);

		g = new FlxSprite(0, 0).makeGraphic(96, FlxG.height, 0xFF83769C);
		g.immovable = true;
		ground.add(g);

		g = new FlxSprite(FlxG.width - 96, 0).makeGraphic(96, FlxG.height, 0xFF83769C);
		g.immovable = true;
		ground.add(g);
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