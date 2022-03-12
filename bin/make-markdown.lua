#!/usr/bin/lua

local _G = _G;

_G.g = { -- g for "global"   g = _G.g
            FILES   = {},
            YAML    = {},
            bucket  = { BUILD = {}, CONTENT = {},
                        DIRS  = {}, ERR     = {},
                        FILES = {} },
            count   = { BUILD = 0,  DIRS    = 0,
                        ERR   = 0,  FILES   = 0, },
            outtxt  = {},
          };

g.FUNC = {}; -- functions

g.CONFIG      = {
  recipe      = "clu", -- specific to this project
  appname     = "make-markdown.lua",
  dir         = { bin    = "./bin", build  = "./build",
                  out    = "./out", recipe = "./recipes",
                  source = "./src",
                },
  errors      = true,
  ext         = { filter = ".md;.yaml",    markdown = ".md",
                  out    = ".md",          recipe   = ".rec",
                  source = "(.md|%.yaml)", yaml     = ".yaml",
                },
  ignore      = "(%.git|Makefile|%.test|%.|backup|markdown)",
  intro       = "intro",
  lsfmt       = "  %-30s %-20s",
  logfmt      = "  %-30s %-20s",
  maxerrors   = 2,
  outfile     = "build",
  src_in_comment = true,
  summary     = true,
  verbose     = true,
  yaml_ignore = "^(metadata|flat|%d+)"
};

require "func";
require "content";
require "modules";

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
      then for i, j in pairs(v)
           do  if type(i) == "string" then flat_tree[i] = j; end;
           end;
      end;
      flat_tree[k] = v;
  end;

  return flat_tree;

end;


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


local function yaml_char_group(bio_group_affiliation)
  local markdown = "";
  yprint("we have group affiliation");
  markdown = markdown .. "\n- **Group Affiliation:** ";
  local group_list = {};
  local group_memberships = unpack_yaml_tree(bio_group_affiliation, "group_memberships");

  if   bio_group_affiliation == "none"
  then table.insert(group_list, "*none*");
  else for group_name, data in pairs(group_memberships)
       do  local str = group_name
           local gstatus = unpack_yaml_tree(data, "gstatus");
           if   type(str) == "string" and gstatus
           then if   (gstatus.inactive or gstatus.reserve  or
                      gstatus.founder  or gstatus.resigned or
                      gstatus.expelled or gstatus.status
                     )
                  then local gdata = {};
                       if gstatus.founder  then table.insert(gdata, "*founding member*"); end;
                       if gstatus.inactive then table.insert(gdata, "*inactive*"       ); end;
                       if gstatus.resigned then table.insert(gdata, "*resigned*"       ); end;
                       if gstatus.reserve  then table.insert(gdata, "*reserve member*" ); end;
                       if gstatus.status   then table.insert(gdata, gstatus.status     ); end;

                       local memdata_string = table.concat(gdata, ", ");
                       str = str .. " (" .. memdata_string .. ")";
                end;
                table.insert(group_list, str);
           end; -- if type == string and
       end; -- for group_name, data
  end; -- if gstatus ~= "none"
  markdown = markdown .. table.concat(group_list, ", ");
  return markdown;
end;


local function yaml_char_relatives(bio_relatives)
  local markdown = "\n- **Known Relatives:** ";
  local relatives = unpack_yaml_tree(bio_relatives, "relatives");
  local rel_list = {};
  for rel_name, rel in pairs(relatives)
  do if   type(rel_name) == "string"
     then local rel_string = rel_name;
          local rel_data   = unpack_yaml_tree(rel, "yaml_char_relatives: rel");

          if   rel_data.gender
          then rel_string = rel_string .. "[]{.icon-" .. rel_data.gender .. "} ";
          end;

          if   rel_data.relationship or rel_data.deceased or rel_data.aka
          then rel_string = rel_string .. "(";
               if   rel_data.relationship
               then rel_string = rel_string .. rel_data.relationship;
                    if   rel_data.deceased or rel_data.aka
                    then rel_string = rel_string .. ", ";
                    end;
               end; -- if rel.relationship

               if rel_data.aka      then rel_string = rel_string .. rel_data.aka; end;
               if rel_data.deceased then rel_string = rel_string .. "*deceased*"; end;
               rel_string = rel_string .. ")";
          end; -- if rel[relationship, deceased, aka]
          table.insert(rel_list, rel_string);
     end;
  end; -- for rel.name
  markdown = markdown .. table.concat(rel_list, ", ");
  return markdown;
end;


local function yaml_char_picture(character_picture)
  local markdown = "";
  local picture = unpack_yaml_tree(character_picture, "picture");
  yprint("We have picture!");

  if   picture.alt and picture.url
  then markdown = markdown .. "![" .. picture.alt .. "]";
  else markdown = markdown .. "![]";
       yprint("We don't have picture alt text", ":(");
  end;

  if   picture.url
  then markdown = markdown .. "(" .. picture.url .. ")";
       yprint("We have picture url!", picture.url);
  else yprint("We don't picture have url :(");
  end;

  if   picture.anchor
  then markdown = markdown .. "{#" .. picture.anchor .. "}";
  end;

  return markdown;
end;


local function yaml_char_base(bio_base)
  if    type(bio_base) == "string" then return "\n- **Base of Operations:** " .. bio_base; end;
  local markdown  = "\n- **Base of Operations:** ";
  local base_list = {};
  local bases     = unpack_yaml_tree(bio_base, "base");
  for   base_name, base_data in pairs(bases)
  do  if     type(base_name) == "string" and type(base_data) == "string"
      then   table.insert(base_list, base_data);
      elseif type(base_name) == "string"
      then   local data    = unpack_yaml_tree(base_data, "base_data");
             local str     = base_name;
             local details = {};

             if #bases > 1 and data.active then table.insert(details, "current");                        end;
             if data.former                then table.insert(details, "formerly");                       end;
             if data.temporary             then table.insert(details, "temporarily");                    end;
             if data.status                then table.insert(details, data.status);                      end;
             if #details >= 1              then str = str .. " (" .. table.concat(details, ", ") .. ")"; end;

             table.insert(base_list, str);
      end;  -- if name == string
  end;
  markdown = markdown .. table.concat(base_list, "; ");
  return markdown;
