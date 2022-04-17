#!/usr/bin/lua

local _G     = _G;
_G.g         = _G.g or {};
local g      = _G.g;
g.FUNC       = g.FUNC or {};
g.CONFIG     = g.CONFIG or {};

package.path = "./func/?.lua;./?.lua;./?/load.lua;" .. package.path;

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
  print("Requiring: " .. cat);
  if not LOADED[cat]
  then LOADED[cat] = true;
       require(cat);
  else print("not loading " .. cat .. " twice.");
  end;
end;

local load_funcs;

if not FUNC.load_funcs
then   load_funcs = loc_load_funcs;
       FUNC.load_funcs = loc_load_funcs;
else   load_funcs = FUNC.load_funcs;
end;

load_funcs( "meta" );

local register_func, register_func_cat;

if   FUNC
then print("FUNC ... exists");
else print("ERROR: no FUNC");
     os.exit(1);
end;

if   FUNC and FUNC.util
then print("FUNC.util ... exists");
else print("CRITICAL ERROR: no FUNC.util");
     print(FUNC);
     -- for i, cat in ipairs(FUNC) do print(i, cat) end;
     os.exit(1);
end;

if   FUNC and (FUNC.util or not FUNC.util) and FUNC.util.register_func_cat
then print("FUNC.util.register_func_cat ... exists");
     register_func_cat = FUNC.util.register_func_cat;
else print("CRITICAL ERROR: no FUNC.util.register_func_cat");
     os.exit(1);
end;

register_func_cat("util");

if   FUNC and FUNC.util and FUNC.util.register_func
then print("FUNC.util.register_func ... exists");
     register_func = FUNC.util.register_func;
else print("CRITICAL ERROR: no FUNC.util.register_func_cat");
     os.exit(1);
end;

local function register_util_func(n, ff) register_func("util", n, ff) end;

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

