#!/usr/bin/lua

local _G     = _G;
_G.g         = _G.g or {};
local g      = _G.g;
g.FUNC       = g.FUNC or {};
g.CONFIG     = g.CONFIG or {};

package.path = "./func/?.lua;./?.lua;./?/load.lua;" .. package.path;

print("------------------------ util ------------------------------");
_G.g = { -- g for "global"   g = _G.g
  FILES  = { }, YAML = { },
  bucket = { BUILD   = { }, CONTENT = { },
             DIRS    = { }, ERR  = { },
             FILES   = { } },
  count  = { BUILD   = 0,   DIRS   = 0,
             ERR     = 0,   FILES  = 0, },
  outtxt = { },
};

    g.FUNC = { }; -- functions
local FUNC = g.FUNC;
local UTIL = FUNC.util;

g.CONFIG         = {
  recipe         = "clu", -- specific to this project
  appname        = "make-markdown.lua",
  dir            = { bin          = "./bin", build  = "./build",
                     out          = "./out", recipe = "./recipes",
                     source       = "./src", },
  errors         = true,
  ext            = { filter       = ".md;.yaml",
                     markdown     = ".md",  out    = ".md",
                     recipe       = ".rec", source = "(.md|%.yaml)",
                     yaml         = ".yaml", },
  ignore         = "(%.git|Makefile|%.test|%.|backup|markdown)",
  intro          = "intro",
  lsfmt          = "  %-30s %-20s",
  logfmt         = "  %-30s %-20s",
  maxerrors      = 2,
  outfile        = "build",
  src_in_comment = true,
  summary        = true,
  verbose        = true,
  yaml_ignore    = "^(metadata|flat|%d+)"
};

local CONFIG = g.CONFIG or {};
local LOADED = g.LOADED or {};

package.path = "./bin/func/?.lua;./bin/func/?.lua;.bin/func/?/load.lua;" .. package.path;

local function loc_load_funcs(cat)
  print("util.lua/55: Requiring: " .. cat);
  if   LOADED[cat]
  then LOADED[cat] = true;
       require(cat);
  else print("not loading " .. cat .. " twice.");
  end;
end;

local load_funcs;

if   FUNC and FUNC.meta and FUNC.meta.load_funcs
then load_funcs = FUNC.load_funcs;
else FUNC.meta = FUNC.meta or {};
     load_funcs = loc_load_funcs;
     FUNC.meta.load_funcs = loc_load_funcs;
end;

-- load_funcs("meta");
local register_func, register_func_cat;

if   FUNC
then print("FUNC ... exists");
else print("ERROR: no FUNC");
     os.exit(1);
end;

local function dump_function_cats()
  local catlist = {};
  for cat, _ in pairs(FUNC) do table.insert(catlist, "FUNC." .. cat); end;
  print("CATEGORY LIST: ", table.concat(catlist, "; "));
end;

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
  
if   FUNC and FUNC.meta
then print("FUNC.meta ... exists");
else print("CRITICAL ERROR/99: no FUNC.meta");
     os.exit(1);
end;

if   FUNC and (FUNC.meta or not FUNC.meta) and FUNC.meta.register_func_cat
then print("FUNC.meta.register_func_cat ... exists");
     register_func_cat = FUNC.meta.register_func_cat;
else print("ERROR/107: no FUNC.meta.register_func_cat");
     register_func_cat = 
       function(cat)
         cat = cat or "util";
	 FUNC[cat] = FUNC[cat] or {};
       end;
     dump_function_list();
end;

register_func_cat("util");

if   FUNC and FUNC.meta and FUNC.meta.register_func
then print("FUNC.meta.register_func ... exists");
     register_func = FUNC.meta.register_func;
else print("ERROR/121: no FUNC.meta.register_func");
     register_func =
       function(cat, name, f)
         register_func_cat(cat);
         FUNC[cat][name] = f;
       end;
     dump_function_list();
end;

local function register_util_func(n, ff) register_func("util", n, ff) end;

dump_function_list("meta");
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

local function vprint(s, l) if CONFIG.verbose   then print(string.format(CONFIG.logfmt, s or "", l or "")) end; end;
local function eprint(s, l) if CONFIG.errors    then print(string.format(CONFIG.logfmt, s or "", l or "")) end; end;
local function sprint(s, l) if CONFIG.summary   then print(string.format(CONFIG.logfmt, s or "", l or "")) end; end;
local function yprint(s, l) if CONFIG.debugyaml then print(string.format(CONFIG.logfmt, s or "", l or "")) end; end;
local function pprint(s, l) print(string.format(CONFIG.logfmt, s or "", l or "")); end;
local function ignore(name) return string.match(name, CONFIG.ignore) and true or false; end;

register_util_func("eprint", eprint);
register_util_func("ignore", ignore);
register_util_func("pprint", pprint);
register_util_func("split",  split );
register_util_func("sprint", sprint);
register_util_func("vprint", vprint);
register_util_func("yprint", yprint);

print("----------------------- /util ------------------------------");
