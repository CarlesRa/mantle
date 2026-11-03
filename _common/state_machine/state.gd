## Base class for all states used by a StateMachine.
## Concrete states extend it and override only the methods they need.
class_name State
extends Node

## Asks the StateMachine to change to another state, identified by its node name.
@warning_ignore("unused_signal")
signal change_state(state_name: StringName)

## Entity controlled by this state. Assigned by the StateMachine on startup.
var actor: CharacterBody2D

## Called once when the state is entered.
func enter() -> void: pass

## Called once when the state is exited.
func exit() -> void: pass

## Called every physics frame while the state is active.
func physics_update(_delta: float) -> void: pass

## Called once by the StateMachine after the state is registered.
## Returns false if the state could not be set up.
func setup(new_actor: CharacterBody2D) -> bool:
	if not new_actor:
		return false
	actor = new_actor
	return true
