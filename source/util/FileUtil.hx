package util;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import haxe.io.Path;
import openfl.utils.Assets;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
#end
#if mobile
import util.SUtil;
#end

/**
 * A utility to help provide functions relating to the file explorer, and general file manipulation. 
 */
class FileUtil
{
    public static function randomizeBG():FlxGraphic
	{
		if (FlxG.random.bool(1 / 5000))
		{
			return Paths.image('backgrounds/ramzgaming');
		}
		else
		{
			var backgroundPath:String = Path.withoutExtension(Paths.imagePath('backgrounds'));

			var bgs:Array<String> = Assets.list(IMAGE).filter((p:String) ->
			{
				return p.startsWith(backgroundPath);
			}).map((s:String) -> {
				return Path.withoutExtension(s.substr(backgroundPath.length + 1, s.length));
			});
			return Paths.image('backgrounds/${FlxG.random.getObject(bgs)}');
		}
	}
    public static function splitText(path:String):Array<String>
	{
		var daList:Array<String> = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}
		return daList;
	}
    
    /**
     * Creates a new directory a specified 'path', will make a new directory if one isn't made already.
     * @param path The path to create a directory in.
     */
    public static function createDirectory(path:String)
    {
		#if desktop
		var finalPath:String = path;
		#else
		var finalPath:String = SUtil.getStorageDirectory() + path;
		#end
		
        if (!FileSystem.exists(finalPath)) {
            FileSystem.createDirectory(SUtil.getStorageDirectory() + finalPath);
        }
    }

    /**
     * Opens a file at the specified 'path', works on all platforms.
     * @param path The path to open.
     */
    public static function openFile(path:String)
    {
        #if windows
		Sys.command("start " + path);
		#elseif linux
		Sys.command("xdg-open " + path);
		#else
		Sys.command("open " + path);
		#end
    }
}