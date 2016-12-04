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
  var stage = new Stage(canvas, width: 480, height: 600);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  // load "spineboy" skeleton resources

  var resourceManager = new ResourceManager();
  var libgdxx = TextureAtlasFormat.LIBGDX;
  resourceManager.addTextFile("spineboy", "spine/spineboy.json");
  resourceManager.addTextureAtlas("spineboy", "spine/spineboy.atlas", libgdxx);
  await resourceManager.load();

  // add TextField to show user information

  var textField = new TextField();
  textField.defaultTextFormat = new TextFormat("Arial", 24, Color.White);
  textField.defaultTextFormat.align = TextFormatAlign.CENTER;
  textField.width = 480;
  textField.x = 0;
  textField.y = 550;
  textField.text = "tap to change animation";
  textField.addTo(stage);

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("spineboy");
  var textureAtlas = resourceManager.getTextureAtlas("spineboy");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);

  // configure Spine animation mix

  var animationStateData = new AnimationStateData(skeletonData);
  animationStateData.setMixByName("idle", "walk", 0.2);
  animationStateData.setMixByName("walk", "run", 0.2);
  animationStateData.setMixByName("run", "walk", 0.2);
  animationStateData.setMixByName("walk", "idle", 0.2);

  // create the display object showing the skeleton animation

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 240;
  skeletonAnimation.y = 520;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.7;
  skeletonAnimation.state.setAnimationByName(0, "idle", true);
  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);

  // change the animation on every mouse click

  var animationNames = ["idle", "idle", "walk", "run", "walk"];
  var animationState = skeletonAnimation.state;
  var animationIndex = 0;

  stage.onMouseClick.listen((me) {
    animationIndex = (animationIndex + 1) % animationNames.length;
    if (animationIndex == 1) {
      animationState.setEmptyAnimation(1, 0.0);
      animationState.addAnimationByName(1, "shoot", false, 0.0).mixDuration = 0.2;
      animationState.addEmptyAnimation(1, 0.2, 0.5);
    } else {
      var animationName = animationNames[animationIndex];
      animationState.setAnimationByName(0, animationName, true);
    }
  });

  // register track events


  skeletonAnimation.state.onTrackStart.listen((TrackEntryStartEvent e) {
    print("${e.trackEntry.trackIndex} start: ${e.trackEntry}");
  });

  skeletonAnimation.state.onTrackEnd.listen((TrackEntryEndEvent e) {
    print("${e.trackEntry.trackIndex} end: ${e.trackEntry}");
  });

  skeletonAnimation.state.onTrackComplete.listen((TrackEntryCompleteEvent e) {
    print("${e.trackEntry.trackIndex} complete: ${e.trackEntry}");
  });

  skeletonAnimation.state.onTrackEvent.listen((TrackEntryEventEvent e) {
    var ev = e.event;
    var text = "${ev.data.name}: ${ev.intValue}, ${ev.floatValue}, ${ev.stringValue}";
    print("${e.trackEntry.trackIndex} event: ${e.trackEntry}, $text");
  });

  // Test other animations defined in this Spine animation
  // For best visual appearance please check the animation mix setup.

  //skeletonAnimation.state.setAnimationByName(0, "idle", false);
  //skeletonAnimation.state.addAnimationByName(0, "death", false, 0);
  //skeletonAnimation.state.addAnimationByName(0, "hit", false, 0);
  //skeletonAnimation.state.addAnimationByName(0, "jump", false, 0);
  //skeletonAnimation.state.addAnimationByName(0, "run", false, 0);
  //skeletonAnimation.state.addAnimationByName(0, "shoot", false, 0);
  //skeletonAnimation.state.addAnimationByName(0, "test", false, 0);
  //skeletonAnimation.state.addAnimationByName(0, "walk", false, 0);

}
