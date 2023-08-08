import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../design_system_flutter.dart';

const _trackWidth = 50.0;
const _trackHeight = 31.0;
const _trackRadius = _trackHeight * 0.5;
const _trackInnerStart = _trackHeight * 0.5;
const _trackInnerEnd = _trackWidth - _trackInnerStart;
const _trackInnerLength = _trackInnerEnd - _trackInnerStart;
const _switchDisabledOpacity = 0.5;
const _thumbRadius = 27.0 * 0.5;
const _thumbBoxShadows = <BoxShadow>[
  BoxShadow(
    color: Color(0x14000000),
    offset: Offset(0, 4),
    blurRadius: 9.0,
    spreadRadius: 2.0,
  ),
  BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 4),
    blurRadius: 2.0,
  ),
  BoxShadow(
    color: Color(0x1C000000),
    offset: Offset(0, 0),
    blurRadius: 1.0,
    spreadRadius: 1.0,
  ),
  BoxShadow(
    color: Color(0x12000000),
    offset: Offset(0, 1),
    blurRadius: 1.0,
  ),
];

/// The SBB Switch. Use according to documentation.
///
/// The Switch itself does not maintain any state. Instead, when the state of
/// the Switch changes, the widget calls the [onChanged] callback. Most
/// widgets that use a Switch will listen for the [onChanged] callback and
/// rebuild the Switch with a new [value] to update the visual appearance of
/// the Switch.
///
/// The Switch can optionally display two values - true or false
///
/// See also:
///
/// * [SBBSwitchListItem], which builds this Widget as a part of a List Item
/// so that you can give the Switch a label, a subtext, a leading icon and a
/// link Widget.
/// * [SBBCheckbox], a widget with semantics similar to [SBBSwitch].
/// * [SBBRadioButton], for selecting among a set of explicit values.
/// * [SBBSegmentedButton], for selecting among a set of explicit values.
/// * <https://digital.sbb.ch/en/design-system/mobile/components/switch>
class SBBSwitch extends StatefulWidget {
  const SBBSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<SBBSwitch> createState() => _SBBSwitchState();
}

class _SBBSwitchState extends State<SBBSwitch> with TickerProviderStateMixin {
  late TapGestureRecognizer _tap;
  late HorizontalDragGestureRecognizer _drag;

  late AnimationController _positionController;
  late CurvedAnimation position;

  late bool isFocused;

