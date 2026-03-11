local M = {}

local function run(rules, s, p)
  if rules[s] and rules[s].action then rules[s].action(p) end
  local e = table.remove(p.queue, 1)
  if not e then return p end
  
  local transitions = (rules[s] and rules[s].transitions) or {}
  --Q4 Fall back is this line
  local step = transitions[e] or transitions["*"]

  -- guard transition support
  local next_state
  if type(step) == "function" then
      next_state = step(p) or s
  else
      next_state = step or s
  end
  -- Record transition BEFORE tail call (doesn't break TCO)
  if not p.trace then p.trace = {} end
  table.insert(p.trace, string.format("[%s] %s -> %s", e, s, next_state))
  
  return run(rules, next_state, p)
end

function M.start(rules, s, p) return run(rules, s, p) end

return M
