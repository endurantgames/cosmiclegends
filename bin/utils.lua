#!/usr/bin/lua

local g = _G.g;

local function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s
   do    if s ~= 1 or cap ~= ""
         then table.insert(t,cap)
         end
         last_end  = e+1
         s, e, cap = str:find(fpat, last_end)
   end
   if   last_end <= #str
   then cap = str:sub(last_end)
        table.insert(t, cap)
   end
   return t
end

-- ==================================================================================
-- code by GianlucaVespignani - 2012-03-04; 2013-01-26
-- Search files in a path, alternative in sub directory
-- @param  dir_path string         - (";" for multiple paths supported)
-- @param  filter   string         - eg.: ".txt" or ".mp3;.wav;.flac"
-- @param  s        bool           - search in subdirectories
-- @param  pformat  format of data - 'system' for system-dependent number; nil or string with formatting directives
-- @return files, dirs             - files and dir are tables {name, modification, path, size}
--
local function file_search(dir_path, filter, s, pformat)
  -- === Preliminary functions ===
  -- comparison function like the IN() function like SQLlite, item in a array
  -- useful for compare table for escaping already processed item
  -- Gianluca Vespignani 2012-03-03
  --
  local c_in =
    function(value, tab)
      for k,v in pairs(tab)
      do  if v==value then return true end
      end
      return false
    end; -- function

  local string = string -- http://lua-users.org/wiki/SplitJoin
  function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
  end -- function

  local ExtensionOfFile =
    function(filename)
      local rev     = string.reverse(filename)
      local len     = rev:find("%.")
      local rev_ext = rev:sub(1,len)
      return string.reverse(rev_ext)
    end -- function

  -- === Init ===
  dir_path         = dir_path or cwd
  filter           = string.lower(filter) or "*"
  local extensions = split(filter, ";") -- filter:split(";")
  s                = s or false -- as /s : subdirectories

  local os_date;

  if    pformat == 'system' -- if 4th arg is explicity 'system', then return the
                            -- system-dependent number representing date/time
  then  os_date = function(os_time) return os_time end
  else  -- if 4th arg is nil use default, else it could be a string
        -- that respects the Time formatting directives
        pformat = pformat or "%Y/%m/%d" -- eg.: "%Y/%m/%d %H:%M:%S"
        os_date = function(os_time)
                    return os.date(pformat, os_time)
                  end -- function
  end; -- if pformat

  -- == MAIN ==
  local files = {}
  local dirs = {}
  local paths = dir_path:split(";")
  for i,path in ipairs(paths)
  do  for f in lfs.dir(path)
      do if   f ~= "." and f ~= ".."
         then local attr = lfs.attributes ( path.."/"..f )
              if   attr.mode == "file"
              then if   filter=="*" or c_in( string.lower( ExtensionOfFile(f) ), extensions)
                   then table.insert(files,
                                  { name         = f,
                                       modification = os_date(attr.modification),
                                       path         = path.."/",
                                       ext          = ExtensionOfFile(f),
                                       size         = attr.size
                                     });
                   end -- if filter = "*"
              else -- attr.mode == "file"
                   if   filter=="*" -- if attr.mode == "directory" and file ~= "." and file ~= ".." then end
                   then table.insert(dirs,
                                  { name         = f,
                                       modification = os_date(attr.modification),
                                       path         = path.."/",
                                       size         = attr.size
                                     });
                   end -- if filter="*"
                   if   s and attr.mode == "directory"
                   then local subf, subd;
                        subf, subd = file_search(path.."/"..f, filter, s, pformat)
                        for i,v in ipairs(subf)
                        do  table.insert(files,
                                     { name         = v.name,
                                           modification = v.modification,
                                           path         = v.path,
                                           ext          = ExtensionOfFile(f),
                                           size         = v.size
                                         });
                        end -- for i, v
                        for i,v in ipairs(subd)
                        do  table.insert(dirs,
                                     { name         = v.name,
                                           modification = v.modification,
                                           path         = v.path,
                                           ext          = ExtensionOfFile(f),
                                           size         = v.size
                                         });
                        end -- for i, v
                    end -- if s and attr.mode == direcotry
              end -- if attr.mode = file
         end
      end
  end
  return files, dirs
end

