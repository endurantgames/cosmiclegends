#!/usr/bin/lua

local _G     = _G;
_G.g         = _G.g or {};
local g      = _G.g;
g.FUNC       = g.FUNC or {};
g.CONFIG     = g.CONFIG or {};
g.LOADED     = g.LOADED or {};

package.path = "./bin/func/?.lua;./?.lua;.bin/func/?/load.lua;" .. package.path;

print("------------------------------- load.lua ----------------------");
local _G = _G;
_G.g     = _G.g or {};
local g  = _G.g;

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

-- package.path = "./func/?.lua;./?.lua;./?/load.lua;" .. package.path;
-- require "util";

g.FUNC     = g.FUNC or {};
local FUNC = g.FUNC;
local UTIL = FUNC.util;
local LOADED = g.LOADED or {};

-- == meta (registration) functions ===============================================
--
local function register_func_cat(name, quiet)
  if quiet == nil then quiet = true; end;
  if                      not name  then print("Can't create FUNC category", name); os.exit();
  elseif g.FUNC[name] and not quiet then print("FUNC category exists",       name); os.exit();
  end;
  print("Creating FUNC category", string.upper(name));
  g.FUNC[name] = {}
end;

local function mark_loaded(cat) LOADED[cat] = true; end;
local function load_funcs(cat)
  print("Requiring: " .. cat);
  if not LOADED[cat]
  then mark_loaded(cat);
       require(cat);
  else print("not loading " .. cat .. " twice.");
  end;
end;

mark_loaded(       "meta"   );
register_func_cat( "bucket" );
register_func_cat( "file"   );
register_func_cat( "line"   );
register_func_cat( "recipe" );
register_func_cat( "util"   );
register_func_cat( "yaml"   );

local function register_format(name, func_func, x_format)
  x_format = x_format or name;
  if g.YAML[x_format]
  then print("Error: format registered", x_format);
       os.exit();
  end;
  if not func_func
  then print("Error: no format to register", x_format);
       os.exit();
  end;
  print("Registering x_format", x_format);
  g.YAML[x_format] = func_func;
end;

local function register_func(cat, name, func_func)
  cat = cat or "util";

  if     not name      then print("Can't register " .. string.upper(cat) .. " func", name); os.exit();
  elseif not func_func then print("No func "        .. string.upper(cat) .. " func", name); os.exit();
  -- elseif FUNC[cat]     then print("112: Already registered " .. string.upper(cat) .. " func category"); 
  end;

  local  func_cat = FUNC[cat];
  if not func_cat 
  then   register_func_cat(cat); 
         func_cat = FUNC[cat]; 
  end;
  print("Registering " .. string.upper(cat) .. " func", name);
  func_cat[name] = func_func;
end;

register_func_cat("util");
register_func_cat("meta");

register_func("meta", "load_funcs",        load_funcs       );
register_func("meta", "register_func",     register_func    );
register_func("meta", "register_func_cat", register_func_cat);

if not FUNC.meta then print("error! no FUNC.meta"); os.exit(); end;
if not FUNC.meta.register_func_cat then print("error! no FUNC.meta.register_func_cat"); os.exit(); end;

--  print("Creating register_*_functions"  ); -- =====================================
--  local function register_bucket_func( n, ff ) register_func( "bucket", n, ff ); end;
--  local function register_file_func(   n, ff ) register_func( "file",   n, ff ); end;
--  local function register_line_func(   n, ff ) register_func( "line",   n, ff ); end;
--  local function register_recipe_func( n, ff ) register_func( "recipe", n, ff ); end;
--  local function register_util_func(   n, ff ) register_func( "util",   n, ff ); end;
--  local function register_yaml_func(   n, ff ) register_func( "yaml",   n, ff ); end;
--  local          register_util               = register_util_func;
 
local function dump_function_cats()
  local catlist = {};
  for cat, _ in pairs(FUNC)
  do table.insert(catlist, "FUNC." .. cat);
  end;
  print("CATEGORY LIST: ", table.concat(catlist, "; "));
end;

dump_function_cats();
register_func("meta", "catlist", dump_function_cats);

local FUNC   = g.FUNC;
local CONFIG = g.CONFIG;
local FUNC   = g.FUNC;
local UTIL   = g.FUNC.util;
local LOADED = g.LOADED;

local function load_funcs(cat) 
  print("load.lua/160: Requiring: " .. cat); 
  if not LOADED[cat]
  then LOADED[cat] = true;
       require(cat);
       os.exit();
  else print("not loading " .. cat .. " twice.");
  end;
end;

-- register_func("meta", "load_funcs", load_funcs);

print("------------------------------- /load.lua ---------------------");
load_funcs( "util"   );
load_funcs( "recipe" );
load_funcs( "bucket" );
load_funcs( "line"   );
load_funcs( "file"   );
load_funcs( "yaml"   );

