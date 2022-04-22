#!/usr/bin/lua

local _G     = _G        or {};
_G.g         = _G.g      or {};
local g      = _G.g      or {};
g.FUNC       = g.FUNC    or {};
g.CONFIG     = g.CONFIG  or {};
g.UTIL       = g.UTIL    or {};
local FUNC   = g.FUNC    or {};
local CONFIG = g.CONFIG  or {};
local FUNC   = g.FUNC    or {};
local UTIL   = FUNC.util or {};

print("-------------------------------- recipe ------------------------------");

local register_func, register_cat;

local ignore, split;
local vprint, eprint, sprint, pprint, yprint;

local function fallback_eprint(txt, more)
  print(txt, more);
end;

if   UTIL.eprint 
then eprint = UTIL.eprint 
else eprint = fallback_eprint;
     eprint("ERROR: no function", "eprint");
end;

assert(UTIL.ignore, "no UTIL.ignore"); ignore = UTIL.ignore;
assert(UTIL.split,  "no UTIL.split");  split  = UTIL.split;
assert(UTIL.vprint, "no UTIL.vprint"); vprint = UTIL.vprint;
assert(UTIL.pprint, "no UTIL.pprint"); pprint = UTIL.pprint;
assert(UTIL.sprint, "no UTIL.sprint"); sprint = UTIL.sprint;
assert(UTIL.yprint, "no UTIL.yprint"); yprint = UTIL.yprint;

-- if UTIL.ignore then ignore = UTIL.ignore else eprint("Error: no function", "ignore" ); end;
-- if UTIL.split  then split  = UTIL.split  else eprint("Error: no function", "split"  ); end;
-- if UTIL.vprint then vprint = UTIL.vprint else eprint("Error: no function", "vprint" ); end;
-- if UTIL.sprint then sprint = UTIL.sprint else eprint("Error: no function", "sprint" ); end;
-- if UTIL.pprint then pprint = UTIL.pprint else eprint("Error: no function", "pprint" ); end;
-- if UTIL.yprint then yprint = UTIL.yprint else eprint("Error: no function", "yprint" ); end;

assert(FUNC,                    "FUNC not exist"                   );
assert(FUNC.meta,               "FUNC.meta not exist"              );
assert(FUNC.meta.register_cat,  "FUNC.meta.register_cat not exist" );
assert(FUNC.meta.register_func, "FUNC.meta.register_cat not exist" );

register_cat  = FUNC.meta.register_cat;
register_func = FUNC.meta.register_func;

-- if   FUNC and FUNC.meta and FUNC.meta.register_cat
-- then register_cat = FUNC.meta.register_cat; 
-- else eprint("FATAL Error: no function", "FUNC.meta.register_cat"); 
--      os.exit(1); -- can't continue without ability to register categories
-- end; 
-- 
-- if FUNC and FUNC.meta and FUNC.meta.register_func     
-- then register_func     = UTIL.register_func;          
-- else eprint("FATAL Error: no function", "FUNC.meta.register_func"    ); 
--      os.exit(1); -- can't continue without ability to register funcs
-- end; 

register_cat("recipe");

local function register_recipe_func(n, ff) register_func("recipe", n, ff); end;

vprint("Loading bucket functions");

assert(FUNC,         "FUNC does not exist");
-- assert(FUNC.util, "FUNC.util does not exist");
assert(FUNC.bucket,  "FUNC.bucket does not exist");

local BUCKET = FUNC and -- FUNC.util 
               FUNC.bucket or {};

assert(BUCKET, "BUCKET does not exist");

local bucket_exists, bucket_count, bucket_contents, bucket_dump, bucket_fetch, bucket_test, bucket_add;

assert(BUCKET.exists, "BUCKET.exists"     ); bucket_exists   = BUCKET.exists;
assert(BUCKET.add, "BUCKET.add"           ); bucket_add      = BUCKET.add;
assert(BUCKET.test, "BUCKET.test"         ); bucket_test     = BUCKET.test;
assert(BUCKET.fetch, "BUCKET.fetch"       ); bucket_fetch    = BUCKET.fetch;
assert(BUCKET.dump, "BUCKET.dump"         ); bucket_dump     = BUCKET.dump;
assert(BUCKET.count, "BUCKET.count"       ); bucket_count    = BUCKET.count;
assert(BUCKET.contents, "BUCKET.contents" ); bucket_contents = BUCKET.contents;