--[=[        ABOUT ATTRIBUTES
> for k,v in pairs(a) do print(k..' \t'..v..'') end
    dev     2
    change  1175551262        -- date of file Creation
    access  1235831652
    rdev    2
    nlink   1
    uid     0
    gid     0
    ino     0
    mode    file
    modification    1181692021 -- Date of Last Modification
    size    805 in byte
]=]

local function vprint(s, l) if g.CONFIG.verbose   then print(string.format(g.CONFIG.logfmt, s or "", l or "")) end; end;
local function eprint(s, l) if g.CONFIG.errors    then print(string.format(g.CONFIG.logfmt, s or "", l or "")) end; end;
local function sprint(s, l) if g.CONFIG.summary   then print(string.format(g.CONFIG.logfmt, s or "", l or "")) end; end;
local function yprint(s, l) if g.CONFIG.debugyaml then print(string.format(g.CONFIG.logfmt, s or "", l or "")) end; end;
local function pprint(s, l) print(string.format(g.CONFIG.logfmt, s or "", l or "")); end;
-- local function iprint(s, data) print(string.format, s or "", inspect(data)); end;
-- http://lua-users.org/wiki/FileInputOutput

local function register_bucket_func(name, func_func)
  if not name      then eprint("Can't register bucket func",      name); os.exit(); end; 
  if not func_func then eprint("Can't register bucket func_func", name); os.exit(); end;
  vprint("Registering bucket function", name);
  FUNC.bucket(name) = func_func;
end;

local function bucket_exists(bucket)
  bucket = bucket or "";
  bucket = bucket:upper();
  if   g.bucket[bucket]
  then return true
  else return false
  end;
end;


local function bucket_count(bucket)
  bucket = bucket or "";
  bucket = bucket:upper();
  if   not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Can't get count");
  else return g.count[bucket]
  end;
end;

local function bucket_contents(bucket)
  bucket = bucket or "";
  bucket = bucket:upper();
  if not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Can't get contents");
  else return g.bucket[bucket];
  end; -- if not bucket_exists
end; -- function

local function bucket_dump(bucket, printfunc)
  printfunc = printfunc or pprint;
  bucket = bucket or "";
  bucket = bucket:upper();
  if not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Can't do dump");
       return nil;
  else printfunc("Dump starts ===========", bucket);
       for i, line in pairs(bucket_contents(bucket))
       do printfunc(bucket .. "[" .. i .. "]", line);
       end;
       printfunc("Dump ends ===========", bucket);
  end; -- if not bucket_exists
end;

local function bucket_fetch(bucket, key)
  key    = key or "";
  bucket = bucket or "";
  bucket = bucket:upper();
  if not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Can't do lookup");
       return nil;
  else bucket_list = bucket_contents(bucket);
       if not bucket_list
       then   eprint("Error: can't get bucket list", bucket)
              return nil;
       elseif not bucket_list[key]
              then eprint("Error: no value for", bucket .. "[" .. key .. "]");
              return nil;
       end; -- if not bucket_list
  end; -- if not bucket_exists

end;


local function bucket_test(bucket, key)
  key    = key or "";
  bucket = bucket or "";
  bucket = bucket:upper();
  if not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Can't do test");
       return false;
  else local value = bucket_fetch(bucket, key)
       if value then return true else return false; end;
  end; -- not bucket_exists
end; -- function

local function bucket_add(bucket, data)
  bucket = bucket or "";
  bucket = bucket:upper();
  if   not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Unsaved data:", inspect(data));
       os.exit(1);
  else table.insert(g.bucket[bucket], data);
       g.count[bucket] = bucket_count(bucket) + 1;
  end;
end;

register_bucket_func("exists"  , bucket_exists   );
register_bucket_func("count"   , bucket_count    );
register_bucket_func("content" , bucket_contents );
register_bucket_func("dump"    , bucket_dump     );
register_bucket_func("fetch"   , bucket_fetch    );
register_bucket_func("test"    , bucket_test     );
register_bucket_func("add"     , bucket_add      );

local function get_slug(file)
  file = string.gsub(file, "^%"  .. g.CONFIG.dir.source,        "");
  file = string.gsub(file, "%"   .. g.CONFIG.ext.source .. "$", "");
  file = string.gsub(file, "^/",                                "");
  file = string.gsub(file, "/$",                                "");
  return file;
end;

local function path_level(path)
  path   = get_slug(path);
  local  pathdirs = split(path, "/");
  local  level = #pathdirs;
  if     not(string.find(path, g.CONFIG.intro))
  then   level = level + 1;
  end;   -- if string.find
  return level;
