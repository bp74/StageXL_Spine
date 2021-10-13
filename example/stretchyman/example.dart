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
  var stage = Stage(canvas, width: 1600, height: 800);
  var renderLoop = RenderLoop();
  renderLoop.addStage(stage);

  // load "raptor" skeleton resources

  var resourceManager = ResourceManager();
  var format = TextureAtlasFormat.LIBGDX;
  resourceManager.addTextFile("stretchyman", "spine/stretchyman.json");
  resourceManager.addTextureAtlas("stretchyman", "spine/stretchyman.atlas", format);
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("stretchyman");
  var textureAtlas = resourceManager.getTextureAtlas("stretchyman");
  var attachmentLoader = TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);
  var animationStateData = AnimationStateData(skeletonData);

  // create the display object showing the skeleton animation

  var skeletonAnimation = SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 200;
  skeletonAnimation.y = 700;
  //skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.5;
  skeletonAnimation.state.setAnimationByName(0, "sneak", true);

  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
}
