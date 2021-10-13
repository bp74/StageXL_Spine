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
  var stage = Stage(canvas, width: 600, height: 1000);
  var renderLoop = RenderLoop();
  renderLoop.addStage(stage);

  // load "raptor" skeleton resources

  var resourceManager = ResourceManager();
  var libgdx = TextureAtlasFormat.LIBGDX;
  resourceManager.addTextFile("vine", "spine/vine.json");
  resourceManager.addTextureAtlas("vine", "spine/vine.atlas", libgdx);
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("vine");
  var textureAtlas = resourceManager.getTextureAtlas("vine");
  var attachmentLoader = TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);
  var animationStateData = AnimationStateData(skeletonData);

  // create the display object showing the skeleton animation

  var skeletonAnimation = SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 300;
  skeletonAnimation.y = 950;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.8;
  skeletonAnimation.state.setAnimationByName(0, "grow", true);

  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
}
