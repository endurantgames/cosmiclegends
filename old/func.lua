#!/usr/bin/lua

local _G = _G;
local  g = _G.g or {};

_G.g = { -- g for "global"   g = _G.g
   FILES     = { },
   YAML      = { },
   bucket    = {
     BUILD   = { },
     CONTENT = { },
     DIRS    = { },
     ERR     = { },
     FILES   = { } },
   count     = {
     BUILD   = 0,
     DIRS    = 0,
     ERR     = 0,
     FILES   = 0, },
   outtxt    = { },
};

local CONFIG = g.CONFIG;
g.FUNC       = {}; -- functions
local FUNC   = g.FUNC;
local UTIL   = FUNC.util;

package.path = "./?.lua;./?/load.lua;" .. package.path;

local lfs     = require "lfs"    ;
local cli     = require "cliargs";
local lyaml   = require "lyaml"  ; -- https://github.com/gvvaughan/lyaml
local inspect = require "inspect"; -- https://github.com/kikito/inspect.lua

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
  if last_end <= #str then cap = str:sub(last_end); table.insert(t, cap) end
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

local function file_search(dir_path, filter, s, pformat)
  -- === Preliminary functions ===
  -- comparison function like the IN() function like SQLlite, item in a array
  -- useful for compare table for escaping already processed item
  -- Gianluca Vespignani 2012-03-03

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
                   then table.insert(
			  files,
                          { name         = f,
                            modification = os_date(attr.modification),
                            path         = path.."/",
                            ext          = ExtensionOfFile(f),
                            size         = attr.size
                           });
                   end -- if filter = "*"
              else -- attr.mode == "file"
                   if   filter=="*" -- if attr.mode == "directory" and file ~= "." and file ~= ".." then end
                   then table.insert(
			  dirs,
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
                        do  table.insert(
			      files,
                              { name         = v.name,
                                modification = v.modification,
                                path         = v.path,
                                ext          = ExtensionOfFile(f),
                                size         = v.size
                              });
                        end -- for i, v
                        for i,v in ipairs(subd)
                        do  table.insert(
			      dirs,
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
  dev          2
  change       1175551262 -- date of file Creation
  access       1235831652
  rdev         2
  nlink        1
  uid          0
  gid          0
  ino          0
  mode         file
  modification 1181692021 -- Date of Last Modification
  size         805 in byte
]=]

-- == meta-functions to register ============================================================
--
local function register_func_cat(name, quiet)
  if quiet == nil then quiet = true; end;
  if     not name                   then eprint("Can't create FUNC category", name); os.exit();
  elseif g.FUNC[name] and not quiet then eprint("FUNC category exists",       name); os.exit();
  end;
  vprint("Creating FUNC category", name);
  g.FUNC[name] = {}
end;

local function register_func(cat, name, func_func)
  if     not cat       then cat = "util"
  elseif not name      then eprint("Can't register " .. string.upper(cat) .. " func", name); os.exit();
  elseif not func_func then eprint("No func "        .. string.upper(cat) .. " func", name); os.exit();
  end;
  local  func_cat = FUNC[cat];
  if not func_cat then register_func_cat(cat); func_cat = FUNC[cat]; end;
  vprint("Registering " .. string.upper(cat) .. " func", name);
  func_cat[name] = func_func;
end;

vprint(            "Registering function categories" );
register_func_cat( "bucket"                          );
register_func_cat( "file"                            );
register_func_cat( "line"                            );
register_func_cat( "recipe"                          );
register_func_cat( "util"                            );
register_func_cat( "yaml"                            );

vprint( "Creating register_*_functions" ); -- ===========================================
local function register_bucket_func( n, ff ) register_func( "bucket", n, ff ); end;
local function register_file_func(   n, ff ) register_func( "file",   n, ff ); end;
local function register_line_func(   n, ff ) register_func( "line",   n, ff ); end;
local function register_recipe_func( n, ff ) register_func( "recipe", n, ff ); end;
local function register_util_func(   n, ff ) register_func( "util",   n, ff ); end;
local function register_yaml_func(   n, ff ) register_func( "yaml",   n, ff ); end;
local          register_util               = register_util_func;
-- -- above: register_*_ functions -----------------------------------------------------

