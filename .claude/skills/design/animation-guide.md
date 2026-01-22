# Animation Guide

Animations communicate change, provide feedback, and guide attention. This guide covers when to animate, timing, performance, and Flutter-specific patterns.

---

## Philosophy: Purposeful Motion

Animation should serve users, not impress them.

| Good Animation | Bad Animation |
|----------------|---------------|
| Helps user understand state changes | Added "because it looks cool" |
| Guides attention to important changes | Distracts from the task |
| Provides feedback that actions worked | Delays user from completing goals |
| Feels natural and expected | Feels jarring or excessive |

**The Apple HIG principle**: "Don't add motion for the sake of adding motion. Gratuitous or excessive animation can distract people or make them feel disconnected."

---

## 1. Timing & Duration

### Duration Guidelines

Research shows ideal animation duration is **100-500ms** for most UI interactions.

| Animation Type | Duration | Notes |
|----------------|----------|-------|
| Micro-interactions (tap feedback) | 50-100ms | Must feel instant |
| Toggle switches, checkboxes | 150-200ms | Quick confirmation |
| Button loading states | 200ms | Show immediately |
| Fade transitions | 200-300ms | Standard crossfade |
| Slide/move transitions | 250-350ms | Page transitions |
| Complex transitions | 300-500ms | Multi-element orchestration |
| Elaborate animations | 500-800ms | Use sparingly |

**Platform-specific adjustments:**
- **Desktop**: 30% faster than mobile (150-200ms vs 250-300ms)
- **Wearables**: 30% faster than mobile

### The 300ms Sweet Spot

For most page transitions, **300ms** is the default recommendation:
- Fast enough to feel responsive
- Slow enough to communicate the change
- Matches Material Design and iOS conventions

```dart
// Standard page transition duration
const kPageTransitionDuration = Duration(milliseconds: 300);

// Micro-interaction duration
const kMicroAnimationDuration = Duration(milliseconds: 150);

// Quick feedback duration
const kFeedbackDuration = Duration(milliseconds: 100);
```

### When Duration Should Be Longer

- **Large area changes**: Full-screen transitions need more time for comprehension
- **Complex state changes**: Multiple elements changing simultaneously
- **Emphasis**: Drawing attention to important changes

### When Duration Should Be Shorter

- **Repeated actions**: Undo, redo, repeated saves
- **User-initiated cancellation**: Dismiss should feel instant
- **Tap feedback**: Must respond within 100ms or feels broken

---

## 2. Easing Curves

Easing makes motion feel natural. Linear animation feels robotic.

### Material Design 3 Standard Curves

| Curve | Use For | Flutter |
|-------|---------|---------|
| **Emphasized** | Most M3 animations, standard transitions | `Curves.easeInOutCubicEmphasized` |
| **Emphasized Accelerate** | Elements leaving screen | `Curves.easeInCubic` |
| **Emphasized Decelerate** | Elements entering screen | `Curves.easeOutCubic` |
| **Standard** | Utility animations, size changes | `Curves.easeInOut` |

### Common Flutter Curves

```dart
// RECOMMENDED for most cases
Curves.easeInOut          // Symmetric ease - general purpose
Curves.easeOutCubic       // Enter screen - fast start, gentle end
Curves.easeInCubic        // Exit screen - gentle start, fast end
Curves.fastOutSlowIn      // Material standard - quick start, slow finish

// SPECIAL CASES
Curves.easeOutBack        // Overshoot then settle (playful)
Curves.elasticOut         // Bounce effect (success celebrations)
Curves.bounceOut          // Bouncing ball effect (use sparingly)

// AVOID
Curves.linear             // Feels robotic, only for progress indicators
Curves.easeInExpo         // Too aggressive for most UI
```

### Curve Selection Guide

```
Is it entering the screen?
  → Use Curves.easeOut variants (decelerate)

Is it leaving the screen?
  → Use Curves.easeIn variants (accelerate)

Is it changing in place (size, color)?
  → Use Curves.easeInOut (symmetric)

Is it a playful/celebratory moment?
  → Consider Curves.easeOutBack or Curves.elasticOut

Is it a progress indicator?
  → Use Curves.linear (constant rate expected)
```

---

## 3. Implicit vs Explicit Animations

Flutter offers two animation approaches. Choose based on complexity.

### Implicit Animations (Start Here)

Framework handles the animation automatically. Best for simple state changes.

