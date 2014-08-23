import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Stage stage;
RenderLoop renderLoop;
ResourceManager resourceManager = new ResourceManager();

void main() {

  var canvas = html.querySelector('#stage');

  stage = new Stage(canvas, webGL: true, width:500, height: 300, color: Color.DarkSlateGray);
  stage.scaleMode = StageScaleMode.SHOW_ALL;
  stage.align = StageAlign.NONE;

  renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  BitmapData.defaultLoadOptions.webp = true;

  resourceManager.addTextFile("powerup", "spine/powerup.json");
  //resourceManager.addTextureAtlas("powerup", "atlas1/powerup.atlas", TextureAtlasFormat.LIBGDX);
  resourceManager.addTextureAtlas("powerup", "atlas2/powerup.json", TextureAtlasFormat.JSONARRAY);
  resourceManager.load().then((rm) => startPowerup());
}

//-----------------------------------------------------------------------------

void startPowerup() {

  var spineJson = resourceManager.getTextFile("powerup");
  var textureAtlas = resourceManager.getTextureAtlas("powerup");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);

  var animationStateData = new AnimationStateData(skeletonData);

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 250;
  skeletonAnimation.y = 280;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.7;

  skeletonAnimation.state.setAnimationByName(0, "animation", true);

  var skeletonAnimationContainer = new Sprite();
  skeletonAnimationContainer.addChild(skeletonAnimation);
  skeletonAnimationContainer.useHandCursor = true;

  stage.addChild(skeletonAnimationContainer);
  stage.juggler.add(skeletonAnimation);
}