end; -- function

local function file_exists(file)
  local  f = io.open(file, "rb")
  if     f then f:close() end
  return f ~= nil
end -- function

local function find_file(file)
  file = file or "";
  local  filename_md   = file .. g.CONFIG.ext.markdown;
  local  filename_yaml = file .. g.CONFIG.ext.yaml;
  if     file_exists( file )
  then   pprint("found raw file", file);
         return false, file, "raw";
  elseif file_exists(  filename_md)
  then   pprint("found markdown", filename_md);
         return true,  filename_md, "markdown";
  elseif file_exists(filename_yaml)
  then   pprint("found yaml", filename_yaml);
         return true,  filename_yaml, "yaml"
  else   eprint("Couldn't find :(", file);
         return false, file, "not_found"
  end;
end;

local function adjust_md_level(source_file, markdown)
  local octo, _    = string.match(markdown, "^(#+)");
  local octo_level = string.len(octo or "");
  if   octo_level > 1
  then local mod = octo_level - 1;
       local oldhash = "\n" .. string.rep("#", mod);
       local newhash = "\n";
       markdown = string.gsub(markdown, oldhash, newhash);
  end; -- if octo_level

  local level = path_level(source_file);
  if   level >= 1
  then local mod = level - 1;
       local oldhash = "\n#";
       local newhash = "\n#" .. string.rep("#", mod)
       markdown = string.gsub(markdown, oldhash, newhash);
       markdown = string.gsub(markdown, "\n#####+", "\n#####");
       -- handle the H6 headings
       markdown = string.gsub(markdown, "\n:#", "\n######");
  end; -- if level

  return markdown;