```dart
// ✅ PREFERRED: Simple, declarative
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  width: _expanded ? 200 : 100,
  height: _expanded ? 200 : 100,
  color: _selected ? AppColors.primary : AppColors.surface,
  child: child,
)

// Other implicit widgets:
// AnimatedOpacity, AnimatedPadding, AnimatedPositioned,
// AnimatedDefaultTextStyle, AnimatedCrossFade, AnimatedSwitcher
```

**When to use implicit:**
- Property changes (size, color, opacity, padding)
- Simple state transitions
- You don't need precise control over timing

### Explicit Animations (When Needed)

You control the animation directly. Required for complex sequences.

```dart
// When you need more control
final class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this, // CRITICAL: prevents off-screen animation waste
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // CRITICAL: prevent memory leaks
    super.dispose();
  }

  void _startAnimation() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: child,
    );
  }
}
```

**When to use explicit:**
- Staggered animations (multiple elements, timed sequence)
- Repeating animations (loading spinners, pulsing)
- Animations you need to pause, reverse, or control programmatically
- Physics-based animations (springs, flings)

### Decision Tree

```
Can AnimatedFoo or TweenAnimationBuilder do it?
  YES → Use implicit animation
  NO ↓

Do you need to coordinate multiple animations?
  YES → Use explicit with Intervals (staggered)
  NO ↓

Do you need to repeat, pause, or reverse?
  YES → Use explicit with AnimationController
  NO → Reconsider if implicit can work
```

---

## 4. Page Transitions

### Default Transitions

| Platform | Default Behavior |
|----------|------------------|
| **Android** | Zoom + fade (enter), zoom + fade (exit) |
| **iOS** | Slide from right, parallax on exit |
| **Cupertino** | Full iOS-style with swipe-back |

### Custom Page Transitions

```dart
// Custom slide transition
GoRoute(
  path: '/details',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: DetailsScreen(),
    transitionDuration: Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(1.0, 0.0), // From right
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
  ),
)
```

### Common Transition Patterns

```dart
// Fade transition (subtle, good for tabs)
FadeTransition(opacity: animation, child: child)

// Slide from right (standard navigation)
SlideTransition(
  position: Tween(begin: Offset(1, 0), end: Offset.zero).animate(animation),
  child: child,
)

// Slide from bottom (modals, bottom sheets)
SlideTransition(
  position: Tween(begin: Offset(0, 1), end: Offset.zero).animate(animation),
  child: child,
)

// Scale + fade (Material forward navigation)
ScaleTransition(
  scale: Tween(begin: 0.9, end: 1.0).animate(animation),
  child: FadeTransition(opacity: animation, child: child),
)
```

### Matching Transitions to Navigation Type

| Navigation | Recommended Transition |
|------------|----------------------|
| Push to detail | Slide from right (iOS) or scale+fade (Material) |
| Modal/dialog | Slide from bottom or fade |
| Tab switch | Fade or none |
| Back/pop | Reverse of push |
| Replace | Fade crossfade |

---

## 5. Hero Animations (Shared Element)

`Hero` animations create visual continuity between screens by animating a widget from one location to another.

### Basic Implementation

```dart
// Source screen
Hero(
  tag: 'product-${product.id}', // MUST be unique and match
  child: Image.network(product.imageUrl),
)

// Destination screen
Hero(
  tag: 'product-${product.id}', // Same tag
  child: Image.network(product.imageUrl),
)
```

### Best Practices

**DO:**
- Use unique, stable tags (IDs, not indices)
- Keep `Hero` children lightweight (avoid complex layouts)
- Pre-cache images to prevent flickering
- Use for visual continuity (images, avatars, cards)

**DON'T:**
- Overuse - limit to 1-2 heroes per transition
- Use with frequently changing content
- Animate expensive layout widgets
- Use identical tags on same screen

### Common Issues & Fixes

```dart
// Problem: Text glitches during hero animation
// Solution: Wrap text in Material widget
Hero(
  tag: 'title-$id',
  child: Material(
    color: Colors.transparent,
    child: Text(title, style: titleStyle),
  ),
)

// Problem: Hero doesn't animate
// Solution: Ensure tags match exactly and are unique

// Problem: Jank during hero flight
// Solution: Use RepaintBoundary, reduce image size
Hero(
  tag: 'image-$id',
  child: RepaintBoundary(
    child: CachedNetworkImage(imageUrl: url),
  ),
)
```

### Custom Hero Flights

```dart
Hero(
  tag: 'avatar-$id',
  flightShuttleBuilder: (
    flightContext,
    animation,
    flightDirection,
    fromHeroContext,
    toHeroContext,
  ) {
    return ScaleTransition(
      scale: animation.drive(Tween(begin: 1.0, end: 1.2)
          .chain(CurveTween(curve: Curves.easeOutBack))),
      child: fromHeroContext.widget,
    );
  },
  child: CircleAvatar(backgroundImage: NetworkImage(url)),
)
```

