library stagexl_spine;

import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:stagexl/stagexl.dart';

part 'src/bone.dart';
part 'src/bone_data.dart';
part 'src/event.dart';
part 'src/event_data.dart';
part 'src/ik_constraint.dart';
part 'src/ik_constraint_data.dart';
part 'src/skeleton.dart';
part 'src/skeleton_bounds.dart';
part 'src/skeleton_data.dart';
part 'src/skeleton_loader.dart';
part 'src/skin.dart';
part 'src/slot.dart';
part 'src/slot_data.dart';

part 'src/animation/animation.dart';
part 'src/animation/animation_state.dart';
part 'src/animation/animation_state_data.dart';
part 'src/animation/attachment_timeline.dart';
part 'src/animation/color_timeline.dart';
part 'src/animation/curve_timeline.dart';
part 'src/animation/draw_order_timeline.dart';
part 'src/animation/event_timeline.dart';
part 'src/animation/ffd_timeline.dart';
part 'src/animation/flip_x_timeline.dart';
part 'src/animation/flip_y_timeline.dart';
part 'src/animation/ik_constraint_timeline.dart';
part 'src/animation/rotate_timeline.dart';
part 'src/animation/scale_timeline.dart';
part 'src/animation/timeline.dart';
part 'src/animation/track_entry.dart';
part 'src/animation/translate_timeline.dart';

part 'src/attachments/attachment.dart';
part 'src/attachments/attachment_loader.dart';
part 'src/attachments/attachment_type.dart';
part 'src/attachments/bounding_box_attachment.dart';
part 'src/attachments/mesh_attachment.dart';
part 'src/attachments/region_attachment.dart';
part 'src/attachments/skinned_mesh_attachment.dart';

part 'src/stagexl/skeleton_animation.dart';
part 'src/stagexl/skeleton_display_object.dart';
part 'src/stagexl/texture_atlas_attachment_loader.dart';
