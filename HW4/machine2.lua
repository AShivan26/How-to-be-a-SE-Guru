--[[
Because we are passing a payload that contains the queue of events,
we gain a really powerful new ability: the FSM can modify its own
future. If the character takes a hit and their HP drops below 0,
the FSM can dynamically inject a "die" event to the very front of
the queue, instantly hijacking the flow.

You don't need to change the engine from the previous step at all.
You just need this main.lua:
]]--
local machine = require"fsm3"

-- HELPER FUNCTIONS FOR CLEANER DSL

-- 1. Fix: String concatenation spam with character status
local function say(msg)
  return function(p)
    local output = msg:gsub("{name}", p.name):gsub("{hp}", p.hp)
    print(output)
  end
end

-- 2. Fix: Repetitive "[name] verb" pattern
local function action_say(verb)
  return say("[{name}] " .. verb)
end

-- 3. Fix: Damage application boilerplate
local function take_damage()
  return function(p)
    local dmg = table.remove(p.damage_queue, 1) or 0
    p.hp = p.hp - dmg
    print(string.format("   > BOOM! [%s] took %d damage! HP is now %d", p.name, dmg, p.hp))
    if p.hp <= 0 then
      print("   > SYSTEM: Fatal damage detected! Injecting 'die' event...")
      table.insert(p.queue, 1, "die")
    end
  end
end

-- 4. Fix: State definition boilerplate
local function state(action_fn, transitions)
  return { action = action_fn, transitions = transitions }
end

-- REFACTORED RULES USING HELPERS
local rpg_rules = {
  idle = state(
    action_say("is idling. HP: {hp}"),
    { walk = "moving", attack = "attacking", hit = "staggered", die = "dead" }
  ),
  
  moving = state(
    action_say("is walking forward."),
    { stop = "idle", attack = "attacking", hit = "staggered", die = "dead" }
  ),
  
  attacking = state(
    action_say("swings their weapon!"),
    { recover = "idle", hit = "staggered", die = "dead" }
  ),
  
  staggered = state(
    take_damage(),
    { recover = "idle", die = "dead" }
  ),
  
  dead = state(
    action_say("has collapsed to the ground."),
    { revive = "idle" }
  )
}

-- Add trace printer helper
local function print_trace(p)
  print("\n=== TRANSITION TRACE ===")
  for i, transition in ipairs(p.trace or {}) do
    print(i .. ". " .. transition)
  end
end

-- 2. Define the payload (Memory + Queues)
local my_payload = {
  name = "Hero",
  hp = 100,
  -- The sequence of events we want the FSM to process
  queue = { 
    "walk", "attack", "recover", 
    "hit", "recover", 
    "walk", "attack", 
    "hit", "walk" -- Note: They will die on this second hit, so the final "walk" will be ignored!
  },
  -- A custom queue just for this payload to hold damage amounts
  damage_queue = { 15, 90 },
  -- Initialize trace table
  trace = {}
}

print("=== STARTING TCO RPG BATTLE ===")

-- Boot up the machine! (Passing the rules, initial state, and payload memory)
local final_memory = machine.start(rpg_rules, "idle", my_payload)

print("\n=== PROCESSING COMPLETE ===")
print("Final Queue Size remaining: " .. #final_memory.queue)
print("Final HP: " .. final_memory.hp)
print_trace(final_memory)
