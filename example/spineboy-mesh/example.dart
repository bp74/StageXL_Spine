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

  var stage = new Stage(html.querySelector('#stage'), width: 480, height: 600);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  // load "spineboy" skeleton resources

  var resourceManager = new ResourceManager();
  resourceManager.addTextFile("spineboy", "spine/spineboy-hoverboard.json");
  //resourceManager.addTextureAtlas("spineboy", "atlas1/spineboy-hoverboard.atlas", TextureAtlasFormat.LIBGDX);
  resourceManager.addTextureAtlas("spineboy", "atlas2/spineboy-hoverboard.json", TextureAtlasFormat.JSONARRAY);
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("spineboy");
  var textureAtlas = resourceManager.getTextureAtlas("spineboy");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);
  var animationStateData = new AnimationStateData(skeletonData);

  // create the display object showing the skeleton animation

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 240;
  skeletonAnimation.y = 550;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.7;
  skeletonAnimation.state.setAnimationByName(0, "fly", true);
  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
}