vprint( "Registering functions defined earlier"            ); -- =======================
register_util_func( "split",             split             );
register_util_func( "register_func",     register_func     );
register_util_func( "register_func_cat", register_func_cat );
register_util_func( "register_util",     register_util     );

-- == print functions ================================================================
local function eprint(s, l) if CONFIG.errors    then print(string.format(CONFIG.logfmt, s or "", l or "")); end; end;
local function pprint(s, l)                          print(string.format(CONFIG.logfmt, s or "", l or ""));      end;
local function sprint(s, l) if CONFIG.summary   then print(string.format(CONFIG.logfmt, s or "", l or "")); end; end;
local function vprint(s, l) if CONFIG.verbose   then print(string.format(CONFIG.logfmt, s or "", l or "")); end; end;
local function yprint(s, l) if CONFIG.debugyaml then print(string.format(CONFIG.logfmt, s or "", l or "")); end; end;
-- -- above: print functions ----------------------------------------------------------
vprint(             "Registering *print utils",  string.rep("-", 20) ); -- ============
register_util_func( "eprint", eprint );
register_util_func( "pprint", pprint );
register_util_func( "sprint", sprint );
register_util_func( "vprint", vprint );
register_util_func( "yprint", yprint );

-- -- above: util functions -----------------------------------------------------------
-- == bucket functions ================================================================
--
local function bucket_exists(bucket)
  bucket = bucket or ""; bucket = bucket:upper();
  if g.bucket[bucket] then return true else return false end;
end;

local function bucket_count(bucket)
  bucket = bucket or "";
  bucket = bucket:upper();
  if   not bucket_exists(bucket)
  then eprint( "Error: unknown bucket", bucket );
       eprint( "Can't get count",       bucket );
  else return g.count[bucket]
  end;
end;

local function bucket_contents(bucket)
  bucket = bucket or "";
  bucket = bucket:upper();
  if not bucket_exists(bucket)
  then   eprint( "Error: unknown bucket", bucket );
         eprint( "Can't get contents",    bucket );
  else   return g.bucket[bucket];
  end;   -- if not bucket_exists
end; -- function

local function bucket_dump(bucket, printfunc)
  printfunc = printfunc or pprint;
  bucket    = bucket or "";
  bucket    = bucket:upper();
  if not bucket_exists(bucket)
  then   eprint("Error: unknown bucket", bucket);
         eprint("Can't do dump");
         return nil;
  else   printfunc("Dump starts ===========", bucket);
         for i, line in pairs(bucket_contents(bucket))
         do printfunc(bucket .. "[" .. i .. "]", line);
         end;
         printfunc("Dump ends ===========", bucket);
  end;   -- if not bucket_exists
end;

local function bucket_fetch(bucket, key)
  key    = key or "";
  bucket = bucket or "";
  bucket = bucket:upper();
  if not bucket_exists(bucket)
  then   eprint("Error: unknown bucket", bucket);
         eprint("Can't do lookup");
         return nil;
  else   bucket_list = bucket_contents(bucket);
         if not bucket_list
         then   eprint("Error: can't get bucket list", bucket)
                return nil;
         elseif not bucket_list[key]
                then eprint("Error: no value for", bucket .. "[" .. key .. "]");
                return nil;
         end;   -- if not bucket_list
  end;   -- if not bucket_exists
end;

local function bucket_test(bucket, key)
  key    = key or "";
  bucket = bucket or "";
  bucket = bucket:upper();
  if not bucket_exists(bucket)
  then   eprint("Error: unknown bucket", bucket);
         eprint("Can't do test");
         return false;
  else   local value = bucket_fetch(bucket, key)
         if value then return true else return false; end;
  end;   -- not bucket_exists
end;     -- function

local function bucket_add(bucket, data)
  bucket = bucket or "";
  bucket = bucket:upper();
  if     not bucket_exists(bucket)
  then   eprint("Error: unknown bucket", bucket);
         eprint("Unsaved data:", inspect(data));
         os.exit(1);
  else   table.insert(g.bucket[bucket], data);
         g.count[bucket] = bucket_count(bucket) + 1;
  end;
end;

