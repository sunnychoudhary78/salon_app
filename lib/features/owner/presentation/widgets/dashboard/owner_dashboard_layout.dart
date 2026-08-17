import 'package:flutter/material.dart';

/// Vertical rhythm for the owner dashboard segments. Replaces the ad-hoc mix of
/// 8/12/14/18/22px gaps the single-scroll dashboard used between sections.
const double kOwnerSectionGap = 16;

/// Gap between closely related elements inside one section.
const double kOwnerTightGap = 8;

const Widget kOwnerSectionSpacer = SizedBox(height: kOwnerSectionGap);

const Widget kOwnerTightSpacer = SizedBox(height: kOwnerTightGap);

/// Horizontal page padding shared by every segment so the three views line up
/// when swiped between.
const EdgeInsets kOwnerSegmentPadding = EdgeInsets.fromLTRB(16, 12, 16, 0);
