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
  var stage = new Stage(canvas, width: 600, height: 1000);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  // load "raptor" skeleton resources

  var resourceManager = new ResourceManager();
  var libgdx = TextureAtlasFormat.LIBGDX;
  resourceManager.addTextFile("vine", "spine/vine.json");
  resourceManager.addTextureAtlas("vine", "spine/vine.atlas", libgdx);
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("vine");
  var textureAtlas = resourceManager.getTextureAtlas("vine");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);
  var animationStateData = new AnimationStateData(skeletonData);

  // create the display object showing the skeleton animation

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 300;
  skeletonAnimation.y = 950;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.8;
  skeletonAnimation.state.setAnimationByName(0, "grow", true);

  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
}
