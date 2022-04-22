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

print("--------------------------------  line -------------------------------");

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

assert(UTIL, "UTIL doesn't exist");
assert(UTIL.ignore, "UTIL.ignore doesn't exist"); ignore = UTIL.ignore;
assert(UTIL.split, "UTIL.split doesn't exist"); split = UTIL.split;
assert(UTIL.vprint, "UTIL.vprint doesn't exist"); vprint = UTIL.vprint;
assert(UTIL.sprint, "UTIL.sprint doesn't exist"); sprint = UTIL.sprint;
assert(UTIL.pprint, "UTIL.pprint doesn't exist"); pprint = UTIL.pprint;
assert(UTIL.yprint, "UTIL.yprint doesn't exist"); yprint = UTIL.yprint;

-- if UTIL.ignore then ignore = UTIL.ignore else eprint("Error: no function", "ignore" ); end;
-- if UTIL.split  then split  = UTIL.split  else eprint("Error: no function", "split"  ); end;
-- if UTIL.vprint then vprint = UTIL.vprint else eprint("Error: no function", "vprint" ); end;
-- if UTIL.sprint then sprint = UTIL.sprint else eprint("Error: no function", "sprint" ); end;
-- if UTIL.pprint then pprint = UTIL.pprint else eprint("Error: no function", "pprint" ); end;
-- if UTIL.yprint then yprint = UTIL.yprint else eprint("Error: no function", "yprint" ); end;

assert(FUNC,                    "FUNC doesn't exist"                    );
assert(FUNC.meta,               "FUNC.meta doesn't exist"               );
assert(FUNC.meta.register_cat,  "FUNC.meta.register_cat doesn't exist"  ); register_cat = FUNC.meta.register_cat;
assert(FUNC.meta.register_func, "FUNC.meta.register_func doesn't exist" ); register_func = FUNC.meta.register_func;

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

register_cat("line");

local function register_line_func(n, ff) register_func("line", n, ff); end;
vprint("Loading bucket functions");
local BUCKET, bucket_exists, bucket_count, bucket_contents, bucket_dump, bucket_fetch, bucket_test, bucket_add;

assert(FUNC.bucket,     "FUNC.bucket doesn't exist"     ); BUCKET          = FUNC.bucket;
assert(BUCKET,          "BUCKET doesn't exist"          );
assert(BUCKET.exists,   "BUCKET.exists doesn't exist"   ); bucket_exists   = BUCKET.exists;
assert(BUCKET.add,      "BUCKET.add doesn't exist"      ); bucket_add      = BUCKET.add;
assert(BUCKET.test,     "BUCKET.test doesn't exist"     ); bucket_test     = BUCKET.test;
assert(BUCKET.fetch,    "BUCKET.fetch doesn't exist"    ); bucket_fetch    = BUCKET.fetch;
assert(BUCKET.dump,     "BUCKET.dump doesn't exist"     ); bucket_dump     = BUCKET.dump;
assert(BUCKET.count,    "BUCKET.count doesn't exist"    ); bucket_count    = BUCKET.count;
assert(BUCKET.contents, "BUCKET.contents doesn't exist" ); bucket_contents = BUCKET.contents;

-- if BUCKET.exists   then bucket_exists   = BUCKET.exists   else eprint("Error: no function", "bucket_exists"    ); os.exit(); end;
-- if BUCKET.add      then bucket_add      = BUCKET.add      else eprint("Error: no function", "bucket_add"       ); os.exit(); end;
-- if BUCKET.test     then bucket_test     = BUCKET.test     else eprint("Error: no function", "bucket_test"      ); os.exit(); end;
-- if BUCKET.fetch    then bucket_fetch    = BUCKET.fetch    else eprint("Error: no function", "bucket_fetch"     ); os.exit(); end;
-- if BUCKET.dump     then bucket_dump     = BUCKET.dump     else eprint("Error: no function", "bucket_dump"      ); os.exit(); end;
-- if BUCKET.count    then bucket_count    = BUCKET.count    else eprint("Error: no function", "bucket_count"     ); os.exit(); end;
-- if BUCKET.contents then bucket_contents = BUCKET.contents else eprint("Error: no function", "bucket_contents"  ); os.exit(); end;

-- == line functions ===========================================================

local    function mark_line_used(line)
  if     g.bucket.FILES[line]
  then   g.bucket.FILES[line].used = true;
  elseif g.bucket.DIRS[line]
  then   g.bucket.DIRS[line].used = true;
  else   eprint("Error: can't mark line", inspect(line));
  end;
end;

local   function was_used_line(line)
  local line_data = g.bucket.FILES[line] or g.bucket.DIRS[line];
  if    line_data and line_data.used
  then  return true
  else  return false
  end;
end;

local function parse_recipe_line(line)

  local found = {
          comment  = false, dir      = false,
          ext_md   = false, ext_yaml = false,
          asterisk = false };

  local tests = {
          comment  = "^%# ",
          dir      = "/$",
          ext_md   = "%" .. CONFIG.ext.markdown .. "$",
          ext_yaml = "%" .. CONFIG.ext.yaml     .. "$",
          asterisk = "/%*$"
        };

  for field, test in pairs(tests)
  do  found[field] = false;
      found[field] = string.find(line, test);
  end;

  local was_found, found_filename, found_type = find_file(line);

  -- pprint( line,             string.rep("=", 20) );
  -- pprint( "was_found",      was_found           );
  -- pprint( "found_filename", found_filename      );
  -- pprint( "found_type",     found_type          );

  if   was_found
  then found.nothing   = false;
       found.something = true;
       line            = found_filename;
  else found.nothing   = true;
       found.something = false;
  end;

  -- pprint("found:" and was_found or "not found:", line);

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
         do  local ff = string.gsub(v.name, "%"..CONFIG.ext["filter"  ].."$", "");
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

register_line_func(     "mark_used",    mark_line_used    );
register_line_func(     "was_used",     was_used_line     );
register_func("recipe", "parse_line",   parse_recipe_line );
register_line_func(     "parse_recipe", parse_recipe_line );

print("------------------------------- /line ----------------------------------");
