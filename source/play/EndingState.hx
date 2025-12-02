package play;

import data.animation.Animation;
import data.language.LanguageManager;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import ui.MusicBeatState;
import ui.menu.story.StoryMenuState;

import util.TouchUtil;

typedef EndingStateParams =
{
	/**
	 * The week the player was on.
	 */
	var week:String;

	/**
	 * The ending the player got.
	 */
	var ending:String;

	/**
	 * The song that should play for this ending.
	 * Optional, if none is entered the good ending theme plays automatically.
	 */
	var ?song:String;

	/**
	 * The visual animation used to represent the ending.
	 */
	var ?anims:Array<AnimationData>;

	/**
	 * The animation to start playing when this state opens.
	 */
	var ?startAnim:String;
}

/**
 * A state the player goes to after completing a story mode week.
 * Displays a visual ending depending on the player's score.
 */
class EndingState extends MusicBeatState
{
	/**
	 * The last parameters the player had.
	 * Fallback in-case no parameters exist.
	 */
	var lastParams:EndingStateParams;

	/**
	 * The parameters given when opening this state.
	 */
	var params:EndingStateParams;

	/**
	 * The name of the week.
	 */
	var week:String;

	/**
	 * The ending the player got.
	 */
	var ending:String;

	/**
	 * The description of the ending.
	 */
	var endingTitleText:String;

	/**
	 * The song that should play for this ending.
	 */
	var song:String;

	/**
	 * The text that displays what ending you got.
	 */
	var endingTitle:FlxText;

	/**
	 * The text that displays the description based on the ending you got.
	 */
	var endingDescription:FlxText;

	public function new(params:EndingStateParams)
	{
		super();

		if (params == null)
			params = lastParams;
		else
			this.params = params;

		this.lastParams = params;

		this.week = params.week;
		this.ending = params.ending ?? 'unknown';

		this.endingTitleText = LanguageManager.getTextString('ending_title_${ending}');
		this.song = params.song ?? 'goodEnding';
	}

	override public function create():Void
	{
		super.create();

		SoundController.playMusic(Paths.music(this.song), 1, true);

		var endingSpr:FlxSprite = new FlxSprite();
		if (params.anims == null || params.anims.length == 0)
		{
			endingSpr.loadGraphic(Paths.image('endings/$week/${this.ending}_$week', 'shared'));
		}
		else
		{
			endingSpr.frames = Paths.getSparrowAtlas('endings/$week/${this.ending}_$week', 'shared');
			for (anim in params.anims)
			{
				Animation.addToSprite(endingSpr, anim);
			}
			endingSpr.animation.play(params.startAnim ?? params.anims[0].name, true);
		}
		endingSpr.screenCenter();
		endingSpr.y -= 100;
		add(endingSpr);

		endingTitle = new FlxText(0, 460, '${endingTitleText}');
		endingTitle.setFormat(Paths.font('comic_normal.ttf'), 55, FlxColor.WHITE, FlxTextAlign.CENTER);
		endingTitle.screenCenter(X);
		add(endingTitle);

		endingDescription = new FlxText(0, 550, 0, LanguageManager.getTextString('ending_${week}_${ending}'));
		endingDescription.setFormat(Paths.font('comic_normal.ttf'), 24, FlxColor.WHITE, FlxTextAlign.CENTER);
		endingDescription.screenCenter(X);
		add(endingDescription);

		FlxG.camera.fade(FlxColor.BLACK, 0.8, true);
	}

	var justTouched:Bool = false;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.ACCEPT #if mobile || TouchUtil.justPressed #end)
		{
			endIt();
		}
	}

	public function endIt()
	{
		FlxG.switchState(() -> new StoryMenuState());
		SoundController.playMusic(Paths.music('freakyMenu'));
	}
}