-- if BUCKET.exists   then bucket_exists   = BUCKET.exists   else eprint("Error: no function", "bucket_exists"  ); os.exit(); end;
-- if BUCKET.add      then bucket_add      = BUCKET.add      else eprint("Error: no function", "bucket_add"     ); os.exit(); end;
-- if BUCKET.test     then bucket_test     = BUCKET.test     else eprint("Error: no function", "bucket_test"    ); os.exit(); end;
-- if BUCKET.fetch    then bucket_fetch    = BUCKET.fetch    else eprint("Error: no function", "bucket_fetch"   ); os.exit(); end;
-- if BUCKET.dump     then bucket_dump     = BUCKET.dump     else eprint("Error: no function", "bucket_dump"    ); os.exit(); end;
-- if BUCKET.count    then bucket_count    = BUCKET.count    else eprint("Error: no function", "bucket_count"   ); os.exit(); end;
-- if BUCKET.contents then bucket_contents = BUCKET.contents else eprint("Error: no function", "bucket_contents"); os.exit(); end;

-- local function iprint(s, data) print(string.format, s or "", inspect(data)); end;
-- http://lua-users.org/wiki/FileInputOutput

-- == recipe functions ========================================================
local function recipe_list()
  local files, _ = file_search(CONFIG.dir.recipe, CONFIG.ext.recipe, false)
  sprint("Listing Recipes:", #files .. " known");
  sprint("Recipe directory", CONFIG.dir.recipe);
  print(string.format(CONFIG.lsfmt, "Filename",          "Command Line"      ));
  print(string.format(CONFIG.lsfmt, string.rep("-", 30), string.rep("-", 25) ));
    for k, v in pairs(files)
  do  print(
        string.format(
          CONFIG.lsfmt,
          v.path .. v.name,
          CONFIG.dir.bin   ..
            "/"              ..
            CONFIG.appname ..
            " "              ..
            string.gsub(v.name, CONFIG.ext.recipe, "")
        )
      );
  end;
  os.exit(0);
end;

local function parse_recipe_line(line)
  local found = {
          comment  = false, dir      = false,
          ext_md   = false, ext_yaml = false,
          asterisk = false
        };
  local tests = {
          comment  = "^%# ", dir      = "/$",
          ext_md   = "%" .. CONFIG.ext.markdown .. "$",
          ext_yaml = "%" .. CONFIG.ext.yaml     .. "$",
          asterisk = "/%*$"
        };
  for field, test in pairs(tests)
  do  found[field] = false;
      found[field] = string.find(line, test);
  end;
  local was_found, found_filename, found_type = find_file(line);

  if   was_found 
  then found.nothing = false; found.something = true; line = found_filename;
  else found.nothing = true;  found.something = false;
  end;

  if     was_used_line(line)
  then   vprint("skipping used entry", line)
  elseif found.comment
  then   mark_line_used(line);
  elseif found.dir and bucket_test("dirs", line) -- g.bucket.DIRS[line]
  then   eprint("found a directory", line);
         eprint("looking for index", line .. "/" .. CONFIG.intro);
         parse_recipe_line(line .. "/" .. CONFIG.intro);
  elseif found.asterisk
  then   local dir = string.gsub(line, "/%*$", "");

         local found_files, _ =
                 file_search(
                   CONFIG.dir.source .. "/" .. dir,
                   CONFIG.ext.filter
                 );
         for _, v in pairs(found_files)
         do  local ff;
		   ff = string.gsub(v.name, "%"..CONFIG.ext["filter"  ].."$", "");
                   ff = string.gsub(ff,          CONFIG.ext["markdown"].."$", "");
                   ff = string.gsub(ff,          CONFIG.ext["yaml"    ].."$", "");
             parse_recipe_line(        dir.."/"..ff);
         end; -- for
  elseif bucket_fetch("files", line) -- g.bucket.FILES[line]
  then   local  filedata = bucket_fetch("files", line); -- g.bucket.FILES[line];
         if     filedata.ext == CONFIG.ext.yaml
         then   local  yaml_file = CONFIG.dir.source.."/"..line..CONFIG.ext.yaml;
                if   file_exists(yaml_file)
                then bucket_add("build", yaml_file);
                     mark_line_used(line);
                end;
         elseif filedata.ext == CONFIG.ext.markdown
         then   local md_file = CONFIG.dir.source .. "/" .. line .. CONFIG.ext.markdown;
                if file_exists(md_file)
                then bucket_add("build", md_file);
                     mark_line_used(line);
                end;
         else   eprint("failed to find:", line);
                eprint("> failed to find:", line .. CONFIG.ext.yaml);
                eprint("> failed to find:", line .. CONFIG.ext.markdown);
         end;
  elseif found.nothing
  then   bucket_add("err", line);
  end;
end;

register_recipe_func( "list",         recipe_list       );
register_recipe_func( "parse_line",   parse_recipe_line );
register_func("line", "parse_recipe", parse_recipe_line );

print("------------------------------- /recipe ------------------------------");
