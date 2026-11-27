## Global event bus. Holds signals only, no logic.
extends Node

# Player

## Emitted when the player starts a jump.
@warning_ignore("unused_signal")
signal player_jumped

## Emitted when the player touches the ground after falling.
@warning_ignore("unused_signal")
signal player_landed

## Emitted when the player changes form, and once at startup with the initial form.
@warning_ignore("unused_signal")
signal player_form_changed(form: PlayerForm)

## Emitted when a form transformation begins, with its resolved effect duration.
@warning_ignore("unused_signal")
signal player_transform_started(form: PlayerForm, duration: float)

## Emmited when the plyayer 
@warning_ignore("unused_signal")
signal player_hit

@warning_ignore("unused_signal")
signal player_died

@warning_ignore("unused_signal")
signal player_attacked(attack: AttackData)

## Emitted when the player's health changes, and once at startup with the initial health.
@warning_ignore("unused_signal")
signal player_health_changed(current: int, max_value: int)

# Game flow

@warning_ignore("unused_signal")
signal game_started

@warning_ignore("unused_signal")
signal game_paused

@warning_ignore("unused_signal")
signal game_resumed

@warning_ignore("unused_signal")
signal game_over

@warning_ignore("unused_signal")
signal checkpoint_saved

@warning_ignore("unused_signal")
signal checkpoint_loaded
