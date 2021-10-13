import 'dart:async';
import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Future main() async {
  // configure StageXL default options

  StageXL.stageOptions.renderEngine = RenderEngine.WebGL;
  StageXL.stageOptions.backgroundColor = Color.DarkSlateGray;

  // init Stage and RenderLoop

  var canvas = html.querySelector('#stage') as html.CanvasElement;
  var stage = Stage(canvas, width: 600, height: 600);
  var renderLoop = RenderLoop();
  renderLoop.addStage(stage);

  // load "raptor" skeleton resources

  var resourceManager = ResourceManager();
  var format = TextureAtlasFormat.LIBGDX;
  resourceManager.addTextFile("coin", "spine/coin.json");
  resourceManager.addTextureAtlas("coin", "spine/coin.atlas", format);
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("coin");
  var textureAtlas = resourceManager.getTextureAtlas("coin");
  var attachmentLoader = TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);
  var animationStateData = AnimationStateData(skeletonData);

  // create the display object showing the skeleton animation

  var skeletonAnimation = SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 300;
  skeletonAnimation.y = 600;
  skeletonAnimation.state.setAnimationByName(0, "rotate", true);

  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
}
