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

  //resourceManager.load().then((rm) => startSpineboy());
  resourceManager.load().then((rm) => startPowerup());
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

  var spineJson = resourceManager.getTextFile("spineboyJson");
  var atlasText = resourceManager.getTextFile("spineboyAtlas");
  var atlasBitmapData = resourceManager.getBitmapData("spineboyPng");

  var textureLoader = new BitmapDataTextureLoader(atlasBitmapData);
  var atlas = new Atlas(atlasText, textureLoader);
  var json = new SkeletonJson(new AtlasAttachmentLoader(atlas));
  json.scale = 0.6;

  var skeletonData = json.readSkeletonData(spineJson);

  var animationStateData = new AnimationStateData(skeletonData);
  animationStateData.setMixByName("walk", "jump", 0.2);
  animationStateData.setMixByName("jump", "run", 0.4);
  animationStateData.setMixByName("jump", "jump", 0.2);

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 400;
  skeletonAnimation.y = 300;

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

  //skeleton.state.setAnimationByName(0, "test", true);

  skeletonAnimation.state.setAnimationByName(0, "walk", true);
  skeletonAnimation.state.addAnimationByName(0, "run", false, 3);
  skeletonAnimation.state.addAnimationByName(0, "jump", true, 0);

  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);

}
