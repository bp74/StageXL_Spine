part of stagexl_spine;

class SkeletonAnimation extends SkeletonDisplayObject implements Animatable {
  final AnimationState state;
  double timeScale = 1.0;

  SkeletonAnimation(SkeletonData skeletonData, [AnimationStateData? stateData])
      : state = AnimationState(stateData ?? AnimationStateData(skeletonData)),
        super(skeletonData);

  @override
  bool advanceTime(num time) {
    double timeScaled = time * timeScale;
    skeleton.update(timeScaled);
    state.update(timeScaled);
    state.apply(skeleton);
    skeleton.updateWorldTransform();
    return true;
  }
}