---

## 6. Staggered Animations

Animate multiple elements in a choreographed sequence.

### Using Intervals

```dart
final class StaggeredListState extends State<StaggeredList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Create staggered intervals for each item
    _itemAnimations = List.generate(5, (index) {
      final start = index * 0.1; // Each item starts 10% later
      final end = start + 0.4;   // Each animation takes 40% of total
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      );
    });

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        return FadeTransition(
          opacity: _itemAnimations[index],
          child: SlideTransition(
            position: Tween(
              begin: Offset(0, 0.3),
              end: Offset.zero,
            ).animate(_itemAnimations[index]),
            child: ListTile(title: Text('Item $index')),
          ),
        );
      }),
    );
  }
}
```

### Staggered Grid/List Packages

For complex staggered animations, consider:
- `flutter_staggered_animations` - Easy staggered list/grid animations
- `animations` (official Flutter) - Pre-built transition patterns

```dart
// Using flutter_staggered_animations package
AnimationLimiter(
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      return AnimationConfiguration.staggeredList(
        position: index,
        duration: Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: ListTile(title: Text(items[index])),
          ),
        ),
      );
    },
  ),
)
```

---

## 7. Loading & State Animations

### Skeleton Screens (Shimmer)

Use skeleton screens for content loading (200ms+ wait times).

```dart
// Shimmer effect for loading placeholders
final class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

final class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(1.0 + 2.0 * _controller.value, 0),
              colors: isDark
                  ? [Color(0xFF2A2A2A), Color(0xFF3A3A3A), Color(0xFF2A2A2A)]
                  : [Color(0xFFE0E0E0), Color(0xFFF0F0F0), Color(0xFFE0E0E0)],
            ),
          ),
        );
      },
    );
  }
}
```

### Content Transitions

Smooth transition from loading to content:

```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 300),
  child: isLoading
      ? SkeletonContent(key: ValueKey('skeleton'))
      : ActualContent(key: ValueKey('content'), data: data),
)
```

### Success/Error Feedback

```dart
// Animated checkmark on success
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  child: _success
      ? Icon(Icons.check_circle, color: AppColors.success, size: 48)
      : CircularProgressIndicator(),
)

// Error shake (see interaction-guide.md for ShakeWidget)
ShakeWidget(
  shake: _hasError,
  child: TextField(/* ... */),
)
```

---

## 8. Lottie vs Rive

For complex animations (illustrations, characters, onboarding), use dedicated animation tools.

### Comparison

| Aspect | Lottie | Rive |
|--------|--------|------|
| **Source** | After Effects → JSON | Rive editor → .riv |
| **File size** | Larger (10-50KB typical) | Smaller (often 10x smaller) |
| **Performance** | Good (~17-30 FPS complex) | Excellent (~60 FPS) |
| **Interactivity** | Limited | Built-in state machines |
| **Learning curve** | Low (if you know AE) | Medium (new tool) |
| **Community** | Large, many free assets | Growing |
| **Best for** | Simple illustrations, icons | Interactive, complex animations |

### When to Use Each

**Use Lottie when:**
- Team already uses After Effects
- Simple looping animations (loading, success)
- Many free assets available
- Interactivity not needed

**Use Rive when:**
- Interactive animations needed (respond to user input)
- Performance is critical
- Complex character animations
- State-based animations (idle → walking → jumping)

### Implementation

```dart
// Lottie
dependencies:
  lottie: ^3.1.0

Lottie.asset(
  'assets/animations/success.json',
  width: 200,
  height: 200,
  repeat: false,
  onLoaded: (composition) {
    // Animation loaded, can control playback
  },
)

// Rive
dependencies:
  rive: ^0.13.0

RiveAnimation.asset(
  'assets/animations/character.riv',
  stateMachines: ['State Machine 1'],
  onInit: (artboard) {
    // Can get state machine controller here
  },
)
```

---

## 9. Performance Optimization

### The 16ms Budget

Flutter targets 60 FPS = 16.67ms per frame. Animation jank occurs when frames take longer.

### `RepaintBoundary`

Isolate frequently-animating widgets to prevent unnecessary repaints:

