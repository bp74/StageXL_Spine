import 'dart:math';
import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Stage stage = new Stage(html.querySelector('#stage'), webGL: true, color: Color.DarkSlateGray);
RenderLoop renderLoop = new RenderLoop();
ResourceManager resourceManager = new ResourceManager();

void main() {
  renderLoop.addStage(stage);

  resourceManager.addTextFile("spineboyJson", "spine/spineboy.json");
  resourceManager.addTextFile("spineboyAtlas", "spine/spineboy.atlas");
  resourceManager.addBitmapData("spineboyPng", "spine/spineboy.png");

  resourceManager.addTextFile("powerupJson", "spine/powerup.json");
  resourceManager.addTextFile("powerupAtlas", "spine/powerup.atlas");
  resourceManager.addBitmapData("powerupPng", "spine/powerup.png");

  resourceManager.load().then((rm) => startSpineboy());
  //resourceManager.load().then((rm) => startPowerup());
}

//-----------------------------------------------------------------------------

void startPowerup() {
  var spineJson = resourceManager.getTextFile("powerupJson");
  var atlasText = resourceManager.getTextFile("powerupAtlas");
  var atlasBitmapData = resourceManager.getBitmapData("powerupPng");

  var textureLoader = new BitmapDataTextureLoader(atlasBitmapData);
  var atlas = new Atlas(atlasText, textureLoader);
  var json = new SkeletonJson(new AtlasAttachmentLoader(atlas));

  var skeletonData = json.readSkeletonData(spineJson);
  var animationStateData = new AnimationStateData(skeletonData);
  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);

  skeletonAnimation.x = 400;
  skeletonAnimation.y = 300;
  skeletonAnimation.state.setAnimationByName(0, "animation", true);

   stage.addChild(skeletonAnimation);
   stage.juggler.add(skeletonAnimation);
}

void startSpineboy() {

  var textField = new TextField();
  textField.defaultTextFormat = new TextFormat("Arial", 24, Color.White, align: TextFormatAlign.CENTER);
  textField.width = 400;
  textField.x = 200;
  textField.y = 530;
  textField.text = "Click to change animation";
  textField.addTo(stage);

  var spineJson = resourceManager.getTextFile("spineboyJson");
  var atlasText = resourceManager.getTextFile("spineboyAtlas");
  var atlasBitmapData = resourceManager.getBitmapData("spineboyPng");

  var textureLoader = new BitmapDataTextureLoader(atlasBitmapData);
  var atlas = new Atlas(atlasText, textureLoader);
  var json = new SkeletonJson(new AtlasAttachmentLoader(atlas));
  json.scale = 0.6;

  var skeletonData = json.readSkeletonData(spineJson);

  var animationStateData = new AnimationStateData(skeletonData);
  animationStateData.setMixByName("idle", "walk", 0.2);
  animationStateData.setMixByName("walk", "run", 0.2);
  animationStateData.setMixByName("run", "walk", 0.2);
  animationStateData.setMixByName("walk", "idle", 0.2);

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 400;
  skeletonAnimation.y = 480;

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
