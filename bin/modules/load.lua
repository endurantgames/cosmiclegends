#!/usr/bin/lua

local _G = _G;
local g  = _G.g;

local function load_module(mod)
  print("Requiring: " .. mod);
  require(mod);
end;

package.path = "./?.lua;./bin/modules/?.lua;" .. package.path;

print("package.path is ", package.path);

-- load_module( "util"      );
load_module( "character" );
load_module( "list"      );
load_module( "items"     );
load_module( "sheet"     );

-- require "utils";
-- require "character";
-- require "list";
-- require "list_items";
-- require "sheets";
