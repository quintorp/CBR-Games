﻿package com.borch {	import com.greensock.*;	import flash.display.MovieClip;	import flash.events.Event;	import flash.geom.ColorTransform;	import flash.geom.Rectangle;	import flash.utils.getDefinitionByName;	public class NavGame extends MovieClip implements IGame {		private var gameXML:XML;		private var feedback:Array = [];		private var frameCount:uint;		private var twoMinutesOfFrames:int;		private var score:Number = 0;		private var Field:NavGameField;		private var Player:MovieClip;		private var HitTarget:MovieClip;		private var HitThingsClip:MovieClip;		private var HitThings:Array;		private var HitThing:Hitter;		private var Goal:MovieClip;		private var isNotFishing:Boolean = true;		private var gameUpdate:Function;		private var commandment:int;		private var classes:Array = [ Class (FishingBG), Class (JordanBG), Class (MannaBG), Class (MosesBG), Class (PaulBG), Class (ThingGood0), Class (ThingGood1), Class (ThingGood2) ];		public function NavGame() {			super ();		}		public function initGame(resource:Object = null):void {			gameXML = resource;			gameUpdate = this [gameXML.source + 'Update'];			Field = NavGameField (new (getDefinitionByName (gameXML.source + 'BG')));			addChild (Field);			twoMinutesOfFrames = 120 * stage.frameRate;			addEventListener ('buttonClick', buttonClick, false, 0, true);			HitThingsClip = new MovieClip;			Field.addChild (HitThingsClip);//			SPECIAL PLAYER FOR FISHING			if (gameXML.source.toString () == 'Fishing') {				addChildAt (new SeaweedClip, getChildIndex (Field));				Player = new Fisherman ();				addChildAt (Player, getChildIndex (Field));				HitTarget = Player.Net.Target;				Field.addChild (new WaterClip);				Goal = addChild (new FishingGoal);				isNotFishing = false;				return;			}			Player = HitTarget = new Actor (gameXML.source);			addChild (Player);			switch (gameXML.source.toString ()) {				case 'Jordan' :					Util.bringFront (HitThingsClip);					Goal = Field.Top;					addChild (new WeedClip);					Util.bringFront (Player);					break;				case 'Manna' :					Goal = addChild (new MannaGoal);					addChild (new WeedClip);					setChildIndex (Player, getChildIndex (Goal) - 1);					break;				case 'Moses' :					Player.addEventListener ('moveFieldUp', Field.slideUp, false, 0, true);					Player.addEventListener ('moveFieldDown', Field.slideDown, false, 0, true);					Util.bringFront (Player);					break;				case 'Paul' :					Player.addEventListener ('moveFieldRight', Field.slideRight, false, 0, true);					Player.addEventListener ('moveFieldLeft', Field.slideLeft, false, 0, true);					Goal = new GoalClip;					Goal.x = Field.x + Field.width - Goal.width - 250;					Goal.y = Field.y + Field.height / 2;					Field.addChild (Goal);					Util.bringFront (Player);					break;			}		}		public function resetGame(option:Object = null):void {			frameCount = 0;			Field.x = Field.y = 0;			feedback = [];			for each (var item:XML in CBRXML.the ().xml.gamesXref[gameXML.source + 'Game'].feedback.item) feedback.push (item);			while (HitThingsClip.numChildren) HitThingsClip.removeChildAt (0);			switch (gameXML.source.toString ()) {				case 'Moses' :					Field.y = stage.stageHeight - Field.height;					commandment = 0;					while (feedback.length) {						var CmdClip:Hitter = HitThingsClip.addChild (new Hitter (TenComdClip, Field, ++commandment));						var info:XML = feedback.pop();						trace (info.@label);						CmdClip.setInfo (info.@label, info);					}					commandment = 0;					var i:int = 15;					while (i--) {						var NewRock:Hitter = HitThingsClip.addChild (new Hitter (RockClip, Field));						NewRock.setY ((Field.height - stage.stageHeight) * Math.random ());					}					break;				case 'Paul' :					i = 10;					while (i--) HitThingsClip.addChild (new Hitter (Class (getDefinitionByName ('ThingBad' + String (Util.randomize (3)))), Field));					i = 10;					while (i--) HitThingsClip.addChild (new Hitter (PaulGood, Field));					break;			}			stopGame ();			startGame (true);		}		public function startGame(firstTime:Boolean = false):void {			addEventListener (Event.ENTER_FRAME, update, false, 0, true);			Player.startActor ();			stage.focus = stage;			if (firstTime) GameManager.instance.gameStarted ();		}		public function stopGame(gameOver:Object = false):void {			removeEventListener (Event.ENTER_FRAME, update);			Player.stopActor ();			if (!gameOver) return;			score += int (gameOver - 1);			var message:String = CBRXML.the ().xml.gamesXref.NavGame.finished + '\n';			message += (gameOver - 1) ? CBRXML.the ().xml.gamesXref.NavGame.bonus + ' ' + String (gameOver) + CBRXML.the ().xml.gamesXref.NavGame.total + ' ' + String (score) + '\n':CBRXML.the ().xml.gamesXref.NavGame.score + ' ' + String (score) + ' ' + '\n';			GameManager.instance.gameFeedback (message);		}		public function cleanUp():void {			removeEventListener ('buttonClick', buttonClick);			Player.stopActor ();			stopGame (0);			TweenMax.killAll ();		}		// ********* END IGame FUNCTIONS *********		// ********* START GAME FUNCTIONS *********		// GENERAL GAME TIMER		private function update(event:Event):void {			gameUpdate (++frameCount);			if (frameCount >= twoMinutesOfFrames) stopGame (1);			HitThings = Util.childArray (HitThingsClip);			for each (HitThing in HitThings) {				// MOVE THINGS, CUT IF OUTSIDE Field				HitThing.x += HitThing.speedX;				HitThing.y += HitThing.speedY;				if (!(HitThing.hitTestObject (Field.getChildAt (0)))) {					HitThing.parent.removeChild (HitThing);					continue;				}				// ADD GOAL CHECK				if (isNotFishing && Player.isPaused) continue;				if (HitThing.hitTestObject (HitTarget)) {					var hitterStatus:Object = HitThing.hitStatus;					if (hitterStatus.hitValue != 0) {						if (hitterStatus.smacks) Player.waitForActionComplete ('dizzy');						addScore (hitterStatus.hitValue);						switch (HitThing.type) {							case  MannaClip:								Destroy.it (HitThing);								Player.addManna (false);								break;							case TenComdClip:								++commandment;								popMessage (HitThing.info);								break;							case PaulGood:								popMessage ();								break;							case ThingGood0 :							case ThingGood1 :							case ThingGood2 :								Destroy.it (HitThing);								break;							case FishClip:								switch (Player.caughtFish ()) {									case (2) :										Destroy.it (HitThing);										break;									case (1) :										popMessage ('sinking');										break;								}						}					}				}			}		}		// SPECIFIC GAME TIMERS		private function FishingUpdate(frameCount:int):void {			if (!(frameCount % 20)) HitThingsClip.addChild (new Hitter ([FishClip, SharkClip, OctoClip][Math.floor (3 * Math.random ())], Field));			if ((Player.hitTestObject (Goal)) && (Player.dropOffFish ())) {				popMessage ();				Destroy.it (addChild (new FishBasket), 3, 1);			}		}		private function JordanUpdate(frameCount:int):void {			// ADD NEW HIT THING (ISLAND, LOG)			if (!(frameCount % 50)) HitThingsClip.addChild (new Hitter ([IslandClip, LogClip][Math.round (Math.random ())], Field.River));			// RETURN IF SINKING OR JUMPING			if (Player.isPaused) return;			// RETURN IF HIT FAR SIDE			if (Goal.hitTestPoint (Player.x, Player.y, true)) {				popMessage ();				addScore (200);				Goal = (Goal == Field.Bot) ? Field.Top:Field.Bot;				return;			}			for each (HitThing in HitThings) {				if (HitThing.hitTestPoint (Player.x, Player.y, true)) {					if (Player.x < Player.maxX) Player.x += HitThing.speedX;					return;				}			}			// SINK IF HITS WATER			if (Field.River.hitTestPoint (Player.x, Player.y, true)) {				Player.waitForActionComplete ('sinking');				Goal = Field.Top;			}		}		private function MannaUpdate(frameCount:int):void {			// ADD NEW APPLES OR ROCKS			if (!(frameCount % 10)) HitThingsClip.addChild (new Hitter ([MannaClip, NutClip][Util.pos ()], Field));			if (Player.hitTestObject (Goal)) {				var mannaCount:int = Player.addManna ();				if (Boolean (mannaCount)) {					popMessage ();					var MannaPile:MovieClip = addChild (new (MannaGoalBasket));					MannaPile.gotoAndStop (mannaCount);					Destroy.it (MannaPile, 3, 1);				}			}		}		private function MosesUpdate(frameCount:int):void {			if (!(frameCount % 20)) HitThingsClip.addChild (new Hitter (RockClip, Field));			if (commandment >= 10) stopGame (twoMinutesOfFrames - frameCount + 1);		}		private function PaulUpdate(frameCount:int):void {			if (Player.hitTestObject (Goal)) stopGame (twoMinutesOfFrames - frameCount + 1);		}		private function popMessage(message:String = null):void {			if ((!message) && (!feedback.length)) return;			stopGame ();			var popupXML:XML = <popupXML></popupXML>;			popupXML.options = 'Continue';			if (message == 'sinking') {				popupXML.body = CBRXML.the ().xml.feedbackNeg.choice [Util.randomize (CBRXML.the ().xml.feedbackNeg.choice.length ())] + gameXML.sinking;				addScore (-100);			} else if (feedback.length) {				popupXML.body = (message) ? message:CBRXML.the ().xml.feedbackPos.choice [Util.randomize (CBRXML.the ().xml.feedbackPos.choice.length ())].toString () + '\n' + feedback.pop ();			} else {				popupXML.body = CBRXML.the ().xml.feedbackPos.choice [Util.randomize (CBRXML.the ().xml.feedbackPos.choice.length ())].toString () + '\n' + message;			}			addChild (new GamePopup (popupXML));			dispatchEvent (new Event ('pauseTimer', true, true));		}		public function buttonClick (buttonEvent:Event):void {			buttonEvent.stopPropagation ();			startGame ();			Player.startActor ();			dispatchEvent (new Event ('restartTimer', true, true));		}		private function addScore (hitValue:Number, addBubble:Boolean = true):void {			score += hitValue;			if (!addBubble) return;			var Bubble:MovieClip = addChild (new ScoreBubbleClip);			var playerStageRect:Rectangle = Player.getBounds (stage);			Bubble.x = playerStageRect.x + playerStageRect.width / 2;			Bubble.y = playerStageRect.y + playerStageRect.height / 2;			Bubble.scaleX = Bubble.scaleY = Math.abs (hitValue / 10);			Util.asButton (Bubble, false);			Bubble.Val.text = hitValue;			Bubble.transform.colorTransform = new ColorTransform (Math.random (), Math.random (), Math.random (), 1, 0, 0, 0, 0);			TweenMax.to (Bubble, 1, { y:Bubble.y - 100, alpha:0, onComplete:Destroy.it, onCompleteParams:[Bubble] });		}	}}