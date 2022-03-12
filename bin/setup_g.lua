#!/usr/bin/lua

local _G = _G;

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
