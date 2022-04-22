#!/usr/bin/lua

local _G     = _G;
_G.g         = _G.g     or {};
local g      = _G.g     or {};
-- g.FUNC       = g.FUNC   or {};
-- g.CONFIG     = g.CONFIG or {};
-- g.LOADED     = g.LOADED or {};
-- local CONFIG = g.CONFIG or {};
-- local FUNC   = g.FUNC;
-- local UTIL   = FUNC.util;
-- local LOADED = g.LOADED or {};
-- package.path = CONFIG.pkg_path;

g.FUNC       = g.FUNC      or {};
g.LOADED     = g.LOADED    or {};
g.CONFIG     = g.CONFIG    or {};
g.FUNC.util  = g.FUNC.util or {};
local LOADED = g.LOADED;

assert(g.FUNC,          "g.FUNC does not exist"          ); local FUNC   = g.FUNC;
assert(g.CONFIG,        "g.CONFIG does not exist"        ); local CONFIG = g.CONFIG;
assert(CONFIG.pkg_path, "CONFIG.pkg_path does not exist" ); package.path = CONFIG.pkg_path;

-- assert(FUNC.util,    "FUNC.util does not exist"       ); local UTIL   = FUNC.util;
print("------------------------------- load.lua ----------------------");

-- == meta (registration) functions ===============================================
--
local function register_cat(name, quiet)
  if quiet == nil then quiet = true; end;
  if                      not name  then print("Can't create FUNC category", name); os.exit();
  elseif g.FUNC[name] and not quiet then print("FUNC category exists",       name); os.exit();
  end;
  -- print("Creating FUNC category", string.upper(name));
  g.FUNC[name] = {}
end;

local function mark_loaded(cat) LOADED[cat] = true; end;

local function load_funcs(cat)
  print("Requiring: " .. cat);
  if not LOADED[cat]
  then   mark_loaded(cat);
         require(cat);
  else   print("not loading " .. cat .. " twice.");
  end;
end;

mark_loaded("meta");

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
  if not func_cat then register_cat(cat); func_cat = FUNC[cat]; end;
  print("Registering " .. string.upper(cat) .. " func", name);
  func_cat[name] = func_func;
end;

register_cat("util");
register_cat("meta");
register_func("meta", "load_funcs",    load_funcs   );
register_func("meta", "register_func", register_func);
register_func("meta", "register_cat",  register_cat );

assert(FUNC.meta,         "FUNC.meta does not exist");         local META         = FUNC.meta;
-- assert(META.register_cat, "META.register_cat does not exist"); local register_cat = META.register_cat;
-- if not FUNC.meta then print("error! no FUNC.meta"); os.exit(); end;
-- if not FUNC.meta.register_cat then print("error! no FUNC.meta.register_cat"); os.exit(); end;

local function dump_function_cats()
  local catlist = {};
  for cat, _ in pairs(FUNC)
  do table.insert(catlist, "FUNC." .. cat);
  end;
  print("CATEGORY LIST: ", table.concat(catlist, "; "));
end;

dump_function_cats();
register_func("meta", "catlist", dump_function_cats);

local function load_funcs(cat) 
  if not LOADED[cat] then LOADED[cat] = true; require(cat); else print("not loading "..cat.." twice."); end;
end;

register_func("meta", "load", load_funcs);

print("--------------------- loading functions ----------------------");

print("loading util funcs"   ); load_funcs( "util"   );
print("loading bucket funcs" ); load_funcs( "bucket" );
print("loading line funcs"   ); load_funcs( "line"   );
print("loading file funcs"   ); load_funcs( "file"   );
print("loading yaml funcs"   ); load_funcs( "yaml"   );
print("loading recipe funcs" ); load_funcs( "recipe" );

print("-------------------- /loading functions ----------------------");

print("------------------------------- /load.lua ---------------------");