end;

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
local function slurp(file, no_parse)
  no_parse = no_parse
          or string.find(file, g.CONFIG.ext.yaml)
          or string.find(file, g.CONFIG.ext.recipe);

  if not file_exists(file) then eprint("File doesn't exist", file); return nil end;

  local lines = {}
  for   line in io.lines(file) do lines[#lines + 1] = line end
  local slurped = "\n" .. table.concat(lines, "\n") .. "\n";

  if not no_parse then slurped = adjust_md_level(file, slurped); end;  -- if not no_parse
  return slurped;
end -- function

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

local function dump(file, contents)
  local f = io.open(file, "wb");
  f:write(contents);
  f:close();
end -- function

local function ignore(name)
  if   string.match(name, g.CONFIG.ignore)
  then return true
  else return false;
  end;
end;  -- function

local function map_src_fs(dir_src)
  dir_src = dir_src or g.CONFIG.dir.source;
  local files, dirs = file_search(dir_src, g.CONFIG.ext.filter, true)
  -- os.exit(0);

  for k, v in pairs(files)
  do  if   ignore(v.name)
      then vprint("skipping file", v);
           break;
      else local filekey = v.path .. v.name;
           filekey = filekey:gsub("^" .. g.CONFIG.dir.source .."/", "");
           filekey = filekey:gsub(g.CONFIG.ext.markdown .. "$",     "");
           filekey = filekey:gsub(g.CONFIG.ext.yaml     .. "$",     "");
           g.bucket.FILES[filekey]      = {};
           g.count.FILES = g.count.FILES + 1;
           for    key, value in pairs(v)
           do     g.bucket.FILES[filekey][key] = value;
           end;
           if     string.find(v.name, "%"  .. g.CONFIG.ext.markdown .. "$")
           then   g.bucket.FILES[filekey].ext      = g.CONFIG.ext.markdown;
                  g.bucket.FILES[filekey].markdown = true;
           elseif string.find(v.name, "%"  .. g.CONFIG.ext.yaml .. "$")
           then   g.bucket.FILES[filekey].ext      = g.CONFIG.ext.yaml;
                  g.bucket.FILES[filekey].yaml     = true;
           end; -- if string.find
          -- vprint("g.FILES[" .. filekey .. "] = ", inspect(g.FILES[filekey]));
      end; -- if ignore
  end;

  for k, v in pairs(dirs)
  do  if   ignore(v.path)
      then vprint("Skipping directory", v.name); break
      else local filename   = v.name;
           g.DIRS[filename] = true;
           g.count.DIRS     = g.count.DIRS + 1;
           vprint("Learning directory location", filename);
      end; -- if ignore
  end; -- for k, v

  return files, dirs;
end;

local   function was_used_line(line)
  local line_data = g.bucket.FILES[line] or g.bucket.DIRS[line];
  if    line_data and line_data.used
  then  return true
  else  return false
  end;
end;


local    function mark_line_used(line)
  if     g.bucket.FILES[line]
  then   g.bucket.FILES[line].used = true;
  elseif g.bucket.DIRS[line]
  then   g.bucket.DIRS[line].used = true;
  else   eprint("Error: can't mark line", inspect(line));
  end;
end;


local function parse_recipe_line(line)

  local found = {
          comment  = false,
          dir      = false,
          ext_md   = false,
          ext_yaml = false,
          asterisk = false
        };

  local tests = {
          comment  = "^%# ",
          dir      = "/$",
          ext_md   = "%" .. g.CONFIG.ext.markdown .. "$",
          ext_yaml = "%" .. g.CONFIG.ext.yaml     .. "$",
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
         eprint("looking for index", line .. "/" .. g.CONFIG.intro);
         parse_recipe_line(line .. "/" .. g.CONFIG.intro);
  elseif found.asterisk
  then   local dir = string.gsub(line, "/%*$", "");

         local found_files, _ =
                 file_search(
                   g.CONFIG.dir.source .. "/" .. dir,
                   g.CONFIG.ext.filter
                 );
         for _, v in pairs(found_files)
         do  local ff = string.gsub(v.name, "%"..g.CONFIG.ext["filter"  ].."$", "");
                   ff = string.gsub(ff,          g.CONFIG.ext["markdown"].."$", "");
                   ff = string.gsub(ff,          g.CONFIG.ext["yaml"    ].."$", "");
             parse_recipe_line(        dir.."/"..ff);
         end; -- for
  elseif bucket_fetch("files", line) -- g.bucket.FILES[line]
  then   local  filedata = bucket_fetch("files", line); -- g.bucket.FILES[line];
         if     filedata.ext == g.CONFIG.ext.yaml
         then   local  yaml_file = g.CONFIG.dir.source.."/"..line..g.CONFIG.ext.yaml;
                if   file_exists(yaml_file)
                then bucket_add("build", yaml_file);
                     mark_line_used(line);
                end;
         elseif filedata.ext == g.CONFIG.ext.markdown
         then   local md_file = g.CONFIG.dir.source .. "/" .. line .. g.CONFIG.ext.markdown;
                if file_exists(md_file)
                then bucket_add("build", md_file);
                     mark_line_used(line);
                end;
         else   eprint("failed to find:", line);
                eprint("> failed to find:", line .. g.CONFIG.ext.yaml);
                eprint("> failed to find:", line .. g.CONFIG.ext.markdown);
         end;
  elseif found.nothing
  then   -- eprint("couldn't find", "line = " .. inspect(line));
         -- eprint("or markdown",   line .. g.CONFIG.ext.markdown);
         -- eprint("or yaml",       line .. g.CONFIG.ext.yaml);
         -- eprint("dump of g.FILES", inspect(g.FILES));
        bucket_add("err", line);
  end;
end;



local function recipe_list()
  local files, _ = file_search(g.CONFIG.dir.recipe, g.CONFIG.ext.recipe, false)
  sprint("Listing Recipes:", #files .. " known");
  sprint("Recipe directory", g.CONFIG.dir.recipe);
  print(string.format(g.CONFIG.lsfmt, "Filename",          "Command Line"      ));
  print(string.format(g.CONFIG.lsfmt, string.rep("-", 30), string.rep("-", 25) ));
    for k, v in pairs(files)
  do  print(
        string.format(
          g.CONFIG.lsfmt,
          v.path .. v.name,
          g.CONFIG.dir.bin   ..
            "/"              ..
            g.CONFIG.appname ..
            " "              ..
            string.gsub(v.name, g.CONFIG.ext.recipe, "")
        )
      );
  end;
  os.exit(0);
end;

-- store functions for later use
g.FUNC = {};

g.FUNC.char = {};
g.FUNC.char.base        = yaml_char_base;        -- func(bio_base)
g.FUNC.char.char        = yaml_character;        -- func(yaml_tree)
g.FUNC.char.gender      = yaml_char_gender;      -- func(bio_gender)
g.FUNC.char.picture     = yaml_char_picture;     -- func(character_picture)
g.FUNC.char.power_words = yaml_char_power_words; -- func(stats_power_words)
g.FUNC.char.relatives   = yaml_char_relatives;   -- func(bio_relatives)

g.FUNC.file.dump       = dump;        -- func(filename, contents)
g.FUNC.file.map_src_fs = map_src_fs;  -- func(dir_src)
g.FUNC.file.search     = file_search;
g.FUNC.file.slurp      = slurp;
g.FUNC.file.slurp_yaml = slurp_yaml;  -- func(filename)

g.FUNC.line.mark_line_used = mark_line_used; -- func(line)
g.FUNC.line.was_used       = was_used_line;  -- func(line)

local function register_util_category(name, quiet)
  if quiet == nil then quiet = true; end;

  if not name
  then eprint("Can't create UTIL category", name);
       os.exit();
  end;

  if g.FUNC[name] and not quiet
  then eprint("UTIL category exists", name);
       os.exit();
  end;

  vprint("Creating UTIL category", name);
  g.FUNC.util = g.FUNC.util or {};
  g.FUNC.util[name] = {}
end;

g.FUNC.util = g.FUNC.util or {};
g.FUNC.util.register_category = register_util_category;

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

register_format("error", yaml_error, "unknown");

local function register_util(name, func_func)
  if not name
  then eprint("Error: no util name", name);
       os.exit();
  end;
  if not func_func
  then eprint("Error: no util func_func", name);
       os.exit();
  end;
  vprint("Registering FUNC.util", name);
  g.FUNC.util[name] = func_func;
end;

g.FUNC.util.register = register_util;

local function register_func_category(name, quiet)
  if quiet == nil then quiet = true; end;

  if not name
  then eprint("Can't create FUNC category", name);
       os.exit();
  end;

  if g.FUNC[name] and not quiet
  then eprint("FUNC category exists", name);
       os.exit();
  end;

  vprint("Creating FUNC category", name);
  g.FUNC[name] = {}
end;

g.FUNC.register = register_func_category;

g.FUNC.register("util");
g.FUNC.register("yaml");
g.FUNC.register("file");

local UTIL = g.FUNC.util;

UTIL.register("split", split);
UTIL.register("ignore", ignore);
vprint("Registering *print utils", string.rep("-",20));
UTIL.register("eprint", eprint);
UTIL.register("pprint", pprint);
UTIL.register("sprint", sprint);
UTIL.register("vprint", vprint);
UTIL.register("yprint", yprint);

local function register_yaml_func(name, func_func)
  if not g.FUNC.yaml then g.FUNC.yaml = {}; end;
  if not name
  then eprint("Error: no yamlfunc name", name);
       os.exit();
  end;
  if not func_func
  then eprint("Error: no yamlfunc func_func", name);
       os.exit();
  end;

  vprint("Registering yamlfunc", name);
  g.FUNC.yaml[name] = func_func;
end;

g.FUNC.yaml.register = register_yaml_func;

register_yaml_func("common"          , yaml_common     );
register_yaml_func("error"           , yaml_error      );
register_yaml_func("get_alpha_keys"  , get_alpha_keys  );
register_yaml_func("get_sorted_keys" , get_sorted_keys );
register_yaml_func("unpack_tree"     , unpack_tree     );

-- ==========================================================
-- Command line interface: https://lua-cliargs.netlify.com/#/

cli:set_name(g.CONFIG.appname);
cli:set_description("it creates the .md files we need");

cli:splat("RECIPE", "the recipe to build", "", 1);

cli:option("-o, --outfile=OUTFILE", "specify the outfile"             );
cli:flag(  "-v, --verbose",         "be more wordy than usual",  false);
cli:flag(  "-q, --quiet",           "don't summarize each step", false);
cli:flag(  "-l, --list",            "list the known recipes",    false);
cli:flag(  "-y, --debugyaml",       "be verbose about yaml",     false);
cli:flag(  "-e, --[no-]errors",     "show errors",               true );

local args, err = cli:parse(arg);

if not args then cli:print_help(); os.exit(1); end;

if err then print(string.format("%s: %s", cli.name, err)); os.exit(1); end;

if args and args.list then recipe_list()                                                     end;
if args.quiet         then g.CONFIG.summary   = false else g.CONFIG.summary   = true;        end;
if args.verbose       then g.CONFIG.verbose   = true
                           g.CONFIG.debugyaml = true  else g.CONFIG.verbose   = false;       end;
if args.debugyaml     then g.CONFIG.debugyaml = true  else g.CONFIG.debugyaml = false;       end;
if args.errors        then g.CONFIG.errors    = true  else g.CONFIG.errors    = false;       end;
if args.RECIPE        then g.CONFIG.recipe    = args.RECIPE; g.CONFIG.outfile = args.RECIPE; end;
if args.outfile       then g.CONFIG.outfile   = args.outfile                                 end;

--

-- =======================================
-- Everything above this is initialization
-- =======================================

-- start run -----------------------------
vprint("Running in verbose mode");
sprint("Showing summaries");
yprint("Being wordy about yaml parsing");

-- read the recipe
sprint("reading recipe", g.CONFIG.recipe);
local recipe_src = slurp(g.CONFIG.dir.recipe .. "/" .. g.CONFIG.recipe .. g.CONFIG.ext.recipe, true);

if not recipe_src then print("Error: Can't read that recipe file"); os.exit() end
local recipe = split(recipe_src, "[\r\n]+");
sprint("recipe read", #recipe .. " lines in recipe");

-- parse the filesystem tree
sprint("Loading the filesystem map", g.CONFIG.dir.source );
map_src_fs(g.CONFIG.dir.source);
vprint("Filesystem mapped.", g.count.FILES .. " files");

-- if   g.count.FILES > 1
-- then for k, data in pairs(g.FILES) do vprint(k, data.name); end;
-- else eprint("(no excerpt available)"); os.exit(1);
-- end;

-- vprint("Directories mapped.", g.count.DIRS .. " dirs");

-- parse the recipe, store in g.bucket.BUILD
for _, i in pairs(recipe)
do  if   not string.find(i, "^# ")
    then -- vprint("parsing recipe line", i);
         parse_recipe_line(i)
    end;
end;

sprint("recipe read", bucket_count("build") .. " files in build");
-- ready now to read files

for _, v in pairs(g.bucket.BUILD)
do  if     v:find("%" .. g.CONFIG.ext.yaml     .. "$")
    then   local slurped = slurp_yaml(v);
           -- vprint("slurping ", v);
           table.insert(g.outtxt, slurped);
    elseif v:find("%" .. g.CONFIG.ext.markdown .. "$")
    then   local slurped = slurp(v);
           -- vprint("slurping ", v);
          table.insert(g.outtxt, slurped);
    end;
end;

sprint("done reading/parsing files", g.count.BUILD .. " files");

-- save the output
local outfile = g.CONFIG.dir.build .. "/" .. g.CONFIG.outfile .. g.CONFIG.ext.out;
local outtxt = table.concat(g.outtxt, "\n");

print("Writing to file", outfile);
-- print("Content type is", type(outtxt));
print("Content size is", string.len(outtxt) .. " characters");
dump(outfile, outtxt);

-- notify of errors
eprint(
  "number of errors",
  (g.count.ERR or 0)
    .. " error"
    .. (bucket_count("err") and bucket_count("err") == 1 and "" or "s")
);

eprint("error count is", inspect(bucket_count("err")));

if   false and bucket_count("err") > 0
then bucket_dump("err", eprint);
     -- eprint("DIRS", inspect(bucket_contents("dirs")));
end;

if   bucket_count("err") > 0
then local err_start = 1;
     local err_stop = math.min(g.CONFIG.maxerrors, g.count.ERR);
     for i = err_start, err_stop, 1
     do local errmsg;
        local filename = g.bucket.ERR[i];
        if    bucket_fetch("files", filename) -- g.bucket.FILES[filename]
        then  errmsg = "Improperly marked as missing";
        else  errmsg = (string.find(filename, g.CONFIG.intro .. "$") or
                        string.find(filename, "/$"))
                        and "Warning: Missing index"
                        or  "Alert: Missing file";
        end -- if g.bucket.FILES[filename]
        eprint(errmsg, filename)
     end; -- do
     if   bucket_count("err") > g.CONFIG.maxerrors
     then eprint("...");
          eprint(bucket_count("err") - g.CONFIG.maxerrors .. " errors hidden", "not shown");
     end;
     -- vprint(string.rep("-", 25), string.rep("-", 20));
     -- vprint("g.bucket.FILES", inspect(g.FILES));
end; -- if g.count.ERR
