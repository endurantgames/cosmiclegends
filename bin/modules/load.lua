#!/usr/bin/lua

local _G = _G;
local g  = _G.g;

local function load_module(mod)
  print("Requiring: " .. mod);
  require(mod);
end;

load_module( "utils"     );
load_module( "character" );
load_module( "list"      );
load_module( "items"     );
load_module( "sheet"     );

-- require "utils";
-- require "character";
-- require "list";
-- require "list_items";
-- require "sheets";