end;


local function yaml_char_gender(bio_gender)
  local markdown = "";
  if     type(bio_gender) == "string"
  then   return "\n- **Gender:** " .. bio_gender;
  elseif type(bio_gender) == "table"
  then   yprint("we have gender!", "it's a table");
  end;
  local gender = unpack_yaml_tree(bio_gender, "gender");
  if    gender.desc     then markdown = markdown .. "\n- **Gender:** " .. gender.desc; end;
  if    gender.pronouns then markdown = markdown .. " (" .. gender.pronouns .. ")";    end;
  return markdown;
end;


local function yaml_char_power_words(stats_power_words)
  local markdown = "\n- **Power Words:**";
  local power_words = unpack_yaml_tree(stats_power_words, "power words");

  if   power_words.core
  then markdown = markdown .. "\n  - *Core:* " .. table.concat(power_words.core, ", ");
  else eprint("we don't have CORE power words", ":(");
  end;

  if   power_words.personal
  then markdown = markdown .. "\n  - *Personal:* " .. table.concat(power_words.personal, ", ");
  else eprint("we don't have PERSONAL power words", ":(");
  end;

  if   power_words.nova
  then markdown = markdown .. "\n  - *Nova:* " .. table.concat(power_words.nova, ", ");
  else eprint("we don't have NOVA power words", ":(");
  end;
  return markdown;
end;


local function yaml_sheet_approaches(sheet_approaches)
  local  approaches = unpack_yaml_tree(sheet_approaches, "sheet_approaches");
  if not approaches or not type(approaches) == "table" then return "" end;
  local  markdown = "";

  local function one_approach(a)
    if approaches[a]
    then markdown = markdown .. "\n[" .. approaches[a] .. "]{.pregen-facet ." .. a .. "}";
    end;
  end;

  one_approach("action");
  one_approach("adventure");
  one_approach("detective");
  one_approach("mystery");
  one_approach("suspense");

  return markdown;
end;

local function yaml_sheet_basics(sheet_stats)
  local  stats = unpack_yaml_tree(sheet_stats, "sheet_stats");
  if not stats or not type(stats) == "table" then return "" end;

  local markdown = "";

  if   stats.name and type(stats.name) == "string"
  then markdown = markdown .. "\n[" .. stats.name .. "]{.pregen-name}";
       vprint("sheet for " .. stats.name, "---------------------");
  end;

  if stats.class and type(stats.class) == "string"
  then markdown = markdown .. "\n[" .. stats.class .. "]{.pregen-class}";
  end;

  if stats.health and type(stats.health) == "number"
  then markdown = markdown .. "\n[" .. stats.health .. "]{.pregen-health}";
  end;

  if stats.might and type(stats.might) == "number"
  then markdown = markdown .. "\n[" .. stats.might .. "]{.pregen-might}";
  end;

  if   stats.fighting_style and type(stats.fighting_style) == "table"
  then local fighting_styles = unpack_yaml_tree(stats.fighting_style, "stats.fighting_style");
       for fs, fs_info in pairs(fighting_styles)
       do  local str = "\n[**" .. fs .. "**";
           if type(fs_info) == "table" and fs_info.desc and type(fs_info) == "string"
           then str = str .. " " .. fs_info.desc
           end;
           str = str .. "]";
           markdown = markdown .. str;
       end;
  end;

  if   stats.volume and type(stats.volume) == "number"
  then if stats.volume > 1
       then markdown = markdown .. "\n[" .. stats.volume .. "]{.pregen-volume .box .v1}";
       else markdown = markdown .. "\n[" .. stats.volume .. "]{.pregen-volume .box .v1 .higher}";
       end;
  else markdown = markdown .. "\n[]{.pregen-volume .box .v1}";
  end;

  if   stats.storyline and type(stats.storyline) == "string"
  then markdown = markdown .. "[" .. stats.storyline .. "]{.pregen-storyline}";
  end;

  return markdown;
end;


local function yaml_sheet_bio(bio)
  if not bio or not type(bio) == "table" then return ""; end;
  local markdown = "";

  if   bio.desc and type(bio.desc) == "string"
  then markdown = markdown .. "\n[" .. bio.desc .. "]{.pregen-bio}";
  end;

  if bio.gender and type(bio.gender) == "table"
  then local gender = unpack_yaml_tree(bio.gender, "bio.gender");
       if   gender.pronouns
       then markdown = markdown .. "\n[" .. gender.pronouns .. "]{.pregen-pronouns}";
       end; -- if pronouns
  end; -- if bio gender

  if   bio.name and bio.real_name and bio.name ~= bio.real_name
  then markdown = markdown .. "\n[" .. bio.real_name .. "]{.pregen-nickname}";
  end;
  return markdown;
end;


local function yaml_sheet_face(sheet_picture)
  if not sheet_picture or not type(sheet_picture) == "table" then return "" end;
  local markdown = "";
  if   sheet_picture.face and type(sheet_picture.face) == "string" and
       sheet_picture.alt  and type(sheet_picture.alt)  == "string"
  then markdown = markdown .. "![" .. sheet_picture.alt .. "](" .. sheet_picture.face .. "){.pregen-face} \\";
  end;

  return markdown;
end;


