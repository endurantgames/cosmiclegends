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
package.path = "./?.lua;./?/load.lua;" .. package.path;

local register_func, register_func_cat;

local ignore, split;
local vprint, eprint, sprint, pprint, yprint;

if UTIL.ignore            then ignore            = UTIL.ignore             else eprint("Error: no function", "ignore"           ); os.exit(); end;
if UTIL.split             then split             = UTIL.split              else eprint("Error: no function", "split"            ); os.exit(); end;
if UTIL.vprint            then vprint            = UTIL.vprint             else eprint("Error: no function", "vprint"           ); os.exit(); end;
if UTIL.eprint            then eprint            = UTIL.eprint             else eprint("Error: no function", "eprint"           ); os.exit(); end;
if UTIL.sprint            then sprint            = UTIL.sprint             else eprint("Error: no function", "sprint"           ); os.exit(); end;
if UTIL.pprint            then pprint            = UTIL.pprint             else eprint("Error: no function", "pprint"           ); os.exit(); end;
if UTIL.yprint            then yprint            = UTIL.yprint             else eprint("Error: no function", "yprint"           ); os.exit(); end;
if UTIL.register_func     then register_func     = UTIL.register_func;     else eprint("Error: no function", "register_func"    ); os.exit(); end;
if UTIL.register_func_cat then register_func_cat = UTIL.register_func_cat; else eprint("Error: no function", "register_func_cat"); os.exit(); end;
register_func_cat("recipe");
local function register_recipe_func(n, ff) register_func("recipe", n, ff); end;

vprint("Loading bucket functions");
local BUCKET = UTIL.bucket or {};

local bucket_exists, bucket_count, bucket_contents, bucket_dump, bucket_fetch, bucket_test, bucket_add;

if BUCKET.exists   then bucket_exists   = BUCKET.exists   else eprint("Error: no function", "bucket_exists"    ); os_exit(); end;
if BUCKET.add      then bucket_add      = BUCKET.add      else eprint("Error: no function", "bucket_add"       ); os_exit(); end;
if BUCKET.test     then bucket_test     = BUCKET.test     else eprint("Error: no function", "bucket_test"      ); os_exit(); end;
if BUCKET.fetch    then bucket_fetch    = BUCKET.fetch    else eprint("Error: no function", "bucket_fetch"     ); os_exit(); end;
if BUCKET.dump     then bucket_dump     = BUCKET.dump     else eprint("Error: no function", "bucket_dump"      ); os_exit(); end;
if BUCKET.count    then bucket_count    = BUCKET.count    else eprint("Error: no function", "bucket_count"     ); os_exit(); end;
if BUCKET.contents then bucket_contents = BUCKET.contents else eprint("Error: no function", "bucket_contents"  ); os_exit(); end;

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
  then   -- eprint("couldn't find", "line = " .. inspect(line));
         -- eprint("or markdown",   line .. CONFIG.ext.markdown);
         -- eprint("or yaml",       line .. CONFIG.ext.yaml);
         -- eprint("dump of g.FILES", inspect(g.FILES));
        bucket_add("err", line);
  end;
end;

register_recipe_func( "list",         recipe_list       );
register_recipe_func( "parse_line",   parse_recipe_line );
register_func("line", "parse_recipe", parse_recipe_line );


