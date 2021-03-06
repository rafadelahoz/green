package;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;

import world.Node;

class World extends FlxState
{
	public var player : Player;
	public var ground : FlxGroup;
	public var decoration : FlxGroup;
	public var elements : FlxGroup;
	public var exits : FlxGroup;
	public var backgrounds : FlxGroup;

	public var SceneGraph : Map<String, Node>;
	public var currentSceneName : String;
	public var nextSceneName : String;
	public var traversingDirection : Int;
	public var currentScene : TiledScene;
	public var nextScene : TiledScene;

	public var currentBgColor : Int;
	public var targetBgColor : Int;

	public var currentGround : FlxObject;

	override public function create():Void
	{
		super.create();

		GamePad.init();

		FlxG.scaleMode = new flixel.system.scaleModes.PixelPerfectScaleMode();

		currentBgColor = 0xFF000000;
		targetBgColor = 0xFF000000;

		backgrounds = new FlxGroup();
		add(backgrounds);

		ground = new FlxGroup();
		add(ground);

		decoration = new FlxGroup();
		add(decoration);

		elements = new FlxGroup();
		add(elements);

		exits = new FlxGroup();
		add(exits);

		currentSceneName = null;
		nextSceneName = null;
		currentScene = null;
		nextScene = null;
		currentGround = null;

		loadScenesGraph();

		currentScene = loadScene(currentSceneName, 0, 0);
		updateBounds();

		createPlayer(currentScene.x + currentScene.fullWidth / 2, -10);

		// FlxG.camera.setBounds(-3750, 0, 10000, FlxG.height, true);
		focusCamera();

		FlxG.watch.add(FlxG.camera, "scroll");
	}

	override public function destroy():Void
	{
		super.destroy();
	}

	override public function update(elapsed : Float):Void
	{
		GamePad.update();

		// Background color lerp-ing
		lerpBgColors();

		// Lerp background images
		lerpBackgrounds();

		if (currentScene != null)
			currentScene.collideWithLevel(player);
		FlxG.collide(ground, player);
		FlxG.collide(elements, player);

		FlxG.overlap(exits, player, onPlayerExitCollision);

		super.update(elapsed);

		debugRoutines();
	}

	function lerpBgColors()
	{
		if (targetBgColor != -1 && targetBgColor != FlxG.camera.bgColor && currentGround != null)
		{
			var length : Int = Std.int(currentGround.width);
			var current : Int = 0;

			if (traversingDirection == FlxObject.RIGHT)
				current = Std.int(player.x - currentGround.x);
			else if (traversingDirection == FlxObject.LEFT)
				current = Std.int(currentGround.x + currentGround.width - player.x);

			if (current < 0)
				current = 0;
			if (current > length)
				current = length;

			var factor : Float = current/length;

			var color : Int = FlxColor.interpolate(currentBgColor, targetBgColor, factor);
			FlxG.camera.bgColor = color;
		}
	}

	function lerpBackgrounds()
	{
		if (currentGround != null && nextSceneName != currentSceneName)
		{
			var length : Int = Std.int(currentGround.width);
			var current : Int = 0;

			if (traversingDirection == FlxObject.RIGHT)
				current = Std.int(player.x - currentGround.x);
			else if (traversingDirection == FlxObject.LEFT)
				current = Std.int(currentGround.x + currentGround.width - player.x);

			if (current < 0)
				current = 0;
			if (current > length)
				current = length;

			var factor : Float = current/length;

			backgrounds.forEach(function(bg : FlxBasic) {
				if (Std.is(bg, FlxSprite))
				{
					// If it is a target background, increase its alpha
					if (nextScene.backgrounds.members.indexOf(bg) > -1)
					{
						cast(bg, FlxSprite).alpha = factor;
					}
					// For source backgrounds, decrease it
					else
					{
						cast(bg, FlxSprite).alpha = 1-factor;
					}
				}
			});
		}
	}

	function loadScene(sceneName : String, x : Int, y : Int, ?direction : Int = FlxObject.RIGHT,
						?floorHeight : Float = 0, ?exit : String = null) : TiledScene
	{
		var scene = new TiledScene(x, y, this, sceneName, (direction == FlxObject.LEFT), floorHeight, exit);

		if (scene != null)
		{
			add(scene.backgroundTiles);
			scene.loadObjects(this);
			for (bg in scene.backgrounds)
				backgrounds.add(bg);
			add(scene.overlayTiles);
		}

		trace("Loading scene " + sceneName + " at (" + scene.x + ", " + scene.y + ")");

		return scene;
	}

