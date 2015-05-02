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

  var canvas = html.querySelector('#stage');
  var stage = new Stage(canvas, width:500, height: 300);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  // load "powerup" skeleton resources

  var resourceManager = new ResourceManager();
 resourceManager.addTextFile("powerup", "spine/powerup.json");
  //resourceManager.addTextureAtlas("powerup", "atlas1/powerup.atlas", TextureAtlasFormat.LIBGDX);
  resourceManager.addTextureAtlas("powerup", "atlas2/powerup.json", TextureAtlasFormat.JSONARRAY);
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("powerup");
  var textureAtlas = resourceManager.getTextureAtlas("powerup");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);
  var animationStateData = new AnimationStateData(skeletonData);

  // create the display object showing the skeleton animation

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 250;
  skeletonAnimation.y = 280;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.7;
  skeletonAnimation.state.setAnimationByName(0, "animation", true);
  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
}
