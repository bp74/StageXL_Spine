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

  resourceManager.addTextFile("spineboy", "spine/spineboy.json");
  //resourceManager.addTextureAtlas("spineboy", "atlas1/spineboy.atlas", TextureAtlasFormat.LIBGDX);
  resourceManager.addTextureAtlas("spineboy", "atlas2/spineboy.json", TextureAtlasFormat.JSONARRAY);
  resourceManager.load().then((rm) => startSpineboy());
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

  skeletonAnimation.state.onTrackStart.listen((t) {
    print("${t.trackIndex} start: ${skeletonAnimation.state.getCurrent(t.trackIndex)}");
  });
  skeletonAnimation.state.onTrackEnd.listen((t) {
    print("${t.trackIndex} end: ${skeletonAnimation.state.getCurrent(t.trackIndex)}");
  });
  skeletonAnimation.state.onTrackComplete.listen((t) {
    print("${t.trackIndex} complete: ${skeletonAnimation.state.getCurrent(t.trackIndex)}, ${t.count}");
  });
  skeletonAnimation.state.onTrackEvent.listen((t) {
    print("${t.trackIndex} event: ${skeletonAnimation.state.getCurrent(t.trackIndex)}, "
      "${t.event.data.name}: ${t.event.intValue}, ${t.event.floatValue}, ${t.event.stringValue}");
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