	function createPlayer(x : Float, y : Float)
	{
		player = new Player(x, y, this);
		add(player);

		FlxG.camera.focusOn(player.getMidpoint());

		FlxG.watch.add(player, "velocity");
		/*FlxG.watch.add(player, 	"x");
		FlxG.watch.add(player, 	"y");
		FlxG.watch.add(player, 	"onAir");*/
	}

	function focusCamera()
	{
		FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON, 0.02);
	}

	function onPlayerExitCollision(exit : Exit, player : Player)
	{
		var currentNode : Node = SceneGraph.get(currentSceneName);
		var nextSceneNode : Node = null;
		if (nextSceneName != null)
			nextSceneNode = SceneGraph.get(nextSceneName);

		// TODO: This condition can be substituted by checking the state (in-scene, between-scenes)
		if (player.facing == exit.direction)
		{
			if (!currentNode.exits.exists(exit.name))
			{
				trace("Invalid exit " + exit.name + " for current scene " + currentSceneName);

				player.velocity.x *= -1;
				return;
			}

			var exitData : ExitData = currentNode.exits.get(exit.name);

			// Exiting!
			if (currentGround == null)
			{
				nextSceneName = exitData.node;

				trace("Exiting towards " + nextSceneName);

				// Compute distance to next Scene
				var length : Int = exitData.hops * 32;

				// TODO: Compute appropriate scene X considering target exit X
				var targetSceneX : Int = -1;

				// Generate the floor that joins the two scenes
				var floor : FlxSprite = null;
				switch (exit.direction)
				{
					case FlxObject.RIGHT:
						floor = new FlxSprite(exit.x, exit.y + exit.height).makeGraphic(length, 32, 0x0083769C);
						targetSceneX = Std.int(exit.x + length);
					case FlxObject.LEFT:
						floor = new FlxSprite(exit.x - length, exit.y + exit.height).makeGraphic(length, 32, 0x0083769C);
						targetSceneX = Std.int(exit.x - length);
				}
				floor.immovable = true;

				// Store the traversing direction
				traversingDirection = exit.direction;

				// Store and set it
				currentGround = floor;
				ground.add(currentGround);

				// Load next scene tilemap & data at correct position
				var floorHeight : Float = exit.y + exit.height;
				nextScene = loadScene(exitData.node, targetSceneX, 0, exit.direction, floorHeight, exitData.exit);

				// Setup the background color
				targetBgColor = nextScene.backgroundColor;

				// And update the world bounds
				updateBounds();
			}
		}
		else if (player.facing == oppositeDirectionOf(exit.direction))
		{
			if (nextSceneName == null)
				return;

			if (nextSceneName != exit.scene.name)
			{
				trace("Returning to " + exit.scene.name);
				// return;
				nextSceneName = exit.scene.name;
				var oldNextScene : TiledScene = nextScene;
				nextScene = currentScene;
				currentScene = oldNextScene;
			}

			trace("Entering " + nextSceneName);

			if (nextSceneNode == null)
			{
				trace("Node not found: " + nextSceneName);
				return;
			}
			else if (!nextSceneNode.exits.exists(exit.name))
			{
				trace("Invalid entry " + exit.name + " for current scene " + nextSceneName);
				return;
			}

			// NextScene tilemap and entity data is already loaded
			// free currentScene
			currentScene.destroy();
			// set currentScene = nextScene
			currentScene = nextScene;
			// set nextScene = null
			nextScene = null;

			// set currentNode = nextNode
			currentSceneName = nextSceneName;
			// set nextNode = null
			nextSceneName = null;
			// destroy currentGround & currentGround = null
			if (currentGround != null)
			{
				ground.remove(currentGround);
				currentGround.destroy();
				currentGround = null;
			}

			// Setup background
			FlxG.camera.bgColor = currentScene.backgroundColor;
			currentBgColor = currentScene.backgroundColor;
			targetBgColor = -1;
		}
	}

	function updateBounds()
	{
		// Update camera and world bounds considering the current scenes
		var sceneBounds : FlxRect = currentScene.getBounds();

		var x1 : Float = sceneBounds.left;
		var y1 : Float = sceneBounds.top;
		var w : Float = sceneBounds.width;
		var h : Float = sceneBounds.height;

		if (nextScene != null)
		{
			var nextSceneBounds : FlxRect = nextScene.getBounds();

			x1 = Math.min(x1, nextSceneBounds.left);
			y1 = Math.min(y1, nextSceneBounds.top);

			var x2 : Float = Math.max(sceneBounds.right, nextSceneBounds.right);
			var y2 : Float = Math.max(sceneBounds.bottom, nextSceneBounds.bottom);

			w = x2 - x1;
			h = y2 - y1;
		}

		var padding : Float = FlxG.width;
		FlxG.camera.setScrollBoundsRect(x1 - padding, y1 - padding, w + padding * 2, h + padding);
		FlxG.worldBounds.set(x1 - padding, y1 - padding, w + padding * 2, h + padding);

		// trace("Cam bounds: " + FlxG.camera.bounds);
		// trace("World bounds: " + FlxG.worldBounds);
	}

	public static function oppositeDirectionOf(direction : Int) : Int
	{
		if (direction == FlxObject.LEFT)
			return FlxObject.RIGHT;
		else if (direction == FlxObject.RIGHT)
			return FlxObject.LEFT;
		else
			return FlxObject.NONE;
	}

	function loadScenesGraph()
	{
		SceneGraph = new Map<String, Node>();

		var s1 : Node = new Node("0");
		s1.exits.set("R1", { node : "1", exit : "L1", hops : 5 });
		s1.exits.set("L1", { node : "1", exit : "R2", hops : 5 });

		var s2 : Node = new Node("1");
		s2.exits.set("R1", { node : "0", exit : "L1", hops : 5 });
		s2.exits.set("L1", { node : "0", exit : "R1", hops : 5 });

		var s3 : Node = new Node("2");
		s3.exits.set("R1", { node : "2", exit : "L1", hops : 5 });
		s3.exits.set("L1", { node : "2", exit : "R1", hops : 5 });
		s3.exits.set("R2", { node : "0", exit : "L1", hops : 5 });

		var s4 : Node = new Node("4");
		s4.exits.set("R1", { node : "4", exit : "L1", hops : 5 });
		s4.exits.set("L1", { node : "4", exit : "R1", hops : 5 });

		var twoheights : Node = new Node("verticalL");
		twoheights.exits.set("TOP-L", { node : "top-passage", exit : "R", hops : 10 });
		twoheights.exits.set("TOP-R", { node : "descent",     exit : "L", hops : 10 });
		twoheights.exits.set("BOT-R", { node : "top-passage", exit : "L", hops : 10 });
		twoheights.exits.set("BOT-L", { node : "descent",     exit : "R", hops : 10 });

		var ascent : Node = new Node("top-passage");
		ascent.exits.set("L", { node : "long", exit : "R", hops : 6 });
		ascent.exits.set("R", { node : "verticalL", exit : "TOP-L", hops : 6 });

		var descent : Node = new Node("descent");
		descent.exits.set("L", { node : "verticalL", exit : "TOP-R", hops : 16 });
		descent.exits.set("R", { node : "long", 	 exit : "L", hops : 16 });

		var narrow : Node = new Node("narrow");
		narrow.exits.set("L1", { node : "narrow", exit : "R1", hops: 3 });
		narrow.exits.set("R1", { node : "narrow", exit : "L1", hops: 3 });

		var long : Node = new Node("long");
		long.exits.set("L", { node : "top-passage", exit : "R", hops : 6 });
		long.exits.set("R", { node : "descent", exit : "L", hops : 6 });

		SceneGraph.set(s1.name, s1);
		SceneGraph.set(s2.name, s2);
		SceneGraph.set(s3.name, s3);
		SceneGraph.set(s4.name, s4);

		SceneGraph.set(twoheights.name, twoheights);
		SceneGraph.set(ascent.name, ascent);
		SceneGraph.set(descent.name, descent);
		SceneGraph.set(long.name, long);

		SceneGraph.set(narrow.name, narrow);

		currentSceneName = twoheights.name;
	}

	var BallonGenerator : Bool = false;
	var timer : FlxTimer = null;

	function debugRoutines()
	{
		var mousePos : FlxPoint = FlxG.mouse.getWorldPosition();

		// 1. Create fly
		if (FlxG.keys.pressed.ONE)
		{
			add(new Fly(FlxG.random.float(0, FlxG.width), -10, this));
		}
		// 2. Create balloon
		else if (FlxG.keys.justPressed.TWO)
		{
			elements.add(new Balloon(mousePos.x, mousePos.y, this));
		}

		// P: Display camera and world bounds data
		if (FlxG.keys.justPressed.P)
		{
			// trace("Cam bounds: " + FlxG.camera.bounds);
			trace("World bounds: " + FlxG.worldBounds);
			trace("Zoom: " + FlxG.camera.zoom);
		}

		// O: Switch between Player and DebugPlayer
		if (FlxG.keys.justPressed.O)
		{
			var x : Float = player.x;
			var y : Float = player.y;

			if (player.overridenControl)
			{
				player.destroy();
				player = new Player(x, y, this);
			}
			else
			{
				player.destroy();
				player = new DebugPlayer(x, y, this);
			}

			add(player);

			focusCamera();
		}

		// T: Jump 100 pixels
		if (FlxG.keys.justPressed.T)
		{
			// FlxG.camera.followLerp = 0;
			player.x += (player.facing == FlxObject.LEFT ? -1 : 1) * 100;
			FlxG.camera.focusOn(player.getMidpoint());
		}
		else
		{
			// FlxG.camera.followLerp = 14;
		}

		if (FlxG.keys.justPressed.J)
		{
			if (currentScene != null)
				buildBugCatcherScene();
			else
			{
				cleanBugCatcherScene();
				currentScene = loadScene(currentSceneName, 0, 0);
				player.x = FlxG.width / 2;
				player.y = 0;
			}
		}

		// B: Balloon Generation
		if (FlxG.keys.justPressed.B)
		{
			BallonGenerator = !BallonGenerator;
			if (BallonGenerator)
			{
				lastBalloon = null;
				timer = new FlxTimer();
				timer.start(FlxG.random.float(0.25, 1.5), spawnBalloon);
			}
			else
			{
				timer.cancel();
			}
		}
	}

	var lastBalloon : FlxObject;
	function spawnBalloon(t : FlxTimer) : Void
	{
		var bounds : FlxRect;
		var useBlank : Bool = false;
		var blankLeft : Float = -1;
		var blankRight : Float = -1;

		if (currentScene == null)
		{
			bounds = new FlxRect(32, 16, FlxG.width-56, FlxG.height);
		}
		else
		{
			bounds = new FlxRect(currentScene.x, currentScene.y, currentScene.fullWidth, currentScene.fullHeight);
		}

		if (lastBalloon != null)
		{
			// Calculate distance from last balloon
			var sceneBounds : FlxRect = bounds;

			var lastX : Float = lastBalloon.x;
			var maxDelta : Float = 64;
			var minDelta : Float = 18;
			bounds = new FlxRect(Math.max(lastX - maxDelta, sceneBounds.x), bounds.y,
								 Math.min(maxDelta, bounds.width - lastX), bounds.height);

			useBlank = true;
			blankLeft = lastX - minDelta;
			blankRight = lastX + minDelta;
		}

		var x : Float = -1;
		if (useBlank)
		{
			x = blankLeft+1;
			while (x > blankLeft && x < blankRight)
				x = FlxG.random.float(bounds.x, bounds.x + bounds.width);
		}
		else
			x = FlxG.random.float(bounds.x, bounds.x + bounds.width);

		var y : Float = bounds.y + bounds.height - 16;
		lastBalloon = new Balloon(x, y, this);
		elements.add(lastBalloon);

		timer = new FlxTimer();
		timer.start(FlxG.random.float(1.25, 2.5), spawnBalloon);
	}

	function buildHopwayScene()
	{
		var wallcolor : Int = 0x0083769C;

		FlxG.camera.setScrollBounds(-3750, -1000, 10000, 1000 + FlxG.height);

		var g : FlxSprite = new FlxSprite(-4000, FlxG.height - 16).makeGraphic(Std.int(FlxG.camera.width), 2, wallcolor);
		g.solid = true;
		g.immovable = true;

		ground.add(g);

		createPlayer(FlxG.camera.scroll.x + FlxG.camera.width / 2, -16);
	}

	function buildBugCatcherScene()
	{
		if (currentScene != null)
		{
			currentScene.destroy();
			currentScene = null;
		}

		FlxG.camera.setScrollBounds(0, 0, FlxG.width, FlxG.height);
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		var wallcolor : Int = 0x0083769C;
		var wallwidth : Int = 32;

		var g : FlxSprite = new FlxSprite(0, FlxG.height - 16).makeGraphic(FlxG.width, 2, wallcolor);
		g.solid = true;
		g.immovable = true;

		ground.add(g);

		g = new FlxSprite(0, 0).makeGraphic(wallwidth, FlxG.height, wallcolor);
		g.immovable = true;
		ground.add(g);

		g = new FlxSprite(FlxG.width - wallwidth, 0).makeGraphic(wallwidth, FlxG.height, wallcolor);
		g.immovable = true;
		ground.add(g);

		player.x = FlxG.width / 2;
		player.y = 0;

		FlxG.camera.focusOn(player.getMidpoint());
	}

	function cleanBugCatcherScene()
	{
		ground.clear();
	}
}