local function yaml_sheet_skills(stats_skills)
  if not sheet_skills or not type(sheet_skills) == "table" then return ""; end;
  local markdown = string.rep(":", 10) .. " pregen-skills " .. string.rep(":", 10);

  for _, skillname in ipairs(sheet_skills)
  do  markdown = markdown .. "\n[" .. skillname .. "]{.pregen-skill}";
  end;

  markdown = markdown .. string.rep(":", 30);
  return markdown
end;


local function yaml_sheet_power_words(stats_power_words)
  if not sheet_power_words or not type(stats_power_words) == "table" then return ""; end;
  local markdown = "";

  local function pw_category(cat)
    if   sheet_power_words[cat] and type(sheet_power_words[core]) == "table"
    then markdown = markdown .. string.rep(":", 10) .. " pregen-" .. cat .. " " .. string.rep(":", 10);
         local catwords = unpack_yaml_tree(sheet_power_words[cat]);
         for _, word in ipairs(catwords)
         do  markdown = markdown .. "\n[" .. word .. "]{.pregen-word}";
         end;
    else eprint("error! missing " .. cat .. " power words!");
         os.exit(1);
    end;
    markdown = markdown .. string.rep(":", 30);
  end;

  pw_category("core");
  pw_category("personal");
  pw_category("nova");

  return markdown
end;


local function yaml_sheet_abilities(stats_abilities)
  if not sheet_abilities or not type(stats_abilities) == "table" then return "" end;

  local markdown = "";

  for i, ability in ipairs(stats_abilities)
  do local ability_md = "";
     if     type(ability) == "string" and i == 1
     then   ability_md = ability_md .. "[**" .. ability .. "]{.pregen-ability-class}";
     elseif type(ability) == "table"
     then   local ability_data = unpack_yaml_tree(ability, "stats_ability : ability");
            if   type(i) == "string"
            then ability_md = ability_md .. "[**" .. i .. "**";
                 if   ability_data.desc and type(ability_data.desc) == "string"
                 then ability_md = ability_md .. ability_data.desc;
                 end; -- if type desc string
            end; -- if type i string
            if   ability_data.volume and type(ability_data.volume) == "number"
            then ability_md = ability_md .. "]{.pregen-ability-v" .. ability_data.volume .. "}";
            elseif ability_data.volume and type(ability_data.volume) == "string"
            then   ability_md = ability_md .. "]{.pregen-ability-" .. ability_data.volume .. "}";
           end; -- if ability_data.volume
     end; -- if type ability string
     markdown = markdown .. ability_md;
  end; -- for i, ability
  return markdown;
end;

local function yaml_sheet_ideals(stats_ideals, sheet_config)
  if not stats_ideals or not type(stat_ideals) == "table" then return "" end;
  local markdown = "";

  for i, ideal in pairs(stats_ideals)
  do  if   type(ideal) == "string"
      then markdown = markdown .. "\n[" .. ideal .. "]{.pregen-ideal .pregen-i" .. i;
          if     sheet_config.shrink and sheet_config.shrink["ideal" .. i]
           then   markdown = markdown .. " .shrink";
           elseif sheet_config["shrink2"] and sheet_config["shrink2"]["ideal" .. i]
           then   markdown = markdown .. " .shrink2";
          end;
          markdown = markdown .. "}";
      end;
  end;

  return markdown;
end;


local function yaml_sheet(yaml_tree)
  local sheet, _, _ = yaml_common(yaml_tree);
  if   not sheet or not type(sheet) == "table"
  then return "" end;

  local sheet_config = {};
  if   sheet["sheet-config"]
  then sheet_config = unpack_yaml_tree(sheet["sheet-config"], "sheet-config");
       yprint("found sheet-config!");
       yprint("::::::: start sheet-config ::::::::::");
       yprint(":::::::: end sheet-config :::::::::::");
       if   sheet_config.shrink
       then local shrink = unpack_yaml_tree(sheet_config.shrink, "sheet-config.shrink");
            sheet_config.shrink = shrink;
       end;
  end;

  local markdown = g.CONTENT.herosheet;

  markdown = markdown .. "\n\n" .. string.rep(":", 30) .. " pregen " .. string.rep(":", 30);

  if    not sheet.stats or not type(sheet.stats) == "table"
  then  markdown = markdown .. "\n\n" .. string.rep(":", 50);
        return markdown
  end;

  local stats = unpack_yaml_tree(sheet.stats, "sheet.stats");

  if    stats.approaches and type(stats.approaches) == "table"
  then  markdown = markdown .. yaml_sheet_approaches(stats.approaches, sheet_config);
  else  eprint("Error!", "no approaches");
        os.exit(1);
  end;

  markdown = markdown .. yaml_sheet_basics(stats, sheet_config);

  if     sheet.bio and type(sheet.bio) == "table"
  then   markdown = markdown .. yaml_sheet_bio(sheet.bio, sheet_config);
  end;

  if     sheet.art and type(sheet.art) == "table"
  then   vprint("we have art structure!", "yay!");
         markdown = markdown .. yaml_sheet_face(sheet.art, sheet_config);
  elseif sheet.art and type(sheet.art) == "string"
  then   vprint("we have art string!", sheet.art);
        markdown = markdown .. sheet.art
  elseif sheet.art
  then   eprint("i guess we have sheet.art", sheet.art);
  else   eprint("no art found!", sheet.name);
  end;

  if     stats.power_words and type(stats.power_words) == "table"
  then   markdown = markdown .. yaml_sheet_power_words(stats.power_words, sheet_config);
  else   eprint("Error!", "no power words");
         os.exit(1);
  end;

  if     stats.ideals and type(stats.ideals) == "table"
  then   markdown = markdown .. yaml_sheet_ideals(stats.ideals, sheet_config);
  elseif type(stats.ideals) == "string"
  then   local ideals_list = split(stats.ideals, ",");
         markdown = markdown .. yaml_sheet_ideals(ideals_list, sheet_config);
  end;

  markdown = markdown .. "\n\n" .. string.rep(":", 50);
  return markdown;
