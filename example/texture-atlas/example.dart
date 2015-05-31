import 'dart:async';
import 'dart:math' as math;
import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Future main() async {

  // configure StageXL default options

  StageXL.stageOptions.renderEngine = RenderEngine.WebGL;
  StageXL.stageOptions.backgroundColor = Color.Azure;
  StageXL.bitmapDataLoadOptions.webp = true;

  // init Stage and RenderLoop

  var canvas = html.querySelector('#stage');
  var stage = new Stage(canvas, width: 800, height: 400);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  // load "raptor" skeleton resources

  var resourceManager = new ResourceManager();
  resourceManager.addTextureAtlas("combined", "atlas/combined.json");
  resourceManager.addTextFile("goblins-mesh-spine", "atlas/goblins-mesh.json");
  resourceManager.addTextFile("goblins-mesh-atlas", "atlas/goblins-mesh.atlas");
  resourceManager.addTextFile("hero-mesh-spine", "atlas/hero-mesh.json");
  resourceManager.addTextFile("hero-mesh-atlas", "atlas/hero-mesh.atlas");
  resourceManager.addTextFile("raptor-spine", "atlas/raptor.json");
  resourceManager.addTextFile("raptor-atlas", "atlas/raptor.atlas");
  resourceManager.addTextFile("speedy-spine", "atlas/speedy.json");
  resourceManager.addTextFile("speedy-atlas", "atlas/speedy.atlas");
  resourceManager.addTextFile("spineboy-hoverboard-spine", "atlas/spineboy-hoverboard.json");
  resourceManager.addTextFile("spineboy-hoverboard-atlas", "atlas/spineboy-hoverboard.atlas");
  await resourceManager.load();

  //---------------------------------------------------------------------------
  // load Spine skeletons from combined texture and the individual definitions

  var names = ["goblins-mesh", "hero-mesh", "raptor", "speedy", "spineboy-hoverboard"];
  var skeletonAnimations = new List<SkeletonAnimation>();

  for (var name in names) {

    // get spine texture atlases from combined texture atlas

    var bitmapData = resourceManager.getTextureAtlas("combined").getBitmapData(name);
    var spine = resourceManager.getTextFile("$name-spine");
    var atlas = resourceManager.getTextFile("$name-atlas");
    var format = TextureAtlasFormat.LIBGDX;
    var textureAtlas = await TextureAtlas.fromBitmapData(bitmapData, atlas, format);

    // create spine skeleton data

    var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
    var skeletonLoader = new SkeletonLoader(attachmentLoader);
    var skeletonData = skeletonLoader.readSkeletonData(spine);

    // create spine skeleton animation

    var animationStateData = new AnimationStateData(skeletonData);
    var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
    skeletonAnimations.add(skeletonAnimation);
  }

  //---------------------------------------------------------------------------
  // setup the skeleton animations

  skeletonAnimations[0] // goblins-mesh
    ..state.setAnimationByName(0, "walk", true)
    ..skeleton.skinName = "goblin"
    ..scaleX = 1.0 ..scaleY = 1.0
    ..x = 150..y = 320;

  skeletonAnimations[1] // hero-mesh
    ..state.setAnimationByName(0, "Walk", true)
    ..scaleX = 0.7 ..scaleY = 0.7
    ..x = 260..y = 390;

  skeletonAnimations[2] // raptor
    ..state.setAnimationByName(0, "walk", true)
    ..scaleX = 0.28 ..scaleY = 0.28
    ..x = 380 ..y = 320;

  skeletonAnimations[3] // speedy
    ..state.setAnimationByName(0, "run", true)
    ..scaleX = 0.65 ..scaleY = 0.65
    ..x = 550 ..y = 390;

  skeletonAnimations[4] // spineboy-hoverboard
    ..state.setAnimationByName(0, "fly", true)
    ..scaleX = 0.32 ..scaleY = 0.32
    ..x = 660 ..y = 320;

  // add the skeleton animations to the Stage and the Juggler

  stage.addChild(skeletonAnimations[0]);
  stage.addChild(skeletonAnimations[2]);
  stage.addChild(skeletonAnimations[4]);
  stage.addChild(skeletonAnimations[1]);
  stage.addChild(skeletonAnimations[3]);

  stage.juggler.add(skeletonAnimations[0]);
  stage.juggler.add(skeletonAnimations[1]);
  stage.juggler.add(skeletonAnimations[2]);
  stage.juggler.add(skeletonAnimations[3]);
  stage.juggler.add(skeletonAnimations[4]);

}
