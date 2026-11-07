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