end;

local function yaml_character(yaml_tree)
  local character, metadata, markdown = yaml_common(yaml_tree);
  -- yprint("yaml xformat is:", "character");

  if   metadata
  then yprint("we have metadata!")
       if metadata.title  then markdown = markdown .. "# "  .. metadata.title;         end
       if metadata.anchor then markdown = markdown .. " {#" .. metadata.anchor .. "}"; end;
       markdown = markdown .. "\n\n";
  else eprint("we don't have metadata :(");
  end;

  if   character
  then yprint("we have character!")

       if   character.art -- and type(character.picture) == "table"
       then markdown = markdown .. yaml_char_picture(character.art);
       else yprint("We don't have picture :(");
       end; -- character.picture

       if   character.bio
       then yprint("We have bio!");

            markdown = markdown .. "\n" .. string.rep(":", 15) .. " {.bio} " ;
            markdown = markdown .. "\n" .. string.rep(":", 15) .. "\n";

            local bio = unpack_yaml_tree(character.bio, "bio");

            if   bio.real_name
            then markdown = markdown .. "\n- **Real Name:** "    .. bio.real_name;
            end;

            if   bio.occupation
            then markdown = markdown .. "\n- **Occupation:** "   .. bio.occupation;
            end;

            if   bio.legal_status
            then markdown = markdown .. "\n- **Legal Status:** " .. bio.legal_status;
            end;

            if   bio.gender
            then markdown = markdown .. yaml_char_gender(bio.gender);
            else eprint("we don't have gender :(");
            end;

            if   bio.identity
            then markdown = markdown .. "\n- **Identity:** "       .. bio.identity;
            end;

            if   bio.place_of_birth
            then markdown = markdown .. "\n- **Place of Birth:** " .. bio.place_of_birth;
            end;

            if   bio.marital_status
            then markdown = markdown .. "\n- **Marital Status:** " .. bio.marital_status;
            end;

            if     bio.known_relatives
            then   if     type(bio.known_relatives) == "table"
                   then   markdown = markdown .. yaml_char_relatives(bio.known_relatives);
                   elseif bio.known_relatives == "none"
                   then   markdown = markdown .. "\n- **Known Relatives:** none";
                   end;
            else   markdown = markdown .. "\n- **Known Relatives:** unknown";
            end;   -- bio.relatives

            if     bio.base and type(bio.base) == "table"
            then   markdown = markdown .. yaml_char_base(bio.base);
            elseif bio.base == "none" then markdown = markdown .. "\n- **Base of Operations:** none";
            end;   -- bio.base

            if     bio.group_affiliation and type(bio.group_affiliation) == "table"
            then   markdown = markdown .. yaml_char_group(bio.group_affiliation);
            elseif bio.group_affiliation == "none"
            then   markdown = markdown .. "\n- **Group Affiliation:** none";
            else   yprint("We don't have group affiliation");
            end;   -- bio.group_affiliation

            markdown = markdown .. "\n\n" .. string.rep(":", 50);

       else yprint("We don't have bio :(");
       end;

       if   character.history
       then yprint("we have history!");
            markdown = markdown .. "\n\n" .. "**History:**" .. "\n\n";
            markdown = markdown .. character.history;
       else yprint("we don't have history :(");
            os.exit(1);
       end;

       if   character.powers
       then yprint("we have powers!");
            markdown = markdown .. "\n\n" .. "**Powers:**" .. "\n\n";
            markdown = markdown .. character.powers;
       else yprint("we don't have powers :(");
       end;

       if   character.weapons
       then yprint("we have weapons!");
            markdown = markdown .. "\n\n" .. "**Weapons:**" .. "\n\n";
            markdown = markdown .. character.powers;
       else yprint("we don't have weapons :(");
       end;

       if   character.stats
       then yprint("we have stats!");

            markdown = markdown .. "\n\n" .. string.rep(":", 25);
            markdown = markdown .. " stats ";
            markdown = markdown .. string.rep(":", 20) .. "\n";

            local stats = unpack_yaml_tree(character.stats, "stats");

            if stats.name  then markdown = markdown .. "\n## " .. stats.name .. "\n\n";             end;
            if stats.class then markdown = markdown .. "- **" .. "Class:** " .. stats.class .. "\n" end;

            if   stats.volume and type(stats.volume) == "number" and stats.volume > 1
            then markdown = markdown .. "\n- **Volume:** " .. stats.volume .. g.CONTENT.higher_volume .. "\n";
            end;

            if   stats.approaches
            then yprint("We have approaches!");
                 local approach = unpack_yaml_tree(stats.approaches, "approaches");
                 markdown = markdown .. "- **Approaches:**";
                 if approach.action    then markdown = markdown ..  "\n  Action "    .. approach.action;    end;
                 if approach.adventure then markdown = markdown .. ",\n  Adventure " .. approach.adventure; end;
                 if approach.detective then markdown = markdown .. ",\n  Detective " .. approach.detective; end;
                 if approach.mystery   then markdown = markdown .. ",\n  Mystery "   .. approach.mystery;   end;
                 if approach.suspense  then markdown = markdown .. ",\n  Suspense "  .. approach.suspense;  end;
            else yprint("We don't have approaches :(");
            end;

            if stats.health then markdown = markdown .. "\n- **Health:** " .. stats.health; end;
            if stats.might  then markdown = markdown .. "\n- **Might:** "  .. stats.might;  end;

            if   stats.power_words and type(stats.power_words) == "table"
            then yprint("We have power words!");
                 markdown = markdown .. yaml_char_power_words(stats.power_words);
            else yprint("We don't have power words :(");
            end;

            if   stats.abilities and type(stats.abilities) == "table"
            then yprint("We have abilities!");
                 local abilities = unpack_yaml_tree(stats.abilities, "abilities");
                 markdown = markdown .. "\n- **Abilities:** ";
                 local ab_list = {};
                 for ab_name, ab_data in pairs(abilities)
                 do  yprint("ability:", "--------------");
                     yprint("ab_name", ab_name);
                     yprint("ab_data", ab_data);
                     yprint(ab_name, ab_data);
                     if     type(ab_name) == "string"
                     then   table.insert(ab_list, ab_name);
                     elseif type(ab_name) == "number" and type(ab_data) == "string"
                     then   table.insert(ab_list, ab_data);
                     end;
                 end;
                 markdown = markdown .. table.concat(ab_list, ", ");
            else yprint("we don't have abilities :(");
            end;

            if     stats.fighting_styles and type(stats.fighting_styles) == "table"
            then   yprint("We have fighting styles!");
                   local fighting_styles = unpack_yaml_tree(stats.fighting_styles, "fighting styles");
                   markdown = markdown .. "\n- **Fighting Styles:** " .. table.concat(fighting_styles, ", ");
            elseif stats.fighting_styles and type(stats.fighting_styles) == "string"
            then   vprint("we have fighting style(s?)", "as a string not table");
                   markdown = markdown .. "\n- **Fighting Styles:** " .. stats.fighting_styles;
            else   yprint("We don't have fighting styles :(");
            end;

            if     stats.skills and type(stats.skills) == "table"
            then   yprint("We have skills!");
                   local skills = unpack_yaml_tree(stats.skills, "skills");
                   markdown = markdown .. "\n- **Skills:** " .. table.concat(skills, ", ");
            elseif stats.skills and type(stats.skill) == "string"
            then   yprint("we have skill(s?)!");
                   markdown = markdown .. "\n-- **Skills:** " .. stats.skills;
            else   yprint("We don't have skills :(");
            end;

            if     stats.ideals and type(stats.ideals) == "table"
            then   yprint("we have ideals!");
                   local ideals = unpack_yaml_tree(stats.ideals, "ideals");
                   markdown = markdown .. "\n- **Ideals:** " .. table.concat(ideals, ", ");
            elseif stats.ideals and type(stats.ideals) == "string"
            then   markdown = markdown .. "\n- **Ideals:** " .. stats.ideals;
                   yprint("we have ideal(s?)!", "as a string");
            else   yprint("we don't have ideals", ":(");
            end;

            markdown = markdown .. "\n\n" .. string.rep(":", 50);

       else yprint("we don't have stats :(");
       end;

  else yprint("we don't have flat tree / character :(");
  end;

  markdown = markdown .. "\n\n" .. string.rep(":", 70);
  return markdown;