register_bucket_func( "exists"   , bucket_exists   );
register_bucket_func( "count"    , bucket_count    );
register_bucket_func( "contents" , bucket_contents );
register_bucket_func( "dump"     , bucket_dump     );
register_bucket_func( "fetch"    , bucket_fetch    );
register_bucket_func( "test"     , bucket_test     );
register_bucket_func( "add"      , bucket_add      );

-- -- above: bucket functions ----------------------------------------------------------
-- == file functions ===================================================================
--
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
  if    octo_level > 1
  then  local mod = octo_level - 1;
        local oldhash = "\n" .. string.rep("#", mod);
        local newhash = "\n";
        markdown = string.gsub(markdown, oldhash, newhash);
  end;  -- if octo_level

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

register_util(      "path_level",      path_level      );
register_util(      "get_slug",        get_slug        );
register_file_func( "exists",          file_exists     );
register_file_func( "find",            find_file       );
register_file_func( "adjust_md_level", adjust_md_level );
register_file_func( "slurp",           slurp           );

-- -- above: file functions ------------------------------------------------------------
-- == yaml functions ===================================================================
--
local function unpack_yaml_tree(yaml_tree, tree_id)
  tree_id = tree_id or "no id";
  -- yprint("==================", "------------------");
  -- yprint(tree_id .. ":before", inspec(yaml_tree));
  if     yaml_tree == nil
  then   -- eprint("Error! in unpack_yaml_tree", "yaml_tree (" .. tree_id .. ") = nil");
         return {};
         -- os.exit(1);
  elseif yaml_tree and type(yaml_tree) ~= "table"
  then   eprint("Error! unpacking", "type(" .. tree_id .. ") = " .. type(yaml_tree));
         vprint("Should be:", "table");
         os.exit(1);
  elseif tree_id and type(tree_id) ~= "string"
  then   eprint("Error!", "type(" .. tree_id .. ") = " .. type(tree_id));
         vprint("Should be:", "string");
         os.exit(1);
  end;
  local flat_tree = {};
  for k, v in pairs(yaml_tree)
  do  if   type(v) == "table"
      then for i, j in pairs(v) do if type(i) == "string" then flat_tree[i] = j; end; end;
      end;
      flat_tree[k] = v;
  end;
  return flat_tree;
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

local function register_format(name, func_func, x_format)
  x_format = x_format or name;
  if     g.YAML[x_format] then eprint("Error: format registered",     x_format); os.exit();
  elseif not func_func    then eprint("Error: no format to register", x_format); os.exit();
  end;
  vprint( "Registering x_format", x_format );
  g.YAML[ x_format ] = func_func;
end;

register_yaml_func( "common",          yaml_common           );
register_yaml_func( "error",           yaml_error            );
register_yaml_func( "get_alpha_keys",  get_alpha_keys        );
register_yaml_func( "get_sorted_keys", get_sorted_keys       );
register_yaml_func( "register",        register_yaml_func    );
register_yaml_func( "unpack_tree",     unpack_tree           );
register_yaml_func( "register_format", register_format       );
register_format(    "error",           yaml_error, "unknown" );
register_yaml_func  "register_format", register_format       );

-- -- above: yaml functions ------------------------------------------------------------
-- == file functions ===================================================================
--
local function dump(file, contents)
  local f = io.open(file, "wb");
        f:write(contents);
        f:close();
end -- function

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

register_file_func( "dump"       , dump        );
register_file_func( "map_src_fs" , map_src_fs  );
register_file_func( "search"     , file_search );
register_file_func( "slurp"      , slurp       );
register_file_func( "slurp_yaml" , slurp_yaml  );

-- -- above: file functions ------------------------------------------------------------
-- == util functions ===================================================================
--
local function ignore(name)
  if string.match(name, g.CONFIG.ignore) then return true else return false; end;
end;  -- function

register_util_func( "ignore", ignore );

-- -- above: util functions ------------------------------------------------------------
-- == line functions ===================================================================
--
local   function was_used_line(line)
  local line_data = g.bucket.FILES[line] or g.bucket.DIRS[line];
  if    line_data and line_data.used
  then  return true
  else  return false
  end;
end;

