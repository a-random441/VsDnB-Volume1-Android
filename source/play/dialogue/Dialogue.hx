package play.dialogue;

import audio.GameSound;
import data.IRegistryEntry;
import data.dialogue.DialogueData;
import data.dialogue.DialogueRegistry;
import data.dialogue.SpeakerRegistry;
import data.language.LanguageManager;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import scripting.events.ScriptEvent;
import scripting.events.ScriptEventDispatcher;
import scripting.IScriptedClass.IDialogueScriptedClass;
import scripting.IScriptedClass.IEventDispatcher;
import util.SortUtil;
import util.TweenUtil;
#if mobile
import util.TouchUtil;
#end

enum DialogueState
{
    Opening;
    Typing;
    Idle;
    Ending;
}

/**
 * A re-fined version of the dialogue system that allows for easy accessability.
 * 
 * This runs on a state machine, and runs scripted functions to control how the dialogue acts. 
 */
class Dialogue extends FlxSpriteGroup implements IDialogueScriptedClass implements IRegistryEntry<DialogueData> 
{
	public final id:String;

    var _data:DialogueData;

    final DEFAULT_DIALOGUE_SOUND:FlxSound = SoundController.load(Paths.sound('dialogue/pixelText'));

    /**
     * The asset path to the music played in the dialogue.
     */
    var dialogueMusicPath:Null<String>;

	/**
	 * Animation offsets for the dialogue box sprite to make sure it stays in place.
	 */
	final boxOffsets:Map<String, FlxPoint> = 
	[
		'normal' => FlxPoint.get(0, 0),
		'none' => FlxPoint.get(0, -51),
	];

    /**
     * The list of dialogue entries that is to be advanced throughout this dialogue.
     */
    var dialogueList(get, never):Array<DialogueEntryData>;

    function get_dialogueList():Array<DialogueEntryData>
    {
        return _data?.dialogue ?? [];
    }

    /**
     * The current state the dialogue box is in.
     */
    var state:DialogueState = Opening;


    /**
     * The music that'll play during the dialogue.
     */
    var music:GameSound = null;

    /**
     * The backdrop that appears behind the dialogue box.
     */
    var background:FlxSprite;

    /**
     * The actual dialogue box sprite that overlayed under the text.
     */
    var dialogueBox:FlxSprite;

    /**
     * The text inside of the dialogue box that actually displays the dialogue.
     */
    var dialogueText:FlxTypeText;

    /**
     * The current speaker sprite that's actively talking.
     */
    var speaker:Speaker;

    /**
     * The tween that fades out the dialogue, and completes it.
     */
    var outroTween:FlxTween;

    /**
     * Function called when this dialogue finishes.
     */
    public var onFinish:Void->Void;

    /**
     * Whether this dialogue is currently fading out, and the song is about to start.
     */
    public var isDialogueEnding(get, never):Bool;

    function get_isDialogueEnding():Bool
    {
        return outroTween != null;
    }

    /**
     * The current dialogue line we're at.
     */
    var currentDialogueLine:Int = 0;

    /**
     * The current dialogue entry we're in at the list.
     */
    var currentDialogueEntry(get, never):DialogueEntryData;

    function get_currentDialogueEntry():DialogueEntryData
    {
        return dialogueList[currentDialogueLine];
    }

    /**
     * The amount of entries the dialogue we're in has. 
     */
    var dialogueEntryCount(get, never):Int;

    function get_dialogueEntryCount():Int
    {
        return dialogueList.length - 1;
    }

	public function new(id:String)
    {
        super();

		this.id = id;
        _data = fetchData(id);
	}
    
    public function onCreate(event:ScriptEvent):Void
    {
        currentDialogueLine = 0;
        dialogueMusicPath = _data.music;

        buildMusic();
        buildBackground();
        createDialogueBox();

        refresh();
    }
    
