# tap-input Specification

## Purpose
Defold 게임의 UI 포인터 입력을 한 제스처 단위로 정리하고, 누른 대상 위에서 손을 뗄 때만 실행하는 공용 탭 판정을 제공한다.

## Requirements

### Requirement: One pointer source per gesture
The helper SHALL accept a gesture from the first source that presses and SHALL ignore events from any other source until that gesture is released.

#### Scenario: Touch delivered as touch and emulated mouse
- **WHEN** one physical touch produces a touch press and a mouse press in the same frame
- **THEN** only the first press is accepted and the other source's held and release events are ignored

#### Scenario: Engine emulates the touch as a mouse first
- **WHEN** a mouse press for a touch arrives before the touch press of the same gesture
- **THEN** the touch takes the gesture over without a second press, and the gesture ends with the touch release while the emulated mouse events are ignored

#### Scenario: Native mobile touch-only mode
- **WHEN** the gate is created in touch-only mode
- **THEN** every mouse event is ignored, including one that arrives before any touch

### Requirement: Compatibility mouse echo is not a new tap
The helper SHALL ignore mouse events that arrive within the configured echo window (default 1.0 s) after any accepted touch event, regardless of their position.

#### Scenario: Browser compatibility click after a touch
- **WHEN** a touch ends and a mouse press and release arrive 0.6 s later at a different position
- **THEN** neither mouse event is accepted

#### Scenario: Real mouse after the window
- **WHEN** a mouse press arrives after the echo window has passed
- **THEN** it is accepted as a new gesture

### Requirement: Orphan events are ignored
The helper SHALL ignore a release or held event that has no accepted press, including after the caller explicitly resets the gesture.

#### Scenario: Release after a recovered gesture
- **WHEN** the caller resets the gate and the original release arrives later
- **THEN** the release is not accepted

### Requirement: Release-activated taps
A tap SHALL activate only when the release lands on the same target that the press armed. Leaving the target SHALL disarm it, returning SHALL re-arm it, and a press that hit no target SHALL never activate.

#### Scenario: Normal tap
- **WHEN** the pointer presses and releases on the same target
- **THEN** that target is activated exactly once

#### Scenario: Slide off and release
- **WHEN** the pointer presses a target, moves off it and releases elsewhere
- **THEN** nothing is activated

#### Scenario: Slide onto a button
- **WHEN** the pointer presses empty space and releases on a target
- **THEN** nothing is activated

#### Scenario: Scroll slop
- **WHEN** a tap configured with a slop moves farther than the slop before release
- **THEN** it never re-arms and does not activate

### Requirement: Pressed feedback
The helper SHALL expose the currently armed target and its bounds so the caller can draw a pressed state, and SHALL report no pressed target while disarmed or idle.

#### Scenario: Pressed state follows the finger
- **WHEN** a target is armed and the pointer leaves it
- **THEN** the pressed query changes from the target to none and the move reports the change

### Requirement: Target lookup and modal blocking
Target lookup SHALL support GUI nodes, center-anchored rectangles and custom hit functions, SHALL return the first matching target in caller priority order, SHALL skip disabled targets, and in modal mode SHALL return an outside marker instead of falling through to targets beneath the modal.

#### Scenario: Outside tap on a modal
- **WHEN** a modal target list is queried at a point that matches none of its targets
- **THEN** the lookup returns the outside marker

#### Scenario: Disabled GUI node
- **WHEN** a GUI node target is disabled
- **THEN** it is not returned even if the point is inside it

### Requirement: Invalid input fails loudly
The helper MUST raise an error for an unknown source, unknown phase, missing clock, invalid coordinates, a target without an id, or a target without a hit shape.

#### Scenario: Unknown source
- **WHEN** the gate receives a source other than touch or mouse
- **THEN** an error is raised instead of the event being ignored
