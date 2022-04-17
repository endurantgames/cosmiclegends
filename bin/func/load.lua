#!/usr/bin/lua

local _G     = _G;
_G.g         = _G.g or {};
local g      = _G.g;
g.FUNC       = g.FUNC or {};
g.CONFIG     = g.CONFIG or {};
g.LOADED     = g.LOADED or {};

package.path = "./bin/func/?.lua;./?.lua;.bin/func/?/load.lua;" .. package.path;
require "util";
require "meta";

local FUNC   = g.FUNC;
local CONFIG = g.CONFIG;
local FUNC   = g.FUNC;
local UTIL   = g.FUNC.util;
local LOADED = g.LOADED;

local vprint, eprint;
if UTIL.eprint then eprint = UTIL.eprint; else  print("Error! Function missing", "eprint"); os.exit(); end;
if UTIL.vprint then vprint = UTIL.vprint; else eprint("Error! Function missing", "vprint"); os.exit(); end;

local function loc_load_funcs(cat) 
  vprint("Requiring: " .. cat); 
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

-- load_funcs( "meta"   );
-- load_funcs( "util"   );
load_funcs( "recipe" );
load_funcs( "bucket" );
load_funcs( "line"   );
load_funcs( "file"   );
load_funcs( "yaml"   );

