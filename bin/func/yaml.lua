
#!/usr/bin/lua

local _G     = _G;
_G.g         = _G.g or {};
local g      = _G.g;
g.FUNC       = g.FUNC or {};
g.CONFIG     = g.CONFIG or {};
local FUNC   = g.FUNC;
local CONFIG = g.CONFIG;
local FUNC   = g.FUNC;
local UTIL   = FUNC.util;
local FILE   = FUNC.file;

print("-------------------------------- file ----------------------------------");
local register_func, register_func_cat;

local ignore, split;
local vprint, eprint, sprint, pprint, yprint;

if FILE.slurp             then slurp             = FILE.slurp              else eprint("Error: no function", "slurp"            ); os.exit(); end;
if UTIL.ignore            then ignore            = UTIL.ignore             else eprint("Error: no function", "ignore"           ); os.exit(); end;
if UTIL.split             then split             = UTIL.split              else eprint("Error: no function", "split"            ); os.exit(); end;
if UTIL.vprint            then vprint            = UTIL.vprint             else eprint("Error: no function", "vprint"           ); os.exit(); end;
if UTIL.eprint            then eprint            = UTIL.eprint             else eprint("Error: no function", "eprint"           ); os.exit(); end;
if UTIL.sprint            then sprint            = UTIL.sprint             else eprint("Error: no function", "sprint"           ); os.exit(); end;
if UTIL.pprint            then pprint            = UTIL.pprint             else eprint("Error: no function", "pprint"           ); os.exit(); end;
if UTIL.yprint            then yprint            = UTIL.yprint             else eprint("Error: no function", "yprint"           ); os.exit(); end;
if UTIL.register_func     then register_func     = UTIL.register_func;     else eprint("Error: no function", "register_func"    ); os.exit(); end;
if UTIL.register_func_cat then register_func_cat = UTIL.register_func_cat; else eprint("Error: no function", "register_func_cat"); os.exit(); end;
register_func_cat("yaml");
local function register_yaml_func(n, ff) register_func("yaml", n, ff); end;

local function register_format(name, func_func, x_format)
  x_format = x_format or name;
  if g.YAML[x_format]
  then eprint("Error: format registered", x_format);
       os.exit();
  end;
  if not func_func
  then eprint("Error: no format to register", x_format);
       os.exit();
  end;
  vprint("Registering x_format", x_format);
  g.YAML[x_format] = func_func;
end;

register_func("util", "register_format", register_format);
register_yaml_func(   "register_format", register_format);

-- == yaml functions ===========================================================
local function yaml_error(yaml_tree, unknown_xformat, filename, return_text)
  yprint("Unknown xformat:", unknown_xformat);
  yprint("> in file:",       filename);
  if return_text or return_text == nil then return "" else return {} end;
end;

local function yaml_common(yaml_tree, slurped)
  local common_error;
  slurped = slurped or "\n\n";
  local flat_tree = unpack_yaml_tree(yaml_tree, "yaml_common") or {};
  local metadata;

  if   flat_tree.metadata
  then metadata     = unpack_yaml_tree(flat_tree.metadata, "yaml_common : metadata") or {};
  else metadata     = nil;
       common_error = true
  end;

  return yaml_tree, metadata, slurped, common_error;
end;

local function slurp_yaml(filename)

  if   not filename
  then eprint("Unknown yaml file location", filename);
       os.exit(1);
  end;

  local yaml_source = slurp(filename, true);

  local yaml_size = yaml_source:len() .. " bytes";

  yprint("Reading YAML file now", filename);

  local yaml_tree, metadata = {}, {};
  local success, xformat;

  if   yaml_source
  then -- yprint("size of yaml_source", yaml_size);
       success = true;
  end;

  if   type(yaml_source) == "string"
  then yaml_tree = lyaml.load(yaml_source);
  else eprint("Couldn't read yaml:", filename);
       success = false;
  end;

  if   not (success and yaml_tree and yaml_tree ~= {})
  then eprint("Couldn't parse yaml:", filename);
       success = false;
       os.exit(1);
  end;

  local flat_tree = unpack_yaml_tree(yaml_tree, "yaml_tree (initial)");

  if   yaml_tree and flat_tree.metadata and type(flat_tree.metadata) == "table"
  then
       metadata = unpack_yaml_tree(flat_tree.metadata, "metadata");
       if   metadata["x-format"]
       then xformat = metadata["x-format"];
       else yprint("metadata has no x-format", ":(");
            os.exit(1);
       end;
  else yprint("YAML tree doesn't have",  "metadata :(");
       success = false;
  end;

  if   not xformat then yprint("metadata has no x-format", ":( :("); return ""; end;

  local parse_func, slurped;

  if   xformat and not g.YAML[xformat]
  then yprint("Unknown x-format:",     xformat);
       parse_func = g.YAML.unknown;
       slurped    = parse_func(yaml_tree);
  else -- yprint("Known x-format:",       xformat);
       -- yprint("Parsing with x-format", "YAML[" .. xformat .. "]");
       parse_func = g.YAML[xformat];
       slurped    = parse_func(flat_tree);
       success    = slurped and slurped ~= "";
  end;

  if   success and slurped
  then return slurped, yaml_tree, metadata;
  else return "",      yaml_tree, metadata;
  end;
end; -- function

register_format(      "error",           yaml_error, "unknown" );
register_yaml_func(   "common",          yaml_common           );
register_yaml_func(   "error",           yaml_error            );
register_yaml_func(   "get_alpha_keys",  get_alpha_keys        );
register_yaml_func(   "get_sorted_keys", get_sorted_keys       );
register_yaml_func(   "unpack_tree",     unpack_tree           );
register_yaml_func(   "slurp",           slurp_yaml            );
register_func("file", "slurp_yaml",      slurp_yaml            );

print("------------------------------- /file ----------------------------------");
