#!/usr/bin/lua

local _G     = _G        or {};
_G.g         = _G.g      or {};
local g      = _G.g      or {};
g.FUNC       = g.FUNC    or {};
g.CONFIG     = g.CONFIG  or {};
g.UTIL       = g.UTIL    or {};
assert(g.FUNC,    "g.FUNC missing");    local FUNC   = g.FUNC    or {};
assert(g.CONFIG,  "g.CONFIG missing");  local CONFIG = g.CONFIG  or {};
assert(g.FUNC,    "g.FUNC missing");    local FUNC   = g.FUNC    or {};
assert(FUNC.util, "FUNC.util missing"); local UTIL   = FUNC.util or {};

print("-------------------------------- recipe ------------------------------");

local register_func, register_cat, ignore, split, vprint, eprint, sprint, pprint, yprint;

assert(FUNC.meta,               "FUNC.meta missing"              );
assert(FUNC.meta.register_func, "FUNC.meta.register_func missing"); register_func = FUNC.meta.register_func;
assert(FUNC.meta.register_cat,  "FUNC.meta.register_cat missing" ); register_cat  = FUNC.meta.register_cat;

assert(UTIL.ignore, "UTIL.ignore missing"); ignore = UTIL.ignore;
assert(UTIL.split, "UTIL.split missing"); split = UTIL.split;
assert(UTIL.eprint, "UTIL.eprint missing"); eprint = UTIL.eprint;
assert(UTIL.vprint, "UTIL.vprint missing"); vprint = UTIL.vprint;
assert(UTIL.eprint, "UTIL.eprint missing"); eprint = UTIL.eprint;
assert(UTIL.sprint, "UTIL.sprint missing"); sprint = UTIL.sprint;
assert(UTIL.pprint, "UTIL.pprint missing"); pprint = UTIL.pprint;
assert(UTIL.pprint, "UTIL.pprint missing"); pprint = UTIL.pprint;

-- local function fallback_eprint(txt, more)
  -- print(txt, more);
-- end;
-- if   UTIL.eprint 
-- then eprint = UTIL.eprint 
-- else eprint = fallback_eprint;
     -- eprint("ERROR: no function", "eprint");
-- end;
 
-- if UTIL.ignore                                        then ignore            = UTIL.ignore                  else eprint("Error: no function", "ignore"           ); end;
-- if UTIL.split                                         then split             = UTIL.split                   else eprint("Error: no function", "split"            ); end;
-- if UTIL.vprint                                        then vprint            = UTIL.vprint                  else eprint("Error: no function", "vprint"           ); end;
-- if UTIL.sprint                                        then sprint            = UTIL.sprint                  else eprint("Error: no function", "sprint"           ); end;
-- if UTIL.pprint                                        then pprint            = UTIL.pprint                  else eprint("Error: no function", "pprint"           ); end;
-- if UTIL.yprint                                        then yprint            = UTIL.yprint                  else eprint("Error: no function", "yprint"           ); end;
 
-- if   FUNC and FUNC.meta and FUNC.meta.register_cat 
-- then register_cat = FUNC.meta.register_cat; 
-- else eprint("FATAL Error: no function", "FUNC.meta.register_cat"); 
     -- os.exit(1); -- can't continue without ability to register categories
-- end; 
-- if FUNC and FUNC.meta and FUNC.meta.register_func     
-- then register_func     = UTIL.register_func;          
-- else eprint("FATAL Error: no function", "FUNC.meta.register_func"    ); 
     -- os.exit(1); -- can't continue without ability to register funcs
-- end; 
 
register_cat("yaml");
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

local function get_alpha_keys(t)
  local n = 0;
  local keys = {};
  for k, v in pairs(t)
  do  n       = n + 1;
      if   type(k) == "string"
      then keys[n]     = k;
           table.insert(keys, k);
      end;
  end;
  return keys;
end;

local function get_sorted_keys(table_of_tables, sort_field, numeric)
  local alpha;
  local t         = unpack_yaml_tree(table_of_tables);
  local keys      = {};
  local sortkeys  = {};
  local storekeys = {};
  local n         = 0;
  local helper    = function(a, b) return a < b end;

  if   type(sort_field) == "string" and numeric
  then sort_field = string.lower(sort_field);
       alpha = false;
  end;

  if   sort_field == nil
   or  sort_field == true
   or  sort_field == "alpha"
   or  sort_field == "alphabetical"
   or  sort_field == "a-z"
  then sort_field =  "key";
       alpha      =  true;
       numeric    =  false;
  end;

  if   not numeric and not alpha
  then   eprint("sorry, don't know what kind of sort", "");
         eprint("numeric is", numeric);
         eprint("alpha is",   alpha  );
         os.exit(1);
  elseif alpha
  then   helper = function(a, b)
		    a = string.lower(a:gsub("^The ", ""));
		    b = string.lower(b:gsub("^The ", ""));
                    return a < b
                  end;
  end;

  for k, v in pairs(t)
  do  if   type(k) == "string"
      then n            = n + 1;
           local  key_to_store = k;
           local  key_index;
           if     alpha
           then   key_index = k;
           elseif type(v)     == "table"
           then   local up_v  =  unpack_yaml_tree(v);
                  key_index = up_v[sort_field];
           else   key_index = 1;
           end;
           storekeys[key_index] = key_to_store;
           table.insert(sortkeys, key_index);
      end;
  end;

  table.sort(sortkeys, helper);

  n   = 0;
  for k, _ in pairs(sortkeys)
  do  n = n + 1;
      local key_to_retrieve = sortkeys[n];
      local retrieved_key   = storekeys[key_to_retrieve];
      -- yprint(n .. ": storekeys[" .. key_to_retrieve .. "]", retrieved_key);
      table.insert(keys, retrieved_key);
  end;

  return keys;

end;

local function yaml_error(yaml_tree, unknown_xformat, filename, return_text)
  yprint("Unknown xformat:", unknown_xformat);
  yprint("> in file:",       filename       );
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

register_format(      "error",           yaml_error, "unknown" );
register_yaml_func(   "common",          yaml_common           );
register_yaml_func(   "error",           yaml_error            );
register_yaml_func(   "get_alpha_keys",  get_alpha_keys        );
register_yaml_func(   "get_sorted_keys", get_sorted_keys       );
register_yaml_func(   "unpack_tree",     unpack_yaml_tree      );
register_yaml_func(   "slurp",           slurp_yaml            );
register_func("file", "slurp_yaml",      slurp_yaml            );

print("------------------------------- /yaml ----------------------------------");