```dart
// ✅ Isolate animation from static content
RepaintBoundary(
  child: AnimatedWidget(/* frequently animating */),
)

// When to use:
// - Loading spinners
// - Progress indicators
// - Animated decorations next to static content
// - Any widget animating independently

// When NOT to use:
// - Everything (adds memory overhead)
// - Widgets that change every frame anyway
// - Small, simple widgets
```

### Avoid setState in Animations

```dart
// ❌ BAD: Rebuilds entire widget tree every frame
void _onAnimationTick() {
  setState(() {
    _value = _controller.value;
  });
}

// ✅ GOOD: Use AnimatedBuilder for targeted rebuilds
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Transform.scale(
      scale: _controller.value,
      child: child, // child is NOT rebuilt
    );
  },
  child: ExpensiveWidget(), // Built once, reused
)
```

### Use const Widgets

```dart
// ✅ Mark static children as const
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) => Transform.rotate(
    angle: _controller.value * 2 * pi,
    child: child,
  ),
  child: const Icon(Icons.refresh, size: 32), // const = not rebuilt
)
```

### Profile in Release Mode

Debug mode is NOT representative of performance:

```bash
# Profile mode for accurate performance testing
flutter run --profile
```

Enable repaint rainbow to visualize repaints:
```dart
import 'package:flutter/rendering.dart';
debugRepaintRainbowEnabled = true;
```

---

## 10. Accessibility: Reduced Motion

Some users experience motion sickness. Respect their preference.

### Checking Reduced Motion

```dart
@override
Widget build(BuildContext context) {
  final reduceMotion = MediaQuery.of(context).disableAnimations;

  return AnimatedContainer(
    duration: reduceMotion ? Duration.zero : Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    // ... properties
  );
}
```

### What to Reduce

| Animation Type | With Motion | Reduced Motion |
|----------------|-------------|----------------|
| Page transitions | Slide/scale | Instant or fade |
| Loading spinners | Keep | Keep (functional) |
| Decorative motion | Normal | Disable or static |
| Auto-playing video | Play | Pause, show poster |
| Parallax effects | Normal | Disable |
| Micro-interactions | Normal | Reduce or disable |

### Implementation Pattern

```dart
extension ReducedMotion on BuildContext {
  bool get prefersReducedMotion => MediaQuery.of(this).disableAnimations;

  Duration animationDuration(Duration normal) =>
      prefersReducedMotion ? Duration.zero : normal;
}

// Usage
AnimatedContainer(
  duration: context.animationDuration(Duration(milliseconds: 300)),
  // ...
)
```

---

## Quick Reference

### Duration Cheatsheet

| Type | Duration |
|------|----------|
| Tap feedback | 50-100ms |
| Micro-interaction | 150-200ms |
| Standard transition | 300ms |
| Complex animation | 400-500ms |

### Curve Cheatsheet

| Situation | Curve |
|-----------|-------|
| Entering screen | `Curves.easeOutCubic` |
| Leaving screen | `Curves.easeInCubic` |
| In-place change | `Curves.easeInOut` |
| Playful/bouncy | `Curves.easeOutBack` |
| Standard Material | `Curves.fastOutSlowIn` |

### Animation Type Cheatsheet

| Need | Use |
|------|-----|
| Simple property change | `AnimatedContainer`, `AnimatedOpacity` |
| Switching widgets | `AnimatedSwitcher`, `AnimatedCrossFade` |
| Custom tween | `TweenAnimationBuilder` |
| Full control | `AnimationController` + `AnimatedBuilder` |
| Page transition | `CustomTransitionPage` |
| Shared element | `Hero` |
| Staggered sequence | `Interval` with `AnimationController` |
| Complex illustration | `Lottie` or `Rive` |

---

## Checklist

Before shipping animations:

- [ ] Duration feels natural (not too fast, not sluggish)
- [ ] Curve matches the motion type (enter/exit/in-place)
- [ ] Animation serves a purpose (feedback, guidance, continuity)
- [ ] Reduced motion preference is respected
- [ ] No jank in profile mode
- [ ] `AnimationController`s are disposed
- [ ] `RepaintBoundary` used for isolated animations
- [ ] `Hero` tags are unique and stable
- [ ] Loading states use skeletons (not just spinners)

---

## Sources

- [Apple Human Interface Guidelines - Motion](https://developer.apple.com/design/human-interface-guidelines/motion)
- [Material Design 3 - Motion](https://m3.material.io/styles/motion/overview)
- [Flutter Animation Documentation](https://docs.flutter.dev/ui/animations)
- [Flutter Curves Class](https://api.flutter.dev/flutter/animation/Curves-class.html)
- [NN/g - Animation Duration](https://www.nngroup.com/articles/animation-duration/)
