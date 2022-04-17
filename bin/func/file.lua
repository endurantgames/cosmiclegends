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

print("-------------------------------- file ----------------------------------");

local register_func, register_func_cat;

if UTIL.register_func     then register_func     = UTIL.register_func;     else eprint("Error: no function", "register_func"    ); os.exit(); end;
if UTIL.register_func_cat then register_func_cat = UTIL.register_func_cat; else eprint("Error: no function", "register_func_cat"); os.exit(); end;

-- == file functions ================================================================
--
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

local function get_slug(file)
  file = string.gsub(file, "^%"  .. CONFIG.dir.source,        "");
  file = string.gsub(file, "%"   .. CONFIG.ext.source .. "$", "");
  file = string.gsub(file, "^/",                                "");
  file = string.gsub(file, "/$",                                "");
  return file;
end;

local function path_level(path)
  path   = get_slug(path);
  local  pathdirs = split(path, "/");
  local  level = #pathdirs;
  if     not(string.find(path, CONFIG.intro))
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
  local  filename_md   = file .. CONFIG.ext.markdown;
  local  filename_yaml = file .. CONFIG.ext.yaml;
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
          or string.find(file, CONFIG.ext.yaml)
          or string.find(file, CONFIG.ext.recipe);

  if not file_exists(file) then eprint("File doesn't exist", file); return nil end;

  local lines = {}
  for   line in io.lines(file) do lines[#lines + 1] = line end
  local slurped = "\n" .. table.concat(lines, "\n") .. "\n";

  if not no_parse then slurped = adjust_md_level(file, slurped); end;  -- if not no_parse
  return slurped;
end -- function

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


local function map_src_fs(dir_src)
  dir_src = dir_src or CONFIG.dir.source;
  local files, dirs = file_search(dir_src, CONFIG.ext.filter, true)
  -- os.exit(0);

  for k, v in pairs(files)
  do  if   ignore(v.name)
      then vprint("skipping file", v);
           break;
      else local filekey = v.path .. v.name;
           filekey = filekey:gsub("^" .. CONFIG.dir.source .."/", "");
           filekey = filekey:gsub(CONFIG.ext.markdown .. "$",     "");
           filekey = filekey:gsub(CONFIG.ext.yaml     .. "$",     "");
           g.bucket.FILES[filekey]      = {};
           g.count.FILES = g.count.FILES + 1;
           for    key, value in pairs(v)
           do     g.bucket.FILES[filekey][key] = value;
           end;
           if     string.find(v.name, "%"  .. CONFIG.ext.markdown .. "$")
           then   g.bucket.FILES[filekey].ext      = CONFIG.ext.markdown;
                  g.bucket.FILES[filekey].markdown = true;
           elseif string.find(v.name, "%"  .. CONFIG.ext.yaml .. "$")
           then   g.bucket.FILES[filekey].ext      = CONFIG.ext.yaml;
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

register_file_func("adjust_md_level",  adjust_md_level );
register_file_func("dump",             dump            );
register_file_func("exists",           file_exists     );
register_file_func("find",             find_file       );
register_file_func("get_slug",         get_slug        );
register_file_func("map_src",          map_src_fs      );
register_file_func("path_level",       path_level      );
register_file_func("search",           file_search     );
register_file_func("slurp",            slurp           );
register_file_func("slurp_yaml",       slurp_yaml      );

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

-- local function iprint(s, data) print(string.format, s or "", inspect(data)); end;
-- http://lua-users.org/wiki/FileInputOutput


print("------------------------------- /file ----------------------------------");