    public function onUpdate(event:UpdateScriptEvent):Void
    {
        switch (state)
        {
            case Typing:
                // Pressing `ENTER` will stop the typing for this dialogue.
                if (FlxG.keys.justPressed.ENTER #if mobile || TouchUtil.justPressed #end)
                {
                    advanceDialogue();
                }
            case Idle:
                // Skip to the next dialogue line when enter's pressed.
                if (FlxG.keys.justPressed.ENTER #if mobile || TouchUtil.justPressed #end)
                {
                    advanceDialogue();
                }
            default:
        }
    }

    public function onDestroy(event:ScriptEvent):Void
    {
        dispatchToChildren(event);

        if (outroTween != null)
        {
            outroTween.cancel();
            outroTween.destroy();
            outroTween = null;
        }

        if (this.music != null)
        {
            SoundController.remove(this.music);
            this.music?.stop();
            this.music = null;
        }

        if (speaker != null)
        {
            killSpeaker();
        }

        if (dialogueBox != null)
        {
            FlxTween.cancelTweensOf(dialogueBox);
            dialogueBox.destroy();
            remove(dialogueBox);

            dialogueBox = null;
        }

        if (background != null)
        {
            FlxTween.cancelTweensOf(background);
            background.destroy();
            remove(background);

            background = null;
        }

        if (dialogueText != null)
        {
            dialogueText.destroy();
            dialogueText = null;
        }

        this.clear();
    }

    override function kill():Void
    {
        super.kill();

        if (outroTween != null)
        {
            outroTween.cancel();
            outroTween.destroy();
            outroTween = null;
        }
    }

    public function refresh():Void
    {
        sort(SortUtil.byZIndex);
    }

    /**
     * Sets up the music used for the dialogue music.
     * Scripts can override this to customize what dialogue music is played.
     */
    function buildMusic():Void
    {
        if (dialogueMusicPath != null)
        {
            this.music = new GameSound().load(Paths.music(dialogueMusicPath));
            this.music.looped = true;
            SoundController.add(this.music);
            startMusicFadeIn();
            
            this.music.play();
        }
	}

	function startMusicFadeIn():Void
	{
		if (_data.fadeInTime != null && _data.fadeInTime > 0)
		{
			music.volume = 0;
			FlxTween.tween(music, {volume: 0.8}, _data.fadeInTime);
		}
	}

    function fadeOutMusic():Void
    {
		if (music != null)
		{
			FlxTween.cancelTweensOf(music);
			if (_data.fadeOutTime != null && _data.fadeOutTime > 0)
			{
				FlxTween.tween(music, {volume: 0.0}, _data.fadeOutTime);
			}
		}
    }

    public function pauseMusic():Void
    {
        if (music != null)
        {
            music.pause();
        }
    }

    public function resumeMusic():Void
    {
        if (music != null)
        {
            music.resume();
        }
    }

    function buildBackground():Void
    {
        background = new FlxSprite().makeGraphic(1, 1, 0xFF8A9AF5);
        background.scale.set(FlxG.width * 2, FlxG.height * 2);
        background.scrollFactor.set();
        background.alpha = 0.0;
        background.zIndex = 0;
        add(background);
    }

    function createDialogueBox():Void
    {
		dialogueBox = new FlxSprite(0, 325);
		dialogueBox.frames = Paths.getSparrowAtlas('ui/dialogue/speech_bubble_talking');
		dialogueBox.animation.addByPrefix('normal', 'chatboxnorm', 24);
		dialogueBox.animation.addByPrefix('none', 'chatboxnone', 24);
		dialogueBox.screenCenter(X);
        dialogueBox.alpha = 0.0;
        dialogueBox.zIndex = 20;
        add(dialogueBox);
        playBoxAnimation('none');

        buildText();
    }
    
    function buildText():Void
    {
		dialogueText = new FlxTypeText(140, 425, Std.int(FlxG.width * 0.8), "", 32);
		dialogueText.font = Paths.font('comic.ttf');
		dialogueText.color = 0xFF000000;
		dialogueText.antialiasing = true;
        dialogueText.zIndex = 30;
        dialogueText.completeCallback = onTypingComplete;
		add(dialogueText);
    }

    /**
     * Starts the callbck for beginning the dialogue.
     * Once the transition begins, the dialogue starts typing.
     */
    function beginDialogue():Void
    {
        FlxTween.tween(dialogueBox, {alpha: 1}, 1,
        {
			onComplete: function(t:FlxTween)
			{
                state = Typing;
                updateDialogueToEntry();
			}
		});
        FlxTween.tween(background, {alpha: 0.7}, 4.0);
    }

    public function start():Void
    {
        dispatchEvent(new DialogueScriptEvent(DIALOGUE_START, this, false));
    }

    public function skipDialogue():Void
    {
        dispatchEvent(new DialogueScriptEvent(DIALOGUE_SKIP, this, true));
    }

    /**
     * Attempts to advance the dialogue depending on the current state.
     * 
     * - When the dialogue box is currently typing, the text will skip, going into the `Idle` state.
     * - When we're in the `Idle` state, we wait for user input to advance to the next line.
     * - when we're at the last line, we go to the ending state. Once we're there, we complete the dialogue.
     */
    function advanceDialogue():Void
    {
        var event:DialogueScriptEvent = null;
        switch (state)
        {
            case Typing:
                event = new DialogueScriptEvent(DIALOGUE_LINE_COMPLETE, this, true);
            case Idle:
                event = new DialogueScriptEvent(DIALOGUE_LINE, this, true);
            case Ending:
                event = new DialogueScriptEvent(DIALOGUE_END, this, false);
            default:
        }

        if (event != null)
        {
            dispatchEvent(event);
        }
    }

    public function onDialogueStart(event:DialogueScriptEvent):Void
    {
        dispatchToChildren(event);

        // Cancelling this event will cause the dialogue to not happen.
        // They'll need to call `beginDialogue` again if they want to start it again.
        if (!event.eventCanceled)
        {
            beginDialogue();
        }
    }
    
    public function onDialogueLine(event:DialogueScriptEvent):Void
    {
        dispatchToChildren(event);

        // Update to the next dialogue line.
        currentDialogueLine++;

        state = Typing;
        if (currentDialogueLine > dialogueEntryCount)
        {
            state = Ending;
            advanceDialogue();
        }
        else
        {
            updateDialogueToEntry();
        }
    }
    
	public function onDialogueLineComplete(event:DialogueScriptEvent):Void
	{
		dispatchToChildren(event);

		if (event.eventCanceled)
			return;

        dialogueText.skip();
	}

    public function onDialogueSkip(event:DialogueScriptEvent):Void
    {
        dispatchToChildren(event);

        if (event.eventCanceled)
            return;

        dispatchEvent(new DialogueScriptEvent(DIALOGUE_END, this, false));
    }

    public function onDialogueEnd(event:DialogueScriptEvent):Void
    {
        dispatchToChildren(event);

        playOutro();
    }

    public function onScriptEvent(event:ScriptEvent):Void
    {
        // Dispatch to any children of the dialogue as well.
        dispatchToChildren(event);
    }

    public function dispatchEvent(event:ScriptEvent):Void
    {
        var eventHandler:IEventDispatcher = cast FlxG.state;
        if (eventHandler != null)
        {
            eventHandler.dispatchEvent(event);
        }
    }

    function dispatchToChildren(event:ScriptEvent):Void
    {
        if (speaker != null)
        {
            ScriptEventDispatcher.callEvent(speaker, event);
        }
    }

    function updateDialogueToEntry():Void
    {
        updateDialogueBox();
        updateSpeaker();
        updateDialogueText();
        
        // Apply a modifier before doing anything else.
        if (currentDialogueEntry.modifier != null)
        {
            applyModifier(currentDialogueEntry.modifier);
        }
    }

    function updateDialogueBox():Void
    {
        var speakerId:String = currentDialogueEntry.speaker;
        var speakingSide:String = currentDialogueEntry.side;

        if (speakerId == 'generic' || speakingSide == 'middle')
        {
            // Change the animation of the box to have no speaking line.
            playBoxAnimation('none');
        }
        else
        {
            playBoxAnimation('normal');

            // Else, flip the dialogue box based on the side the new speaker is on.
            dialogueBox.flipX = (speakingSide == 'right');
        }
    }
    
    /**
     * Updates the speaker to correspond to the current dialogue line we're at. 
     */
    function updateSpeaker():Void
    {
        var speakerId:String = currentDialogueEntry.speaker;
        var expressionId:Null<String> = currentDialogueEntry.expression;
        var speakingSide:String = currentDialogueEntry.side;

        killSpeaker();

        speaker = SpeakerRegistry.instance.fetchEntry(speakerId);
        if (speaker != null)
        {
            // If the speaker is generic, cancel the rest of the logic.
            if (speakerId == 'generic')
                return;

            // Revive the speaker as it was previously killed.
            speaker.revive();
            speaker.zIndex = 10;
            add(speaker);
            refresh();

            switch (speakingSide)
            {
                case 'left':
                    speaker.setPosition(100, 100);
                case 'middle':
                    speaker.setPosition(dialogueBox.x + dialogueBox.width / 2, 100);
                case 'right':
                    speaker.setPosition(800, 100);
            }

            // Expressions are null when you have speakers such as `generic`, or etc.
            if (expressionId != null)
            {
                speaker.switchToExpression(expressionId);
            }
            
            if (speakingSide == 'middle')
            {
                speaker.x -= speaker.width / 2;
            }

            speaker.x += speaker.globalOffsets[0];
            speaker.y += speaker.globalOffsets[1];
            
            speaker.x += currentDialogueEntry?.offsets[0] ?? 0.0;
            speaker.y += currentDialogueEntry?.offsets[1] ?? 0.0;

            fadeInSpeaker(speakingSide);

            ScriptEventDispatcher.callEvent(speaker, new ScriptEvent(CREATE, false));
        }
    }

    function killSpeaker():Void
    {
        if (speaker != null)
        {
            // Remove the speaker for right now.
            speaker.kill();
            remove(speaker);
            speaker = null;
        }
    }

	/**
	 * Plays a little `fading` animation to the speaker on creation.
	 * @param side The side the speaker is on. Determines how the animation should play.
	 */
	function fadeInSpeaker(side:String):Void
	{
		// Animate the speaker.
		var pushbackAmount:Float = switch (side)
		{
			case 'left': -100;
			case 'right': 100;
			default: -50;
		}
		speaker.x += pushbackAmount;
		speaker.alpha = 0;

		FlxTween.cancelTweensOf(speaker);
		FlxTween.tween(speaker, {x: speaker.x - pushbackAmount, alpha: 1}, 0.2);
	}

    function updateDialogueText():Void
    {
        var typingSpeed:Float = currentDialogueEntry.typeSpeed;
        var currentText:String = LanguageManager.getTextString(currentDialogueEntry.text, LanguageManager.currentDialogueList);
        var sounds:Array<FlxSound> = speaker != null ? speaker.dialogueSounds : [cast DEFAULT_DIALOGUE_SOUND];

        if (currentText == '')
        {
            // There's no text in this dialogue entry. Immediately go to the idle state.
            dialogueText.resetText(currentText);
            onTypingComplete();
        }
        else
        {
            // Reset the text data.
            dialogueText.sounds = sounds.length == 0 ? null : sounds;
            dialogueText.resetText(currentText);
            dialogueText.start(typingSpeed, true);
        }
    }

    function onTypingComplete():Void
    {
        state = Idle;
    }

    /**
     * Applies a modifier for when a specific dialogue line with the given one happens.
     * 
     * Scripts can override this to perform custom functionality.
     * @param modifier The modifier that the entry line reached.
     */
    function applyModifier(modifier:String) {}


	function playBoxAnimation(anim:String)
	{
		dialogueBox.updateHitbox();
		dialogueBox.animation.play(anim, true);

		dialogueBox.offset.x += boxOffsets.get(anim)?.x ?? 0.0;
		dialogueBox.offset.y += boxOffsets.get(anim)?.y ?? 0.0;
	}

    public function playOutro():Void
    {
        // Make sure the outro only plays once.
        if (isDialogueEnding)
            return;

        var hasOutro:Bool = (_data.fadeOutTime != null && _data.fadeOutTime > 0);
        if (hasOutro)
        {
            // These have the chance of still having tweens on them because of the intro.
            TweenUtil.completeTweensOf(background);
            TweenUtil.completeTweensOf(dialogueBox);
            if (speaker != null)
            {
                TweenUtil.completeTweensOf(speaker);
            }
            fadeOutMusic();

            outroTween = FlxTween.tween(this, {alpha: 0}, _data.fadeOutTime, {
                onComplete: (t:FlxTween) -> {
                    onOutroComplete();
                }
            });
        }
        else
        {
            // Immediately destroy clear the dialogue, no outro.
            onOutroComplete();
        }
    }

    function onOutroComplete():Void
    {
        ScriptEventDispatcher.callEvent(this, new ScriptEvent(DESTROY, false));
        
        if (onFinish != null)
            onFinish();
    }

    public function fetchData(id:String):DialogueData
    {
        return DialogueRegistry.instance.parseEntryDataWithMigration(id);
    }
    
    public function onScriptEventPost(event:ScriptEvent):Void {}

    public function onPreferenceChanged(event:PreferenceScriptEvent):Void {}
}