package;

import audio.GameSoundTray;
import backend.debug.FPSDisplay;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.events.Event;
import openfl.display.Sprite;
import openfl.text.TextFormat;
import modding.PolymodManager;

import ui.intro.InitState;

#if mobile
import util.SUtil;
#end

#if desktop
import api.ALSoftConfig; // Longest yeah boi ever
#end

class Main extends Sprite
{
	public static var frameRate:Int = 144;

	var gameWidth:Int = 1280;
	var gameHeight:Int = 720;
	
	var initialState:Class<FlxState> = InitState;
	var zoom:Float = -1;

	var startFullscreen:Bool = false;

	public static var fps:FPSDisplay;

	public static var applicationName:String = "VS. Dave and Bambi";

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();
		SUtil.uncaughtErrorHandler();
		stage != null ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	public static function toggleFuckedFPS(toggle:Bool)
	{
		fps.fuckFps = toggle;
	}

	private function setupGame():Void
	{
		PolymodManager.initalize();

		#if !mobile 
		fps = new FPSDisplay(10, 3, 0xFFFFFF);
		var fpsFormat = new TextFormat("Comic Sans MS Bold", 15, 0xFFFFFF, true);
		fps.defaultTextFormat = fpsFormat;
		#end

		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		#if mobile
		gameWidth = 1280;
		gameHeight = 720;
		zoom = 1;
		#end

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}
		var game = new FlxGame(gameWidth, gameHeight, initialState, #if (flixel < "5.0.0") zoom, #end frameRate, frameRate, true, startFullscreen);

		@:privateAccess
		game._customSoundTray = GameSoundTray;

		#if android
		SUtil.checkFiles();
		#end
		addChild(game);
		#if !mobile
		addChild(fps);
		#end
	}
}
