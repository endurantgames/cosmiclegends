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

local CONFIG = g.CONFIG;

package.path = "./func/?.lua;./?.lua;./?/load.lua;" .. package.path;
require "meta";
local register_func, register_func_cat;
if FUNC and FUNC.util and FUNC.util.register_category then register_func_cat = FUNC.util.register_category; end;
if FUNC and FUNC.util and FUNC.util.register_func     then register_func     = FUNC.util.register_func;     end;

register_func_cat("util");
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