  bool get isEnabled => widget.onChanged != null;

  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _handleTap),
  };

  // A non-null boolean value that changes to true at the end of a drag if the
  // switch must be animated to the position indicated by the widget's value.
  bool needsPositionAnimation = false;

  @override
  void initState() {
    super.initState();

    isFocused = false;

    _tap = TapGestureRecognizer()..onTap = _handleTap;
    _drag = HorizontalDragGestureRecognizer()
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd;

    _positionController = AnimationController(
      duration: kThemeAnimationDuration,
      value: widget.value ? 1.0 : 0.0,
      vsync: this,
    );
    position = CurvedAnimation(
      parent: _positionController,
      curve: Curves.linear,
    );
  }

  @override
  void didUpdateWidget(SBBSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (needsPositionAnimation || oldWidget.value != widget.value) {
      _resumePositionAnimation(isLinear: needsPositionAnimation);
    }
  }

  void _resumePositionAnimation({bool isLinear = true}) {
    needsPositionAnimation = false;
    position
      ..curve = isLinear ? Curves.linear : Curves.ease
      ..reverseCurve = isLinear ? Curves.linear : Curves.ease.flipped;
    if (widget.value) {
      _positionController.forward();
    } else {
      _positionController.reverse();
    }
  }

  void _handleTap([Intent? _]) {
    if (isEnabled) {
      widget.onChanged!(!widget.value);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isEnabled) {
      position
        ..curve = Curves.linear
        ..reverseCurve = Curves.linear;
      final double delta = details.primaryDelta! / _trackInnerLength;
      _positionController.value += delta;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      needsPositionAnimation = true;
    });
    if (position.value >= 0.5 != widget.value) {
      widget.onChanged!(!widget.value);
    }
  }

  void _onShowFocusHighlight(bool showHighlight) {
    setState(() {
      isFocused = showHighlight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = SBBControlStyles.of(context).switchToggle!;

    final opacity = isEnabled ? 1.0 : _switchDisabledOpacity;
    final thumbColor =
        isEnabled ? style.thumbColor! : style.thumbColorDisabled!;
    final activeColor =
        isEnabled ? style.activeColor! : style.activeColorDisabled!;
    final trackColor =
        isEnabled ? style.trackColor! : style.trackColorDisabled!;
    final focusColor = activeColor.withOpacity(_switchDisabledOpacity);
    if (needsPositionAnimation) {
      _resumePositionAnimation();
    }
    return Opacity(
      opacity: opacity,
      child: FocusableActionDetector(
        onShowFocusHighlight: _onShowFocusHighlight,
        actions: _actionMap,
        enabled: isEnabled,
        child: _SBBSwitchRenderObjectWidget(
          value: widget.value,
          thumbColor: thumbColor,
          activeColor: activeColor,
          trackColor: trackColor,
          focusColor: focusColor,
          onChanged: widget.onChanged,
          isFocused: isFocused,
          state: this,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tap.dispose();
    _drag.dispose();
    _positionController.dispose();
    super.dispose();
  }
}

class _SBBSwitchRenderObjectWidget extends LeafRenderObjectWidget {
  const _SBBSwitchRenderObjectWidget({
    required this.value,
    required this.thumbColor,
    required this.activeColor,
    required this.trackColor,
    required this.focusColor,
    required this.onChanged,
    required this.isFocused,
    required this.state,
  });

  final bool value;
  final Color thumbColor;
  final Color activeColor;
  final Color trackColor;
  final Color focusColor;
  final ValueChanged<bool>? onChanged;
  final _SBBSwitchState state;
  final bool isFocused;

  @override
  _SBBRenderSwitch createRenderObject(BuildContext context) {
    return _SBBRenderSwitch(
      value: value,
      thumbColor: thumbColor,
      activeColor: activeColor,
      trackColor: trackColor,
      focusColor: focusColor,
      onChanged: onChanged,
      isFocused: isFocused,
      state: state,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _SBBRenderSwitch renderObject) {
    assert(renderObject._state == state);
    renderObject
      ..value = value
      ..thumbColor = thumbColor
      ..activeColor = activeColor
      ..trackColor = trackColor
      ..focusColor = focusColor
      ..onChanged = onChanged
      ..isFocused = isFocused;
  }
}

class _SBBRenderSwitch extends RenderConstrainedBox {
  _SBBRenderSwitch({
    required bool value,
    required Color thumbColor,
    required Color activeColor,
    required Color trackColor,
    required Color focusColor,
    ValueChanged<bool>? onChanged,
    required bool isFocused,
    required _SBBSwitchState state,
  })  : _value = value,
        _thumbColor = thumbColor,
        _activeColor = activeColor,
        _trackColor = trackColor,
        _focusColor = focusColor,
        _onChanged = onChanged,
        _isFocused = isFocused,
        _state = state,
        super(
          additionalConstraints: const BoxConstraints.tightFor(
            width: _trackWidth,
            height: _trackHeight,
          ),
        ) {
    state.position.addListener(markNeedsPaint);
  }

  final _SBBSwitchState _state;

  bool get value => _value;
  bool _value;

  set value(bool value) {
    if (value == _value) {
      return;
    }
    _value = value;
    markNeedsSemanticsUpdate();
  }

  Color get thumbColor => _thumbColor;
  Color _thumbColor;

  set thumbColor(Color value) {
    if (value == _thumbColor) {
      return;
    }
    _thumbColor = value;
    markNeedsPaint();
  }

  Color get activeColor => _activeColor;
  Color _activeColor;

  set activeColor(Color value) {
    if (value == _activeColor) {
      return;
    }
    _activeColor = value;
    markNeedsPaint();
  }

  Color get trackColor => _trackColor;
  Color _trackColor;

  set trackColor(Color value) {
    if (value == _trackColor) {
      return;
    }
    _trackColor = value;
    markNeedsPaint();
  }

  Color get focusColor => _focusColor;
  Color _focusColor;

  set focusColor(Color value) {
    if (value == _focusColor) {
      return;
    }
    _focusColor = value;
    markNeedsPaint();
  }

  ValueChanged<bool>? get onChanged => _onChanged;
  ValueChanged<bool>? _onChanged;

  set onChanged(ValueChanged<bool>? value) {
    if (value == _onChanged) {
      return;
    }
    final bool wasInteractive = isEnabled;
    _onChanged = value;
    if (wasInteractive != isEnabled) {
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  bool get isFocused => _isFocused;
  bool _isFocused;

  set isFocused(bool value) {
    if (value == _isFocused) {
      return;
    }
    _isFocused = value;
    markNeedsPaint();
  }

  bool get isEnabled => onChanged != null;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isEnabled) {
      _state._drag.addPointer(event);
      _state._tap.addPointer(event);
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    if (isEnabled) {
      config.onTap = _state._handleTap;
    }

    config.isEnabled = isEnabled;
    config.isToggled = _value;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    final currentValue = _state.position.value;

    final trackRRect = RRect.fromLTRBR(
      0.0,
      0.0,
      _trackWidth,
      _trackHeight,
      const Radius.circular(_trackRadius),
    );
    final currentTrackColor = Color.lerp(
      trackColor,
      activeColor,
      currentValue,
    )!;
    final trackPaint = Paint()..color = currentTrackColor;
    canvas.drawRRect(trackRRect, trackPaint);

    if (_isFocused) {
      // Paints a border around the switch in the focus color.
      final RRect borderTrackRRect = trackRRect.inflate(1.75);
      final Paint borderPaint = Paint()
        ..color = focusColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawRRect(borderTrackRRect, borderPaint);
    }

    final thumbCenterX = lerpDouble(
      _trackInnerStart,
      _trackInnerEnd,
      currentValue,
    )!;
    const thumbCenterY = _trackHeight * 0.5;
    final thumbRect = Rect.fromCircle(
      center: Offset(thumbCenterX, thumbCenterY),
      radius: _thumbRadius,
    );

    for (final BoxShadow shadow in _thumbBoxShadows) {
      final shadowRect = thumbRect.shift(shadow.offset);
      final shadowPaint = shadow.toPaint();
      canvas.drawOval(shadowRect, shadowPaint);
    }

    final thumbPaint = Paint()..color = thumbColor;
    canvas.drawOval(thumbRect, thumbPaint);
  }
}