local    function mark_line_used(line)
  if     g.bucket.FILES[line] then g.bucket.FILES[ line ].used = true;
  elseif g.bucket.DIRS[line]  then g.bucket.DIRS[  line ].used = true;
  else   eprint("Error: can't mark line", inspect(line));
  end;
end;

local function parse_recipe_line(line)
  local found      =
        { comment  = false, dir      = false,
          ext_md   = false, ext_yaml = false,
          asterisk = false
        };
  local tests      =
        { comment  = "^%# ", dir      = "/$", asterisk = "/%*$"
          ext_md   = "%" .. g.CONFIG.ext.markdown .. "$",
          ext_yaml = "%" .. g.CONFIG.ext.yaml     .. "$",
        };

  for field, test in pairs(tests)
  do  found[field] = false; found[field] = string.find(line, test);
  end;

  local was_found, found_filename, found_type = find_file(line);

  if false -- set to true to make this print debugging info
  then pprint( line,             string.rep("=", 20) );
       pprint( "was_found",      was_found           );
       pprint( "found_filename", found_filename      );
       pprint( "found_type",     found_type          );
  end;

  if   was_found
  then found.nothing   = false; found.something = true; line = found_filename;
  else found.nothing   = true;  found.something = false;
  end;

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
         do  local ff;
	           ff = string.gsub(  v.name, "%"..g.CONFIG.ext["filter"  ].."$", "" );
                   ff = string.gsub(  ff,          g.CONFIG.ext["markdown"].."$", "" );
                   ff = string.gsub(  ff,          g.CONFIG.ext["yaml"    ].."$", "" );
             parse_recipe_line( dir.."/"..ff );
         end; -- for
  elseif bucket_fetch("files", line) -- g.bucket.FILES[line]
  then   local  filedata = bucket_fetch("files", line); -- g.bucket.FILES[line];
         if     filedata.ext == g.CONFIG.ext.yaml
         then   local  yaml_file = g.CONFIG.dir.source.."/"..line..g.CONFIG.ext.yaml;
                if   file_exists(yaml_file) then bucket_add("build", yaml_file); mark_line_used(line); end;
         elseif filedata.ext == g.CONFIG.ext.markdown
         then   local md_file = g.CONFIG.dir.source .. "/" .. line .. g.CONFIG.ext.markdown;
                if file_exists(md_file) then bucket_add("build", md_file); mark_line_used(line); end;
         else   eprint( "failed to find:",   line                          );
                eprint( "> failed to find:", line .. g.CONFIG.ext.yaml     );
                eprint( "> failed to find:", line .. g.CONFIG.ext.markdown );
         end;
  elseif found.nothing
  then   -- eprint("couldn't find", "line = " .. inspect(line));
         -- eprint("or markdown",   line .. g.CONFIG.ext.markdown);
         -- eprint("or yaml",       line .. g.CONFIG.ext.yaml);
         -- eprint("dump of g.FILES", inspect(g.FILES));
        bucket_add("err", line);
  end;
end;

register_line_func( "mark_used",    mark_line_used );
register_line_func( "parse_recipe", parse_recipe   );
register_line_func( "was_used",     was_used_line  );

-- -- above: line functions -------------------------------------------------------------
-- == recipe functions ==================================================================
--
local function recipe_list()
  local files, _ = file_search( g.CONFIG.dir.recipe, g.CONFIG.ext.recipe, false );
  sprint( "Listing Recipes:", #files .. " known"  );
  sprint( "Recipe directory", g.CONFIG.dir.recipe );
  print( string.format(g.CONFIG.lsfmt, "Filename",          "Command Line"      ) );
  print( string.format(g.CONFIG.lsfmt, string.rep("-", 30), string.rep("-", 25) ) );
  for k, v in pairs(files)
  do  print(
        string.format(
          g.CONFIG.lsfmt,  v.path .. v.name,
          g.CONFIG.dir.bin .. "/" .. g.CONFIG.appname .. 
            " " .. string.gsub(v.name, g.CONFIG.ext.recipe, "")
        )
      );
  end;
  os.exit(0);
end;

register_recipe_func("list", recipe_list );
-- -- above: recipe functions -----------------------------------------------------------
--
