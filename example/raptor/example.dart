import 'dart:async';
import 'dart:math' as math;
import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Future main() async {

  // configure StageXL default options

  StageXL.stageOptions.renderEngine = RenderEngine.WebGL;
  StageXL.stageOptions.backgroundColor = Color.DarkSlateGray;
  StageXL.bitmapDataLoadOptions.webp = true;

  // init Stage and RenderLoop

  var canvas = html.querySelector('#stage');
  var stage = new Stage(canvas, width: 1300, height: 1100);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  // load "raptor" skeleton resources

  var resourceManager = new ResourceManager();
  resourceManager.addTextFile("raptor", "spine/raptor.json");
  //resourceManager.addTextureAtlas("raptor", "atlas1/raptor.atlas", TextureAtlasFormat.LIBGDX);
  resourceManager.addTextureAtlas("raptor", "atlas2/raptor.json", TextureAtlasFormat.JSONARRAY);
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("raptor");
  var textureAtlas = resourceManager.getTextureAtlas("raptor");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);
  var animationStateData = new AnimationStateData(skeletonData);

  // create the display object showing the skeleton animation

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 600;
  skeletonAnimation.y = 1000;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.8;
  skeletonAnimation.state.setAnimationByName(0, "walk", true);

  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
  stage.juggler.transition(0, 1800, 3600, TransitionFunction.linear,
      (v) => skeletonAnimation.timeScale = 0.7 + 0.5 * math.sin(v));
}
