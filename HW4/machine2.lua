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

-- LINTER: Static analyzer for FSM rules
local function lint(rules, initial)
  print("\n=== FSM LINTER ===")
  local warnings = 0
  
  -- Build set of all defined states
  local defined_states = {}
  for state_name in pairs(rules) do
    defined_states[state_name] = true
  end
  
  -- Build set of reachable states
  local reachable = { [initial] = true }
  local queue = { initial }
  while #queue > 0 do
    local current = table.remove(queue, 1)
    if rules[current] and rules[current].transitions then
      for _, next_state in pairs(rules[current].transitions) do
        if not reachable[next_state] then
          reachable[next_state] = true
          table.insert(queue, next_state)
        end
      end
    end
  end
  
  -- Check for issues
  for state_name, state_def in pairs(rules) do
    
    -- 1. Check for ghost states (undefined transition targets)
    if state_def.transitions then
      for event, target_state in pairs(state_def.transitions) do
        if not defined_states[target_state] then
          print(string.format("⚠️  GHOST STATE: [%s] event '%s' targets undefined state '%s'", 
            state_name, event, target_state))
          warnings = warnings + 1
        end
      end
    end
    
    -- 2. Check for dead ends (no transitions, unless terminal)
    if not state_def.transitions or next(state_def.transitions) == nil then
      if state_name ~= "dead" and state_name ~= "finished" and state_name ~= "end" then
        print(string.format("⚠️  DEAD END: [%s] has no outgoing transitions", state_name))
        warnings = warnings + 1
      end
    end
  end
  
  -- 3. Check for unreachable states
  for state_name in pairs(defined_states) do
    if not reachable[state_name] and state_name ~= initial then
      print(string.format("⚠️  UNREACHABLE: [%s] cannot be reached from initial state '%s'", 
        state_name, initial))
      warnings = warnings + 1
    end
  end
  
  if warnings == 0 then
    print("✓ No issues found!")
  else
    print(string.format("Total warnings: %d\n", warnings))
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

-- Run linter before starting machine
lint(rpg_rules, "idle")
-- Boot up the machine! (Passing the rules, initial state, and payload memory)
local final_memory = machine.start(rpg_rules, "idle", my_payload)

print("\n=== PROCESSING COMPLETE ===")
print("Final Queue Size remaining: " .. #final_memory.queue)
print("Final HP: " .. final_memory.hp)
print_trace(final_memory)
