#!/usr/bin/env lua
local help = [[
nb.lua: naive bayes classifier
(c) 2026, Tim Menzies, MIT license.

USAGE
   lua nb.lua [OPTIONS] [FILE]

DESCRIPTION
    Incremental bayes. Training and testing are interleaved: after
    burn-in, each row is classified then added to the training set.

OPTIONS
    -h          Show help.
    -k k=1      Bayes low frequency hack for symbolic attributes.
    -m m=2      Bayes low frequency hack for class priors.
    -w wait=5   Start classifying after seeing "some" rows.

EXAMPLES
    --the       Print config settings.
    --sym       Test symbolic column.
    --num       Test numeric column.
    --col       Test column creation.
    --cols      Test column set creation.
    --data F    Load data, print first y column.
    --like      Test likelihood calculations.
    --likes F   Test row likelihood.
    --nb F      Run naive bayes on CSV file.

INPUT FORMAT
    Comma-separated values. First row defines column names. Uppercase
    names (Age, Weight) are numeric; lowercase (name) are symbolic.
    Suffixes: "!" class label, "X" ignore. Missing values: "?". 

----------------------------------------------------------------------
CODING STANDARD

  Type Hints (single letter)
    i:instance t:table u:output_table r:row n:number p:probability
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
]]
local l = require"lib"
local o,isa,iter,csv,sel,BIG = l.o,l.isa,l.iter,l.csv,l.sel,l.BIG
local sqrt,exp,log,max = math.sqrt,math.exp,math.log,math.max
local the = {}

-- tyoes -----------------------------------------------------------
local DATA,COLS,SYM = {_is="DATA"}, {_is="COLS"}, {_is="SYM"}
local NUM = {_is="NUM"}
local Data,Cols,Sym,Num,Col

local function Sym(n,s) 
  return isa(SYM,{at=n or 0, txt=s or "", n=0, has={}}) end

local function Num(n,s) 
  return isa(NUM,{at=n or 0, txt=s or "", n=0, mu=0, m2=0, sd=0}) end

function Col(n,s) return (s:find"^[A-Z]" and Num or Sym)(n,s) end

local function adds(items,t)
  t=t or Num();for v in iter(items or {})do t:add(v) end; return t end

function Data(s,items)
  return adds(items or {},isa(DATA,{txt=s or "",rows={},cols=nil}))end

function Cols(row,    all)
  all = l.kap(row, Col)
  return isa(COLS, {names=row, all=all,
    x = sel(all, function(c) return not c.txt:find"[!X]$" end),
    y = sel(all, function(c) return c.txt:find"!$" end)}) end

function clone(data,rows) 
  return adds(rows, Data(data.txt, {data.cols.names})) end

-- add -----------------------------------------------------------
function DATA.add(i,row)
  if not i.cols then i.cols=Cols(row) else
    i.rows[1+#i.rows] = row
    for _,col in pairs(i.cols.all) do col:add(row[col.at]) end end end

function SYM.add(i,v)
  if v~="?" then i.n=i.n+1; i.has[v]=1+(i.has[v] or 0) end end

function NUM.add(i,v,    d)
  if v~="?" then
    i.n=i.n+1; d=v-i.mu; i.mu=i.mu+d/i.n; i.m2=i.m2+d*(v-i.mu)
    i.sd = i.n<2 and 0 or sqrt(i.m2/(i.n-1)) end end

-- bayes ------------------------------------------------------------
function SYM.like(i,v,prior,    n)
  n = (i.has[v] or 0) + the.k*(prior or 0)
  return max(1/BIG, n/(i.n + the.k + 1/BIG)) end

function NUM.like(i,v,    z,var)
  z=1/BIG; var=i.sd^2 + z
  return (1/sqrt(2*math.pi*var)) * exp(-((v - i.mu)^2)/(2*var)) end

function DATA.likes(i,row,nall,nh,    b4)
  b4 = (#i.rows + the.m)/(nall + the.m*nh)
  return log(b4) + l.sum(i.cols.x, function(c)
    return row[c.at]~="?" and log(c:like(row[c.at],b4)) or 0 end) end

local function nb(items,   all,klasses,n,nk,klass,train,seen,classify)
  klasses, n, nk = {}, 0, 0
  function klass(row) return row[all.cols.y[1].at] end
  function train(row) klasses[klass(row)]:add(row) end
  function seen(k)
    if not klasses[k] then 
      nk=nk+1; klasses[k]=clone(all); klasses[k].txt=k end end
  function classify(row)
    return l.most(klasses,function(_,d)return d:likes(row,n,nk)end)end

  for row in iter(items) do
    if not all then all=Data("all",{row}) else
      seen(klass(row))
      if n > the.wait then print(classify(row), klass(row)) end
      n=n+1; train(row) end end end

-- demos ------------------------------------------------------------
local eg={}

eg["-h"]   = function(_) print("\n"..help) end
eg["--the"]= function(_) print(o(the)) end
eg["--sym"]= function(_) print(o(adds({"a","a","a","b","c"},Sym())))end
eg["--num"]= function(_) print(o(adds({10,20,30,40}))) end
eg["--col"]= function(_) print(o(Col(1,"Age")), o(Col(2,"name"))) end

eg["--cols"]= function(_) 
   print(o(Cols({"Name","Age","Weight-","Class!"}).y)) end

eg["--data"]= function(f) print(o(Data("",csv(f)).cols.y[1])) end

eg["--like"]= function(_,    num,sym)
  num=adds({10,20,30,40,50}); sym=adds({"a","a","a","b","c"},Sym())
  print(num:like(30), sym:like("a",0.5)) end

eg["--likes"]= function(f,    data)
  data=Data("",csv(f));print(data:likes(data.rows[1],#data.rows,2))end

eg["--nb"]= function(f) nb(csv(f)) end

-- main ------------------------------------------------------------
for k,v in help:gmatch("(%S+)=(%S+)") do the[k]=l.cast(v) end
if arg[0] and arg[0]:find"nb" then
  for j,s in pairs(arg) do if eg[s] then eg[s](arg[j+1]) end end end

return {the=the, SYM=SYM, NUM=NUM, DATA=DATA, COLS=COLS, 
        Sym=Sym, Num=Num, Data=Data, Cols=Cols, Col=Col, adds=adds,
        clone=clone, nb=nb, eg=eg}
