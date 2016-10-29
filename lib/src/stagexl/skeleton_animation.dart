part of stagexl_spine;

class SkeletonAnimation extends SkeletonDisplayObject implements Animatable {

  final AnimationState state;
  double timeScale = 1.0;

  SkeletonAnimation(SkeletonData skeletonData, [AnimationStateData stateData])
      : super(skeletonData),
        state = new AnimationState(stateData ?? new AnimationStateData(skeletonData));

  bool advanceTime(double time) {
    time = time * timeScale;
    skeleton.update(time);
    state.update(time);
    state.apply(skeleton);
    skeleton.updateWorldTransform();
    return true;
  }
}
