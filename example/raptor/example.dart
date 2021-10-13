import 'dart:async';
import 'dart:math' as math;
import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Future main() async {
  // configure StageXL default options

  StageXL.stageOptions.renderEngine = RenderEngine.WebGL;
  StageXL.stageOptions.backgroundColor = Color.DarkSlateGray;

  // init Stage and RenderLoop

  var canvas = html.querySelector('#stage') as html.CanvasElement;
  var stage = Stage(canvas, width: 1300, height: 1100);
  var renderLoop = RenderLoop();
  renderLoop.addStage(stage);
  stage.console.visible = true;
  stage.console.alpha = 0.75;

  // load "raptor" skeleton resources

  var resourceManager = ResourceManager();
  //var libgdx = TextureAtlasFormat.LIBGDX;
  resourceManager.addTextFile("raptor", "spine/raptor.json");
  //resourceManager.addTextureAtlas("raptor", "atlas1/raptor.atlas", libgdx);
  //resourceManager.addTextureAtlas("raptor", "atlas2/raptor.json");
  resourceManager.addTextureAtlas("raptor", "atlas3/raptor.json");
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("raptor");
  var textureAtlas = resourceManager.getTextureAtlas("raptor");
  var attachmentLoader = TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);
  var animationStateData = AnimationStateData(skeletonData);

  // create the display object showing the skeleton animation

  var skeletonAnimation = SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 600;
  skeletonAnimation.y = 1000;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.8;
  skeletonAnimation.state.setAnimationByName(0, "walk", true);

  stage.onMouseClick.listen((me) {
    var state = skeletonAnimation.state;
    var roarAnimation = state.setAnimationByName(0, "roar", false);
    roarAnimation.mixDuration = 0.25;
    roarAnimation.onTrackComplete.first.then((_) {
      var walkAnimation = state.setAnimationByName(0, "walk", true);
      walkAnimation.mixDuration = 1.0;
    });
  });

  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
  stage.juggler.onElapsedTimeChange.listen((time) {
    skeletonAnimation.timeScale = 0.7 + 0.5 * math.sin(time / 2);
  });
}
