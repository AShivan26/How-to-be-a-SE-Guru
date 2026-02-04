-- fp.lua
-- Part C: First-Class Functions

-- Pretty-print a 1D array-like table: {1,4,9}
local function show(t)
  if t == nil then return "nil" end
  local parts = {}
  for i = 1, #t do
    parts[#parts + 1] = tostring(t[i])
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

-- C1. collect(t, f) — map
local function collect(t, f)
  local out = {}
  for i = 1, #t do
    out[i] = f(t[i])
  end
  return out
end

-- C2. select(t, f) — filter (keep truthy)
local function select(t, f)
  local out = {}
  for i = 1, #t do
    local x = t[i]
    if f(x) then
      out[#out + 1] = x
    end
  end
  return out
end

-- C3. reject(t, f) — filter (keep falsy)
local function reject(t, f)
  local out = {}
  for i = 1, #t do
    local x = t[i]
    if not f(x) then
      out[#out + 1] = x
    end
  end
  return out
end

-- C4. inject(t, acc, f) — fold left
local function inject(t, acc, f)
  local a = acc
  for i = 1, #t do
    a = f(a, t[i])
  end
  return a
end

-- C5. detect(t, f) — first element matching predicate, or nil
local function detect(t, f)
  for i = 1, #t do
    local x = t[i]
    if f(x) then return x end
  end
  return nil
end

-- C6. Python-style range for Lua
-- Semantics:
--   range(stop)                -> 0, 1, ..., stop-1
--   range(start, stop)         -> start, start+1, ..., stop-1
--   range(start, stop, step)   -> start, start+step, ... up to but NOT including stop
-- Works with negative steps too.

local function range(a, b, c)
  local start, stop, step

  if b == nil then
    -- range(stop)
    start, stop, step = 0, a, 1
  else
    -- range(start, stop[, step])
    start, stop, step = a, b, c or 1
  end

  assert(step ~= 0, "range: step cannot be 0")

  -- Iterator state: current value to yield next
  local cur = start

  return function()
    -- Stop conditions (stop is exclusive, like Python)
    if step > 0 then
      if cur >= stop then return nil end
    else
      if cur <= stop then return nil end
    end

    local out = cur
    cur = cur + step
    return out
  end
end

------------------------------------------------------------
-- Tests
------------------------------------------------------------

local t1 = {1, 2, 3}
local squares = collect(t1, function(x) return x * x end)
print("C1 collect squares:", show(squares), " expected {1,4,9}")

local t2 = {1, 2, 3, 4, 5}
local evens = select(t2, function(x) return x % 2 == 0 end)
print("C2 select evens:", show(evens), " expected {2,4}")

local odds = reject(t2, function(x) return x % 2 == 0 end)
print("C3 reject evens (keep odds):", show(odds), " expected {1,3,5}")

local sum = inject({1, 2, 3, 4}, 0, function(a, x) return a + x end)
print("C4 inject sum:", sum, " expected 10")

local prod = inject({1, 2, 3, 4}, 1, function(a, x) return a * x end)
print("C4 inject product:", prod, " expected 24")

local first_gt2 = detect({1, 2, 3, 4}, function(x) return x > 2 end)
print("C5 detect first > 2:", first_gt2, " expected 3")

print("C6 range(5): expected 0 1 2 3 4")
for x in range(5) do io.write(x, " ") end
io.write("\n")

print("range(1, 5): expected 1 2 3 4")
for x in range(1, 5) do io.write(x, " ") end
io.write("\n")

print("range(1, 10, 2): expected 1 3 5 7 9")
for x in range(1, 10, 2) do io.write(x, " ") end
io.write("\n")

print("range(10, 1, -3): expected 10 7 4")
for x in range(10, 1, -3) do io.write(x, " ") end
io.write("\n")

print("range(-2, -8, -2): expected -2 -4 -6")
for x in range(-2, -8, -2) do io.write(x, " ") end
io.write("\n")