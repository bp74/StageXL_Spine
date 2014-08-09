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
  var skeleton = new SkeletonAnimation(skeletonData, animationStateData);

  skeleton.x = 400;
  skeleton.y = 300;
  skeleton.state.setAnimationByName(0, "animation", true);

   stage.addChild(skeleton);
   stage.juggler.add(skeleton);
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

  var skeleton = new SkeletonAnimation(skeletonData, animationStateData);
  skeleton.x = 400;
  skeleton.y = 300;

  skeleton.state.onTrackStart.listen((ts) {
    print("${ts.index} start: ${skeleton.state.getCurrent(ts.index)}");
  });
  skeleton.state.onTrackEnd.listen((ts) {
    print("${ts.index} end: ${skeleton.state.getCurrent(ts.index)}");
  });
  skeleton.state.onTrackComplete.listen((ts) {
    print("${ts.index} complete: ${skeleton.state.getCurrent(ts.index)}, ${ts.count}");
  });
  skeleton.state.onTrackEvent.listen((ts) {
    print("${ts.index} event: ${skeleton.state.getCurrent(ts.index)}, "
      "${ts.event.data.name}: ${ts.event.intValue}, ${ts.event.floatValue}, ${ts.event.stringValue}");
  });

  //skeleton.state.setAnimationByName(0, "test", true);

  skeleton.state.setAnimationByName(0, "walk", true);
  skeleton.state.addAnimationByName(0, "run", false, 3);
  skeleton.state.addAnimationByName(0, "jump", true, 0);

  stage.addChild(skeleton);
  stage.juggler.add(skeleton);

}