end;


local function get_item_formatter_func(metadata) -- Usage: local item_formatter, if_error = get_item_formatter_func(metadata);
  -- yprint("looking for item_formatter");
  if not metadata
  then   yprint("Error! Metadata", type(metadata));
         os.exit(1);
  end;

  local metadata_keys = get_alpha_keys(metadata);

  if     not metadata_keys
  then   yprint("MISSING: metadata_keys", metadata_keys);
  elseif not type(metadata_keys) == "table"
  then   yprint("NOT TABLE: type(metadata_keys)", type(metadata_keys));
         os.exit(1);
  end;

  local item_format = metadata and metadata["item-format"];

  if   not item_format
  then -- yprint("no item format?!", item_format);
       return g.YAML.unknown, true
  else -- yprint("YAY: found item format:", item_format);
  end;

  local item_formatter = g.YAML["item:" .. item_format];
  if   not item_formatter
  then -- yprint("no item formatter?! for ...", item_format);
       return g.YAML.unknown, true
  else -- yprint("YAY: found item formatter:", item_format);
  end;

  return item_formatter, false
end;


local function yaml_list(yaml_tree)
  -- yprint("yaml xformat is:", "list");
  local flat_tree, metadata, slurped = yaml_common(yaml_tree);
  local errors = 0;
  local order  = "alpha";
  if    metadata == {} then metadata = nil; end;

  if   metadata and metadata.title
  then slurped = slurped .. "# " .. metadata.title;
       if metadata.anchor then slurped = slurped .. " {#" .. metadata.anchor .. "}"; end;
       slurped = slurped .. "\n";
  else yprint("no title?!", "???");
       errors = errors + 1;
  end;

  if   metadata and metadata.text
  then slurped = slurped .. "\n\n" .. metadata.text .. "\n\n";
  end;

  if   metadata and metadata["list-class"]
  then slurped = slurped .. string.rep(":", 35);
       slurped = slurped .. metadata["list-class"];
       slurped = slurped .. string.rep(":", 35);
  else yprint("no list-class?", "???");
       errors = errors + 1;
  end;

  local item_format = metadata and metadata["item-format"];

  item_format = item_format and ("item:" .. item_format);

  if   item_format and g.YAML[item_format]
  then -- yprint("item format is ", item_format);
  else eprint("no item-format???!", "???");
       errors = errors + 1;
  end;

  local item_list = flat_tree.list;

  if   item_list
  then local numeric = false;
       if   metadata and  metadata.sort_field
       then order       = metadata.sort_field;
            -- eprint("we have a sort field", order);
            numeric = true;
       end;

       item_list  = unpack_yaml_tree(item_list, "item list");
       local keys = get_sorted_keys(item_list, order, numeric);
       local item_formatter, if_error = get_item_formatter_func(metadata);
       if   if_error
       then errors = errors + 1;
       else for _, k in pairs(keys)
            do  local data = item_list[k];
                local term = k;
                -- yprint("term is", k);
                if   not data
                then yprint("error: flat_tree[" .. k .. "]", "NOT EXIST");
                     errors = errors + 1;
                     break;
                end; -- not data

                if   data.definite
                then -- yprint("===================", "---------------------");
                     yprint("definite article on", term);
                     term = "The " .. term;
                     -- yprint("===================", "---------------------");
                end;

                slurped         = slurped .. "\n- **" .. term .. "**";
                local item_info = item_formatter(data);
                slurped         = slurped .. item_info;
            end; -- for pairs
       end;

       if   errors > 0
       then eprint("Errors!", errors);
       end; -- if errors
       slurped = slurped .. "\n\n" .. string.rep(":", 70) .. "\n\n";
       return slurped;

  end; -- if item_list
