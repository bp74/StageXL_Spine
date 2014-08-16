import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Stage stage;
RenderLoop renderLoop;
ResourceManager resourceManager = new ResourceManager();

void main() {

  var canvas = html.querySelector('#stage');

  stage = new Stage(canvas, webGL: true, width:480, height: 600, color: Color.DarkSlateGray);
  stage.scaleMode = StageScaleMode.SHOW_ALL;
  stage.align = StageAlign.NONE;

  renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  BitmapData.defaultLoadOptions.webp = true;

  switch(2) {

    case 1: // powerup
      resourceManager.addTextFile("powerup", "spine/powerup.json");
      resourceManager.addTextureAtlas("powerup", "atlas1/powerup.atlas", TextureAtlasFormat.LIBGDX);
      //resourceManager.addTextureAtlas("powerup", "atlas2/powerup.json", TextureAtlasFormat.JSONARRAY);
      resourceManager.load().then((rm) => startPowerup());
      break;

    case 2: // spineboy
      resourceManager.addTextFile("spineboy", "spine/spineboy.json");
      resourceManager.addTextureAtlas("spineboy", "atlas1/spineboy.atlas", TextureAtlasFormat.LIBGDX);
      //resourceManager.addTextureAtlas("spineboy", "atlas2/spineboy.json", TextureAtlasFormat.JSONARRAY);
      resourceManager.load().then((rm) => startSpineboy());
      break;

    case 3: // goblins
      resourceManager.addTextFile("goblins-ffd", "spine/goblins-ffd.json");
      resourceManager.addTextureAtlas("goblins-ffd", "atlas1/goblins-ffd.atlas", TextureAtlasFormat.LIBGDX);
      //resourceManager.addTextureAtlas("goblins-ffd", "atlas2/goblins-ffd.json", TextureAtlasFormat.JSONARRAY);
      resourceManager.load().then((rm) => startGoblins());
      break;
  }
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

void startPowerup() {

  var spineJson = resourceManager.getTextFile("powerup");
  var textureAtlas = resourceManager.getTextureAtlas("powerup");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);

  var animationStateData = new AnimationStateData(skeletonData);

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 240;
  skeletonAnimation.y = 430;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.8;

  skeletonAnimation.state.setAnimationByName(0, "animation", true);

   stage.addChild(skeletonAnimation);
   stage.juggler.add(skeletonAnimation);
}

//-----------------------------------------------------------------------------

void startSpineboy() {

  var textField = new TextField();
  textField.defaultTextFormat = new TextFormat("Arial", 24, Color.White, align: TextFormatAlign.CENTER);
  textField.width = 480;
  textField.x = 0;
  textField.y = 550;
  textField.text = "tap to change animation";
  textField.addTo(stage);

  var spineJson = resourceManager.getTextFile("spineboy");
  var textureAtlas = resourceManager.getTextureAtlas("spineboy");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);

  var animationStateData = new AnimationStateData(skeletonData);
  animationStateData.setMixByName("idle", "walk", 0.2);
  animationStateData.setMixByName("walk", "run", 0.2);
  animationStateData.setMixByName("run", "walk", 0.2);
  animationStateData.setMixByName("walk", "idle", 0.2);

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 240;
  skeletonAnimation.y = 520;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.7;

  skeletonAnimation.state.onTrackStart.listen((ts) {
    print("${ts.index} start: ${skeletonAnimation.state.getCurrent(ts.index)}");
  });
  skeletonAnimation.state.onTrackEnd.listen((ts) {
    print("${ts.index} end: ${skeletonAnimation.state.getCurrent(ts.index)}");
  });
  skeletonAnimation.state.onTrackComplete.listen((ts) {
    print("${ts.index} complete: ${skeletonAnimation.state.getCurrent(ts.index)}, ${ts.count}");
  });
  skeletonAnimation.state.onTrackEvent.listen((ts) {
    print("${ts.index} event: ${skeletonAnimation.state.getCurrent(ts.index)}, "
      "${ts.event.data.name}: ${ts.event.intValue}, ${ts.event.floatValue}, ${ts.event.stringValue}");
  });

  var animations = ["idle", "walk", "run", "walk"];
  var animationIndex = 0;
  stage.onMouseClick.listen((me) {
    animationIndex = (animationIndex + 1) % animations.length;
    skeletonAnimation.state.setAnimationByName(0, animations[animationIndex], true);
  });

  // death, hit, idle, jump, run, shoot, test, walk,

  //skeletonAnimation.state.setAnimationByName(0, "test", true);
  skeletonAnimation.state.setAnimationByName(0, "idle", true);

//  skeletonAnimation.state.setAnimationByName(0, "walk", true);
//  skeletonAnimation.state.addAnimationByName(0, "death", false, 2);
//  skeletonAnimation.state.addAnimationByName(0, "shoot", false, 6);

  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
}

//-----------------------------------------------------------------------------


void startGoblins() {

  var spineJson = resourceManager.getTextFile("goblins-ffd");
  var textureAtlas = resourceManager.getTextureAtlas("goblins-ffd");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);

  var animationStateData = new AnimationStateData(skeletonData);

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 240;
  skeletonAnimation.y = 560;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 1.5;

  skeletonAnimation.skeleton.skinName = "goblin";
  //skeletonAnimation.skeleton.skinName = "goblingirl";

  skeletonAnimation.state.setAnimationByName(0, "walk", true);

   stage.addChild(skeletonAnimation);
   stage.juggler.add(skeletonAnimation);

}


