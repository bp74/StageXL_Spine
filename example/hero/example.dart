import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Stage stage;
RenderLoop renderLoop;
ResourceManager resourceManager = new ResourceManager();

void main() {

  var canvas = html.querySelector('#stage');

  stage = new Stage(canvas, webGL: true, width:400, height: 500, color: Color.DarkSlateGray);
  stage.scaleMode = StageScaleMode.SHOW_ALL;
  stage.align = StageAlign.NONE;

  renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  BitmapData.defaultLoadOptions.webp = true;

  resourceManager.addTextFile("hero", "spine/hero-mesh.json");
  //resourceManager.addTextureAtlas("hero", "atlas1/hero-mesh.atlas", TextureAtlasFormat.LIBGDX);
  resourceManager.addTextureAtlas("hero", "atlas2/hero-mesh.json", TextureAtlasFormat.JSONARRAY);
  resourceManager.load().then((rm) => startHero());
}

//-----------------------------------------------------------------------------

void startHero() {

  var textField = new TextField();
  textField.defaultTextFormat = new TextFormat("Arial", 24, Color.White, align: TextFormatAlign.CENTER);
  textField.width = 400;
  textField.x = 0;
  textField.y = 450;
  textField.text = "tap to change animation";
  textField.addTo(stage);

  var spineJson = resourceManager.getTextFile("hero");
  var textureAtlas = resourceManager.getTextureAtlas("hero");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);

  var animationStateData = new AnimationStateData(skeletonData);
  animationStateData.setMixByName("Idle", "Walk", 0.2);
  animationStateData.setMixByName("Walk", "Run", 0.2);
  animationStateData.setMixByName("Run", "Attack", 0.2);
  animationStateData.setMixByName("Attack", "Crouch", 0.2);
  animationStateData.setMixByName("Crouch", "Idle", 0.2);

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 180;
  skeletonAnimation.y = 400;

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

  var animations = ["Idle", "Walk", "Run", "Attack", "Crouch"];
  var animationIndex = 0;
  stage.onMouseClick.listen((me) {
    animationIndex = (animationIndex + 1) % animations.length;
    skeletonAnimation.state.setAnimationByName(0, animations[animationIndex], true);
  });

  skeletonAnimation.state.setAnimationByName(0, "Idle", true);

  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
}
