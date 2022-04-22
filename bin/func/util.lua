#!/usr/bin/lua

local _G     = _G          or {};
_G.g         = _G.g        or {};
local g      = _G.g        or {};
g.FUNC       = g.FUNC      or {};
g.CONFIG     = g.CONFIG    or {};
g.LOADED     = g.LOADED    or {};
local CONFIG = g.CONFIG    or {};
local FUNC   = g.FUNC      or {};
local UTIL   = g.FUNC.util or {};


print("------------------------ util ------------------------------");

-- local function fallback_load_funcs(cat)
  -- print("util.lua/55: Requiring: " .. cat);
  -- if   LOADED[cat]
  -- then LOADED[cat] = true;
       -- require(cat);
  -- else print("not loading " .. cat .. " twice.");
  -- end;
-- end;

local load_funcs;

-- if   FUNC and FUNC.meta and FUNC.meta.load_funcs
-- then load_funcs = FUNC.load_funcs;
-- else FUNC.meta = FUNC.meta or {};
     -- load_funcs = fallback_load_funcs;
     -- FUNC.meta.load_funcs = fallback_load_funcs;
-- end;
 
-- load_funcs("meta");
assert(FUNC, "FUNC does not exist");

local register_func, register_cat;

-- if   FUNC
-- then print("FUNC ... exists");
-- else print("ERROR: no FUNC");
     -- os.exit(1);
-- end;
-- 
-- local using_fallback_catlist;

-- local function fallback_dump_function_cats()
  -- local catlist = {};
  -- for cat, _ in pairs(FUNC) do table.insert(catlist, "FUNC." .. cat); end;
  -- print("CATEGORY LIST: ", table.concat(catlist, "; "));
-- end;
-- 
-- local catlist;

-- if   FUNC and FUNC.meta and FUNC.meta.catlist
-- then catlist = FUNC.meta.catlist
-- else catlist = fallback_dump_function_cats;
     -- using_fallback_catlist = true;
-- end;
 
local function dump_function_list(cat)
  cat = cat or "meta";
  local funclist = {};
  if   not FUNC[cat]
  then print("Sorry, can't dump funclist for ", string.upper(cat)); os.exit(1);
  else local CAT = FUNC[cat];
       for f, _ in pairs(CAT) do table.insert(funclist, f .. "()"); end;
       print("FUNC." .. cat .. " FUNCTION LIST: ", table.concat(funclist, "; "));
  end;
end;
  
-- if   FUNC and FUNC.meta
-- then print("FUNC.meta ... exists");
-- else print("CRITICAL ERROR/99: no FUNC.meta");
     -- os.exit(1);
-- end;
 
-- local using_fallback_register_func;
-- local function fallback_register_cat(cat)
  -- cat = cat or "util";
  -- if  not FUNC[cat]
  -- then print("registering FUNC." .. cat .. " = {}");
       -- FUNC[cat] = FUNC[cat] or {};
  -- end;
-- end;
-- 
-- local function fallback_register_func(cat, name, f)
  -- print("registering FUNC." .. cat .. "." .. name);
  -- if using_fallback_register_cat then fallback_register_cat(cat); end;
  -- FUNC[cat][name] = f;
-- end;
-- 
-- if   FUNC and (FUNC.meta or not FUNC.meta) and FUNC.meta.register_cat
-- then print("FUNC.meta.register_cat ... exists");
     -- register_cat = FUNC.meta.register_cat;
-- else print("ERROR/103: no FUNC.meta.register_cat");
     -- register_cat = fallback_register_cat;
     -- using_fallback_register_cat = true;
     -- register_cat("meta"); 
     -- catlist();
-- end;
-- 
assert(g.FUNC, "g.FUNC does not exist");                         local FUNC          = g.FUNC;
assert(FUNC.meta, "FUNC.meta does not exist");                   local META          = FUNC.meta;
assert(META.register_cat,  "META.register_cat does not exist");  local register_cat  = META.register_cat;
assert(META.register_func, "META.register_func does not exist"); local register_func = META.register_func;

register_cat("util");

-- if   FUNC and FUNC.meta and FUNC.meta.register_func
-- then print("FUNC.meta.register_func ... exists");
     -- register_func = FUNC.meta.register_func;
-- else print("ERROR/117: no FUNC.meta.register_func");
     -- print("using fallback_register_func()");
     -- register_func = fallback_register_func;
     -- register_func("meta", "register_func", fallback_register_func);
     -- dump_function_list("meta");
-- end;
-- 
local function register_meta_func(n, ff) register_func("meta", n, ff) end;
local function register_util(n, ff)      register_func("util", n, ff) end;

-- if using_fallback_register_cat then register_meta_func("register_cat", fallback_register_cat); end;
-- if using_fallback_catlist then register_meta_func("catlist", fallback_catlist); end;


-- dump_function_list("meta");
-- == general utilities ===========================================================
local function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s
   do    if s ~= 1 or cap ~= "" then table.insert(t,cap) end
         last_end  = e+1
         s, e, cap = str:find(fpat, last_end)
   end
   if   last_end <= #str then cap = str:sub(last_end) table.insert(t, cap) end
   return t
end

local function vprint(s, l) if CONFIG.verbose   then print(string.format(CONFIG.logfmt, s or "", l or "")); end; end;
local function eprint(s, l) if CONFIG.errors    then print(string.format(CONFIG.logfmt, s or "", l or "")); end; end;
local function sprint(s, l) if CONFIG.summary   then print(string.format(CONFIG.logfmt, s or "", l or "")); end; end;
local function yprint(s, l) if CONFIG.debugyaml then print(string.format(CONFIG.logfmt, s or "", l or "")); end; end;
local function pprint(s, l)                          print(string.format(CONFIG.logfmt, s or "", l or ""));      end;
local function ignore(name) return string.match(name, CONFIG.ignore) and true or false; end;

register_util("eprint", eprint);
register_util("ignore", ignore);
register_util("pprint", pprint);
register_util("split",  split );
register_util("sprint", sprint);
register_util("vprint", vprint);
register_util("yprint", yprint);

dump_function_list("util");

print("----------------------- /util ------------------------------");
