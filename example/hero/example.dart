import 'dart:async';
import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Future main() async {

  // configure StageXL default options

  StageXL.stageOptions.renderEngine = RenderEngine.WebGL;
  StageXL.stageOptions.backgroundColor = Color.DarkSlateGray;

  // init Stage and RenderLoop

  var canvas = html.querySelector('#stage');
  var stage = new Stage(canvas, width: 400, height: 500);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  // load "hero" skeleton resources

  var resourceManager = new ResourceManager();
  var libgdx = TextureAtlasFormat.LIBGDX;
  resourceManager.addTextFile("hero", "spine/hero-mesh.json");
  resourceManager.addTextureAtlas("hero", "spine/hero-mesh.atlas", libgdx);
  await resourceManager.load();

  // Add TextField to show user information

  var textField = new TextField();
  textField.defaultTextFormat = new TextFormat("Arial", 24, Color.White);
  textField.defaultTextFormat.align = TextFormatAlign.CENTER;
  textField.width = 400;
  textField.x = 0;
  textField.y = 450;
  textField.text = "tap to change animation";
  textField.addTo(stage);

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("hero");
  var textureAtlas = resourceManager.getTextureAtlas("hero");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);

  // configure Spine animation mix

  var animationStateData = new AnimationStateData(skeletonData);
  animationStateData.setMixByName("Idle", "Walk", 0.2);
  animationStateData.setMixByName("Walk", "Run", 0.2);
  animationStateData.setMixByName("Run", "Attack", 0.2);
  animationStateData.setMixByName("Attack", "Crouch", 0.2);
  animationStateData.setMixByName("Crouch", "Idle", 0.2);

  // create the display object showing the skeleton animation

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 180;
  skeletonAnimation.y = 400;
  skeletonAnimation.state.setAnimationByName(0, "Idle", true);
  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);

  // change the animation on every mouse click

  var animations = ["Idle", "Walk", "Run", "Attack", "Crouch"];
  var animationIndex = 0;

  stage.onMouseClick.listen((me) {
    animationIndex = (animationIndex + 1) % animations.length;
    skeletonAnimation.state.setAnimationByName(0, animations[animationIndex], true);
  });

  // register track events

  skeletonAnimation.state.onTrackStart.listen((TrackEntryStartArgs t) {
    var trackEntry = skeletonAnimation.state.getCurrent(t.trackIndex);
    print("${t.trackIndex} start: ${trackEntry}");
  });

  skeletonAnimation.state.onTrackEnd.listen((TrackEntryEndArgs t) {
    var trackEntry = skeletonAnimation.state.getCurrent(t.trackIndex);
    print("${t.trackIndex} end: ${trackEntry}");
  });

  skeletonAnimation.state.onTrackComplete.listen((TrackEntryCompleteArgs t) {
    var trackEntry = skeletonAnimation.state.getCurrent(t.trackIndex);
    print("${t.trackIndex} complete: ${trackEntry}, ${t.count}");
  });

  skeletonAnimation.state.onTrackEvent.listen((TrackEntryEventArgs t) {
    var trackEntry = skeletonAnimation.state.getCurrent(t.trackIndex);
    var event = t.event;
    print("${t.trackIndex} event: ${trackEntry}, "
        "${event.data.name}: ${event.intValue}, ${event.floatValue}, ${event.stringValue}");
  });
}
