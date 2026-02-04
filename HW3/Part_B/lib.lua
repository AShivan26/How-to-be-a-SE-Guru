#!/usr/bin/env lua
local help = [[
lib.lua: general utilities
(c) 2026, Tim Menzies, MIT license.

USAGE
   lua lib.lua [OPTIONS]

EXAMPLES
    -h          Show help.
    --order     Test sorted key iteration.
    --iter      Test iterator over tables and functions.
    --csv F     Print rows from CSV file.

--------------------------------------------------------------------
CODING STANDARD

  Type Hints (single letter)
    i:instance t:table u:output_table r:row n:number 
    s:string v:value k:key f:function d:delta j:index items:iterator

  Multiple Same-Type Params
    Base + suffix: nall, nh, n1, n2

  Class System
    UPPERCASE:metatable (SYM,NUM)  CamelCase:constructor (Sym,Num)
    lowercase:instance (data,col)

  Collision Avoidance
    file (not f, since f is function)

  Function Signatures
    Params before extra spaces; locals after:
      function sum(t,f,    n)   -- t,f:params; n:local 

--------------------------------------------------------------------
API
  ITERATION
    lib.iter(items)          -- iterator over tables or functions
    lib.order(t)             -- sorted key iteration

  FUNCTIONAL
    n = lib.sum(t,f)         -- sum f(v) over t
    u = lib.kap(t,f)         -- map t by f(k,v)
    u = lib.sel(t,f)         -- filter t by f(v)
    k = lib.most(t,f)        -- key where f(k,v) is max

  CONVERSION
    v = lib.cast(s)          -- string to int/float/trimmed string
    t = lib.casts(s)         -- comma-separated string to table

  IO
    lib.csv(file)            -- iterator over CSV rows
    s = lib.o(t)             -- pretty print
]]
local int = math.tointeger
local fmt = string.format
local BIG = 1E32

-- iteration ------------------------------------------------------
local function iter(t,    more,state,key)
  if type(t)=="function" then return t end
  more,state,key = pairs(t)
  return function(v) key,v = more(state,key); return v end end

local function order(t,     u,j)
  if #t>0 then return ipairs(t) end
  u,j = {},0
  for k in pairs(t) do u[#u+1]=k end; table.sort(u)
  return function()j=j+1; if u[j] then return u[j],t[u[j]] end end end

-- meta -----------------------------------------------------------
local function isa(mt,t) mt.__index=mt; return setmetatable(t,mt) end

-- conversion -----------------------------------------------------
local function cast(s) 
  return int(s) or tonumber(s) or s:match"^%s*(.-)%s*$" end

local function casts(s,    t)
  t={}; for x in s:gmatch"[^,]+" do t[1+#t]=cast(x) end; return t end

-- functional -----------------------------------------------------
local function sum(t,f,   n) 
  n=0; for _,v in pairs(t) do n=n+f(v) end
  return n end

local function kap(t,f,   u) 
  u={}; for k,v in pairs(t) do u[1+#u]=f(k,v) end
  return u end

local function sel(t,f,  u) 
  u={}; for _,v in pairs(t) do if f(v) then u[1+#u]=v end end
  return u end

local function most(t,f,   n,out,tmp)
  n = -BIG; for k,v in pairs(t) do
    tmp = f(k,v); if tmp and tmp > n then n,out = tmp,k end end
  return out end

-- io -------------------------------------------------------------
local function csv(file,    src)
  src = assert(io.open(file))
  return function(s)
    s=src:read()
    if s then return casts(s) else src:close() end end end

local function o(t,     u,mt)
  if math.type(t)=="float" then return fmt("%.2f",t) end
  if type(t)~="table" then return tostring(t) end
  mt=getmetatable(t); u={}
  for k,v in order(t) do 
    u[1+#u]=#t>0 and o(v) or fmt(":%s %s",k,o(v)) end
  return (mt and mt._is or "").."{"..table.concat(u," ").."}" end

-- demos ----------------------------------------------------------
local eg={}

eg["-h"]= function(_) print("\n"..help) end

eg["--order"]= function(_) 
  for k,v in order({z=1,a=2,m=3}) do print(k,v) end end

eg["--iter"]= function(_,    t,f)
  t={}; for x in iter({2,4,8}) do t[1+#t]=x end; print(o(t))
  t={}; f=function(n,   j) j=0; 
            return function() j=j+1
                              if j<=n then return j*10 end end end
  for x in iter(f(8)) do t[1+#t]=x end; print(o(t)) end

eg["--csv"]= function(f) for row in csv(f) do print(o(row)) end end

-- main ----------------------------------------------------------
if arg[0] and arg[0]:find"lib" then
  for j,s in pairs(arg) do if eg[s] then eg[s](arg[j+1]) end end end

return {BIG=BIG, iter=iter, order=order, sum=sum, kap=kap, sel=sel, 
        most=most, cast=cast, casts=casts, csv=csv, isa=isa, o=o, 
        run=run, eg=eg}
