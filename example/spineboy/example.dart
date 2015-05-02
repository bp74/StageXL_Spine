import 'dart:async';
import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Future main() async {

  // configure StageXL default options

  StageXL.stageOptions.renderEngine = RenderEngine.WebGL;
  StageXL.stageOptions.backgroundColor = Color.DarkSlateGray;
  StageXL.bitmapDataLoadOptions.webp = true;

  // init Stage and RenderLoop

  var stage = new Stage(html.querySelector('#stage'), width:480, height: 600);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  // load "spineboy" skeleton resources

  var resourceManager = new ResourceManager();
  resourceManager.addTextFile("spineboy", "spine/spineboy.json");
  //resourceManager.addTextureAtlas("spineboy", "atlas1/spineboy.atlas", TextureAtlasFormat.LIBGDX);
  resourceManager.addTextureAtlas("spineboy", "atlas2/spineboy.json", TextureAtlasFormat.JSONARRAY);
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

  var animations = ["idle", "idle", "walk", "run", "walk"];
  var animationIndex = 0;

  stage.onMouseClick.listen((me) {
    animationIndex = (animationIndex + 1) % animations.length;
    if (animationIndex == 1) {
      skeletonAnimation.state.setAnimationByName(1, "shoot", false);
    } else {
      skeletonAnimation.state.setAnimationByName(0, animations[animationIndex], true);
    }
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