end; -- function


local function yaml_minor_character(yaml_tree)
  local char = unpack_yaml_tree(yaml_tree, "minor character");
  local slurped = "";
  if    char.gender
  then  slurped = slurped .. "[]{.icon-" .. char.gender .. "} ";
  end;
  if    char.bio
  then  slurped = slurped .. char.bio;
  end;
  if    char.cf and type(char.cf) ~= "table"
  then  if     type(char.cf) == "string"
        then   slurped = slurped .. " See *" .. char.cf .. "*";
        elseif type(char.cf) == "table"
        then   local char_cf = table.concat(char.cf, ", ");
               slurped = slurped .. " See *" .. char_cf .. "*";
        end;
  end; -- if char.cf table
  slurped = slurped .. "\n";
  return slurped;
end;


local function yaml_glossary(yaml_tree)
  local flat_tree, metadata, slurped = yaml_common(yaml_tree);
  -- yprint("yaml xformat is:", "=== GLOSSARY ===");
  -- yprint("number of entries:", #flat_tree);
  local keys = get_sorted_keys(flat_tree, "alpha");
  for _, k in pairs(keys)
  do  if   not flat_tree[k] then eprint("error: flat_tree[" .. k .. "]", "NOT EXIST"); os.exit(1); end;
      local term, data    = k, flat_tree[k];
      if   term ~= "metadata" and term ~= "flat"
      then local glossary_data =  unpack_yaml_tree(data, term);
           local generic_equiv =  glossary_data.generic_equiv;
           local def           =  glossary_data.def
           local hq_equiv      =  glossary_data.hq_equiv;

           if    type(hq_equiv) == "table"
           then  hq_equiv       =  unpack_yaml_tree(hq_equiv, term .. ".hq_equiv");
                 hq_equiv       =  hq_equiv.term;
           end;

           if    type(generic_equiv) == "table"
           then  generic_equiv  =  unpack_yaml_tree(generic_equiv, term .. ".generic_equiv");
                 generic_equiv  =  generic_equiv.term;
           end;

           if    def and type(def) == "string"
           then  slurped = slurped .. term .. "\n";
                 slurped = slurped .. ":   " .. def;
           else  yprint(term .. " means:", def);
           end;

           local  equivs = {};
           if hq_equiv      and type(hq_equiv) == "string"      then table.insert(equivs, "*" .. hq_equiv      .. g.CONTENT.in_hd);      end;
           if generic_equiv and type(generic_equiv) == "string" then table.insert(equivs, "*" .. generic_equiv .. g.CONTENT.in_generic); end;
           if     equivs ~= {}
           then   slurped = slurped .. "\n    (" .. table.concat(equivs, "; ") .. ")";
           elseif hq_equiv
           then   yprint("ERROR hq_equiv exists but is type",      type(hq_equiv));
                  os.exit(1);
           elseif generic_equiv
           then   eprint("ERROR generic_equiv exists but is type", type(generic_equiv));
                  os.exit(1);
           end;

           slurped = slurped .. "\n\n";
      else yprint("skipping metadata", "METADATA METADATA");
      end;
  end;
  slurped = slurped .. string.rep(":", 70) .. "\n\n";
  return slurped;
end;


local function yaml_pageref(entry)
  local slurped = "";
  local page = unpack_yaml_tree(entry);
  if    page.url
  then  if   page.main
        then slurped = slurped .. "[#" .. page.url .. "]{.index-entry .main}";
        else slurped = slurped .. "[#" .. page.url .. "]{.index-entry}";
        end;
  end;

  return slurped;
end;

local function yaml_index_entry(title, yaml_tree)
  -- yprint("yaml xformat is", "item: index entry");
  local entry   = unpack_yaml_tree(yaml_tree);
  local slurped = g.CONFIG.src_in_comment and "\n<!--\n" .. inspect(entry) .. "\n-->\n" or "";
  local parts   = {};

  if     not entry then return ""
  elseif not title then return ""
  else   slurped = slurped .. "\n- **" .. title .. "** ";
  end;

  if     entry.cf
  then   table.insert(parts, "[" .. entry.cf .. "]{.index-entry .xref}");
  elseif entry.url
  then   table.insert(parts, yaml_pageref(entry))
  elseif entry.family
  then   vprint("Found a family:", title);
         for memname, memdata in pairs(entry)
         do if type(memname) == "string" and type(memdata) == "table" and memname ~= "family"
            then table.insert(parts, "\n  - ");
                 local memdata_array = unpack_yaml_tree(memdata);
                 if memdata_array.url
                 then table.insert(parts, yaml_pageref(memdata_array));
                 end;
            end;
         end;
  end;

  slurped = slurped .. table.concat(parts, " ");
  return slurped;
end;


local function yaml_index(yaml_tree)
  local xfmt;
  -- yprint("yaml xformat is", "index");
  local index, meta= yaml_common(yaml_tree);

  local slurped = "";

  if   meta.title
  then yprint("Found list name", meta.title);
       slurped = slurped .. "# " .. meta.title;

       if   meta.anchor
       then vprint("Found list anchor", meta.anchor);
            slurped = slurped .. " []{#" .. meta.anchor .. "}";
       else eprint("Didn't find index anchor", "yaml_index");
       end;

       slurped = slurped .. "\n\n";

  else eprint("not found: list name", "yaml_index");
       os.exit(1);
  end;

  local list_class = meta["list-class"];

  if     list_class and type(list_class) == "string"
  then   yprint("found list class", list_class);
         slurped = slurped .. string.rep(":", 30) .. " { ." .. list_class .. " } " .. string.rep(":", 20) .. "\n\n";
  elseif list_class and type(list_class) == "table"
  then   local list_classes = "";
         for k, _ in pairs(list_class)
         do  list_classes = list_classes .. " .";
         end;
         yprint("found list classes", list_classes);
         slurped = slurped .. string.rep(":", 25) .. " { " .. list_classes .. " } " .. string.rep(":", 15) .. "\n\n";
  end;

  if   index.text
  then yprint("Found list description", index.text:len() .. " characters")
       slurped = slurped .. "\n\n" .. index.text .. "\n\n";
  else eprint("Can't find list desc", "yaml_index");

  end;

  if   index.list
  then yprint("Found list");
       local list = unpack_yaml_tree(index.list);

       if   meta["list-item"]
       then xfmt = meta["list-item"];
       else eprint("Error: no meta.list-item", "yaml_index");
       end;

       if   xfmt ~= "index-entry"
       then eprint("Error: meta.list-term isn't index-entry", xfmt);
            os.exit(1);
       end;

       for title, entry in pairs(list)
       do  if   type(title) == "string" and type(entry) == "table"
           then local entry_data = unpack_yaml_tree(entry);
                if   entry_data.url
                then print("item:" .. title, entry_data.url);
                     slurped = slurped .. yaml_index_entry(title, entry_data);
                else for k, v in pairs(entry_data)
                     do slurped = slurped .. yaml_index_entry(k, v);
                     end;
                end;
           end;
       end;
  else eprint("Not found: list", "yaml_index");
       os.exit(1);
  end;

  if list_class then slurped = slurped .. "\n\n" .. string.rep(":", 70); end;
  return slurped;
end;


local function yaml_place(yaml_tree)
  -- yprint("yaml xformat is:", "item:location");
  local slurped = "";
  local place = unpack_yaml_tree(yaml_tree);
  -- yprint("raw place data:", inspect(place));

  if   place.where
  then -- yprint("place.where", place.where);
       slurped = slurped.." *("..place.where..")* ";     
  end;
  if   place.desc 
  then -- yprint("place.desc",  place.desc );
       slurped = slurped..place.desc;                    
  end;

  if   place.cf   
  then -- yprint("place.cf",    place.cf   );
       slurped = slurped.."; also see *"..place.cf.. "*";
  end;

  if   g.CONFIG.src_in_comment
  then slurped = slurped .. "\n<!-- " .. inspect(yaml_tree) .. " -->\n";
  end;

  yprint("=========================", "-------------------------");
  return slurped;
end;


local function yaml_event(yaml_tree)
  local event = yaml_common(yaml_tree);
  local elist = {};

  local slurped = " ";

  event = unpack_yaml_tree(event);

  if event.where then table.insert(elist, " *" .. event.where .. "* <br/>"); end;
  if event.extra then table.insert(elist, event.extra); end;

  if   #elist > 1
  then slurped = slurped .. " (" .. table.concat(elist, "; ") .. ") ";
       elist = {};
  end;

  if event.desc  then table.insert(elist, event.desc                      ); end;
  if event.cf    then table.insert(elist, "<br/>See also: *" .. event.cf .. "*"); end;

  slurped = slurped .. table.concat(elist, " ") .. "\n";

  return slurped;
end;


local function yaml_group_item(yaml_tree)
  local group, _, slurped, _ = yaml_common(yaml_tree);
  local status = group.active    and " "
              or group.disbanded and " *defunct* "
              or " *status unknown* ";
  slurped = (slurped or "") .. status;

  if   group.bio
  then slurped = slurped .. group.bio;
  end;

  if   group.cf and type(group.cf) == "table"
  then slurped = slurped .. table.concat(group.cf, ", ");
  end;

  if   group.members and type(group.members) == "table"
  then local member_list = unpack_yaml_tree(group.members);
       -- pictures -------------------------------------------------------------------
       slurped = slurped .. "\n" .. string.rep(":", 25) .. " group-faces " .. string.rep(":", 25) .. "\n";
       for name, member in pairs(member_list)
       do  if member.face
           then -- -----------------------------------------------------------
                slurped = slurped           ..  "\n"                ..
                        string.rep(":", 20) ..  " member "          ..
                        string.rep(":", 20) ..  "\n";
                slurped = slurped           ..  "\n["               ..
                        name                ..  "]{.member-name}\n";
                slurped = slurped           ..  "\n"                ..
                        string.rep(":", 60) ..  "\n";
           end; -- if member.face --------------------------------------------
       end -- for name, member
       slurped = slurped .. "\n" .. string.rep(":", 70) .. "\n";
       -- end of pictures ------------------------------------------------------------

       slurped = slurped .. "; Members: ";
       local member_entries = {};
       local mem_item = "";
       if   not group["membership-complex"]
       then for name, member in pairs(member_list)
            do  local member_status  = member.active    and ""                           or
                                       member.resigned  and " *resigned* "               or
                                       member.deceased  and " *deceased* "               or
                                       member.expelled  and " *expelled* "               or
                                       member.graduated and " *graduated* "              or
				       member.status    and " *" .. member.status .. "*" or
                                       " *status unknown* ";
                if member.title        then mem_item = mem_item .. " " .. member.title;                 end;
                if name or member.name then mem_item = mem_item .. (name or member.name) .. " ";        end;
                if member.aka          then mem_item = mem_item .. " (" .. member.aka .. ")";           end;
                if member.gender       then mem_item = mem_item .. "[]{.icon-" .. member.gender .. "}"; end;
                if member_status       then mem_item = mem_item .. member_status;                       end;
                if member.bio          then mem_item = mem_item .. " " .. member.bio;                   end;
            end; -- for name, member
       else -- membership-complex
            for name, member in pairs(member_list)
            do  mem_item = mem_item .. name .. " ";
                local complex_status = member.active   and ""                           or
                                       member.honorary and " *honorary* "               or
                                       member.resigned and " *resigned* "               or
                                       member.defunct  and " *defunct* "                or
                                       member.inactive and " *inactive* "               or
                                       member.former   and " *former* "                 or
				       member.status   and " *" .. member.status .. "*" or
                                       member.expelled and " *expelled* "               or
                                       " *status unknown* ";
                if   complex_status then mem_item = mem_item .. complex_status; end;
                if   member.active and member.rep and type(member.rep) == "table"
                then local rep = unpack_yaml_tree(member.rep, "membership-complex : member.rep");
                     if   not string.match(rep.name, "none")
                     then if rep.active then mem_item = mem_item .. " [ represented by ";              end;
                          if rep.former then mem_item = mem_item .. " [ formerly represented by ";     end;
                          if rep.title  then mem_item = mem_item .. rep.title .. " ";                  end;
                          if rep.name   then mem_item = mem_item .. rep.name;                          end;
                          if rep.gender then mem_item = mem_item .. "[]{.icon-" .. rep.gender .. "}";  end;
                          if rep.aka    then mem_item = mem_item .. " (" .. rep.aka .. ") ";           end;
                          mem_item = mem_item .. "]";
                     else mem_item = mem_item .. " [ represented by: *no one* ]"
                     end; -- not rep.name none
                end; -- member.active and member.rep == table
            end; -- for name, member
       table.insert(member_entries, member_entry);
       slurped = slurped .. table.concat(member_entries, ", ");
       end; -- if not membership-complex
  end; -- if group.members
  return slurped;
end; -- function

g.YAML.character               = yaml_character;
g.YAML.list                    = yaml_list;
g.YAML.glossary                = yaml_glossary;
g.YAML.place                   = yaml_place;
g.YAML.group                   = yaml_group_item;
g.YAML.unknown                 = yaml_error;
g.YAML.index                   = yaml_index;
g.YAML["character-sheet"     ] = yaml_sheet;
g.YAML["item:minor-character"] = yaml_minor_character;
g.YAML["item:location"       ] = yaml_place;
g.YAML["item:group"          ] = yaml_group_item;
g.YAML["item:timeline-entry" ] = yaml_event;
g.YAML["item:index-entry"    ] = yaml_index_entry;

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

g.FUNC.file.dump       = dump;        -- func(filename, contents)
g.FUNC.file.map_src_fs = map_src_fs;  -- func(dir_src)
g.FUNC.file.search     = file_search;
g.FUNC.file.slurp      = slurp;
g.FUNC.file.slurp_yaml = slurp_yaml;  -- func(filename)

g.FUNC.line.mark_line_used = mark_line_used; -- func(line)
g.FUNC.line.was_used       = was_used_line;  -- func(line)

register_func_category("file");
register_func_category("line");

local function register_func(cat, name, func_func)
  if     not cat       then cat = "util"
  elseif not name      then eprint("Can't register " .. string.upper(cat) .. " func", name); os.exit();
  elseif not func_func then eprint("No func "        .. string.upper(cat) .. " func", name); os.exit();
  end;

  local  func_cat = FUNC[cat];
  if not func_cat then register_func_category(cat); func_cat = FUNC[cat]; end;

  vprint("Registering " .. string.upper(cat) .. " func", name);
  func_cat[name] = func_func;
end;

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
  register_func("util", name, func_func);
end;

register_util("register", register_util);

-- g.FUNC.util.register = register_util;
-- local function register_util(name, func_func)
--   if not name
--   then eprint("Error: no util name", name);
--        os.exit();
--   end;
--   if not func_func
--   then eprint("Error: no util func_func", name);
--        os.exit();
--   end;
--   vprint("Registering FUNC.util", name);
--   g.FUNC.util[name] = func_func;
-- end;

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
g.FUNC.register( "util" );
g.FUNC.register( "yaml" );

local UTIL = g.FUNC.util;

UTIL.register( "split"                    , split               );
UTIL.register( "ignore"                   , ignore              );
vprint(        "Registering *print utils" , string.rep("-", 20) );
UTIL.register( "eprint"                   , eprint              );
UTIL.register( "pprint"                   , pprint              );
UTIL.register( "sprint"                   , sprint              );
UTIL.register( "vprint"                   , vprint              );
UTIL.register( "yprint"                   , yprint              );

-- local function register_yaml_func(name, func_func)
--   if not g.FUNC.yaml then g.FUNC.yaml = {}; end;
--   if not name
--   then eprint("Error: no yamlfunc name", name);
--        os.exit();
--   end;
--   if not func_func
--   then eprint("Error: no yamlfunc func_func", name);
--        os.exit();
--   end;
-- 
--   vprint("Registering yamlfunc", name);
--   g.FUNC.yaml[name] = func_func;
-- end;

local function register_yaml_func(n, f_f) register_func("yaml", n, f_f); end;
register_yaml_func("register", register_yaml_func);

-- g.FUNC.yaml.register = register_yaml_func;

register_yaml_func("register"        , register_yaml_func );
register_yaml_func("common"          , yaml_common        );
register_yaml_func("error"           , yaml_error         );
register_yaml_func("get_alpha_keys"  , get_alpha_keys     );
register_yaml_func("get_sorted_keys" , get_sorted_keys    );
register_yaml_func("unpack_tree"     , unpack_tree        );

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
