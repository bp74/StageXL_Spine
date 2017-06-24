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
  var stage = new Stage(canvas, width: 600, height: 600);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  // load "raptor" skeleton resources

  var resourceManager = new ResourceManager();
  var format = TextureAtlasFormat.LIBGDX;
  resourceManager.addTextFile("coin", "spine/coin.json");
  resourceManager.addTextureAtlas("coin", "spine/coin.atlas", format);
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("coin");
  var textureAtlas = resourceManager.getTextureAtlas("coin");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);
  var animationStateData = new AnimationStateData(skeletonData);

  // create the display object showing the skeleton animation

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 300;
  skeletonAnimation.y = 600;
  skeletonAnimation.state.setAnimationByName(0, "rotate", true);

  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
}
