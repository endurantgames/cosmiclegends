#!/usr/bin/lua

local CONFIG = {
  appname    = "make-markdown.lua",
  bin_dir    = "./bin",
  build_dir  = "./build",
  errors     = true,
  ext        = { markdown = ".md",     yaml     = ".yaml",
                 recipe   = ".recipe", filter   = ".md;.yaml"
               },
  ignore     = "^(%.git|Makefile|%.test|%.)",
  index      = "intro",
  logformat  = "  %-30s %-20s",
  out_suffix = ".md",
  outdir     = "./out",
  outfile    = "build",
  recipe     = "test",
  recipe_dir = "./",
  recipe_sfx = ".recipe",
  src_dir    = "./src",
  summary    = true,
  verbose    = true,
  yaml_ignore = "^(metadata|flat|%d+)",
  };

local lfs        = require "lfs"
local cli        = require "cliargs";
local lyaml      = require "lyaml";      -- https://github.com/gvvaughan/lyaml
local inspect    = require "inspect";    -- https://github.com/kikito/inspect.lua
-- local table_dump = require "table_dump"; -- https://github.com/suikabreaker/lua-table-dump
-- local dump       = require "lua-dump";   -- https://github.com/mah0x211/lua-dump

local function tprint(tbl, indent)
  indent = indent or 1;

  if   type(tbl) ~= "table"
  then print("Tprint Error: not a table");
       os.exit(1);
  end;

  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2
  for k, v in pairs(tbl)
  do  toprint = toprint .. string.rep(" ", indent)

      if     (type(k) == "number")
      then   toprint = toprint .. "[" .. k .. "] = "
      elseif (type(k) == "string")
      then   toprint = toprint  .. k ..  "= "
      end

      if     (type(v) == "number")
      then   toprint = toprint .. v .. ",\r\n"
      elseif (type(v) == "string")
      then   toprint = toprint .. "\"" .. v .. "\",\r\n"
      elseif (type(v) == "table")
      then   toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
      else   toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
      end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end

local function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s
   do    if s ~= 1 or cap ~= ""
         then table.insert(t,cap)
         end
         last_end = e+1
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
-- @param dir_path string (";" for multiple paths supported)
-- @param filter string - eg.: ".txt" or ".mp3;.wav;.flac"
-- @param s bool - search in subdirectories
-- @param pformat format of data - 'system' for system-dependent number; nil or string with formatting directives
-- @return  files, dirs - files and dir are tables {name, modification, path, size}

local function file_search(dir_path, filter, s, pformat)
  -- === Preliminary functions ===
  -- comparison function like the IN() function like SQLlite, item in a array
  -- useful for compair table for escaping already processed item
  -- Gianluca Vespignani 2012-03-03
        local c_in = function(value, tab)
                for k,v in pairs(tab) do
                        if v==value then
                                return true
                        end
                end
                return false
        end

        local string = string        -- http://lua-users.org/wiki/SplitJoin
        function string:split(sep)
                local sep, fields = sep or ":", {}
                local pattern = string.format("([^%s]+)", sep)
                self:gsub(pattern, function(c) fields[#fields+1] = c end)
                return fields
        end

        local ExtensionOfFile = function(filename)
                local rev = string.reverse(filename)
                local len = rev:find("%.")
                local rev_ext = rev:sub(1,len)
                return string.reverse(rev_ext)
        end

        -- === Init ===
        dir_path         = dir_path or cwd
        filter           = string.lower(filter) or "*"
        local extensions = split(filter, ";") -- filter:split(";")
        s = s or false -- as /s : subdirectories

       local os_date;

        if pformat == 'system' -- if 4th arg is explicity 'system', then return the
                             -- system-dependent number representing date/time
       then os_date = function(os_time) return os_time end
        else -- if 4th arg is nil use default, else it could be a string
            -- that respects the Time formatting directives
                pformat = pformat or "%Y/%m/%d" -- eg.: "%Y/%m/%d %H:%M:%S"
                os_date = function(os_time)
                        return os.date(pformat, os_time)
                end
        end

        -- == MAIN ==
        local files = {}
        local dirs = {}
        local paths = dir_path:split(";")
        for i,path in ipairs(paths) do
                for f in lfs.dir(path) do
                        if f ~= "." and f ~= ".." then
                                local attr = lfs.attributes ( path.."/"..f )
                                if attr.mode == "file" then
                                        if filter=="*"
                                        or c_in( string.lower( ExtensionOfFile(f) ), extensions)
                                        then
                                                table.insert(files,{
                                                        name = f,
                                                        modification = os_date(attr.modification) ,
                                                        path = path.."/",
                                                        size = attr.size
                                                })
                                        end
                                else
                                        if filter=="*" then                        -- if attr.mode == "directory" and file ~= "." and file ~= ".." then end
                                                table.insert(dirs,{
                                                        name = f ,
                                                        modification = os_date(attr.modification) ,
                                                        path = path.."/",
                                                        size = attr.size
                                                })
                                        end
                                        if s and attr.mode == "directory" then
                                                local subf, subd;
                                                subf, subd = file_search(path.."/"..f, filter, s, pformat)
                                                for i,v in ipairs(subf) do
                                                        table.insert(files,{
                                                                name = v.name ,
                                                                modification = v.modification ,
                                                                path = v.path,
                                                                size = v.size
                                                        })
                                                end
                                                for i,v in ipairs(subd) do
                                                        table.insert(dirs,{
                                                                name = v.name ,
                                                                modification = v.modification ,
                                                                path = v.path,
                                                                size = v.size
                                                        })
                                                end
                                        end
                                end
                        end
                end
        end
        return files,dirs
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

local function vprint(s, l) if CONFIG.verbose then print(string.format(CONFIG.logformat, s or "", l or "")) end; end;
local function eprint(s, l) if CONFIG.errors  then print(string.format(CONFIG.logformat, s or "", l or "")) end; end;
local function sprint(s, l) if CONFIG.summary then print(string.format(CONFIG.logformat, s or "", l or "")) end; end;

-- http://lua-users.org/wiki/FileInputOutput

local function slug(filename)
  filename = string.gsub(filename, "^%" .. CONFIG.src_dir, "");
  filename = string.gsub(filename, "%" .. CONFIG.ext.filter .. "$", "");
  filename = string.gsub(filename, "^/", "");
  filename = string.gsub(filename, "/$", "");
  return filename;
end;

local function path_level(path)
  path = slug(path);
  local pathdirs = split(path, "/");
  local level = #pathdirs;
  if   string.find(path, CONFIG.index)
  then vprint("*** found an index", path)
  else level = level + 1;
  end; -- if string.find
  return level;
end; -- function

local function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end -- function

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
local function slurp(file, no_parse)
  if not file_exists(file) then return nil end
  lines = {}
  for line in io.lines(file) do lines[#lines + 1] = line end
  local slurped = "\n" .. table.concat(lines, "\n") .. "\n";
  no_parse = no_parse
             or file:find(CONFIG.ext.yaml)
             or file:find(CONFIG.ext.recipe);

  if   not no_parse
  then -- normalize the number of octothorpes

       local octo, _ = string.match(slurped, "(#+)");
       local octo_level = string.len(octo or "");

       if   octo_level > 1
       then local mod = octo_level - 1;
            local oldhash = "\n" .. string.rep("#", mod);
            local newhash = "\n";
            slurped = string.gsub(slurped, oldhash, newhash);
       end; -- if octo_level

       local level = path_level(file);
       -- vprint(slug(file), "should be " .. level .. ", is " .. octo_level);
       if   level >= 1
       then local mod = level - 1;
            local oldhash = "\n#";
            local newhash = "\n#" .. string.rep("#", mod)
            slurped = string.gsub(slurped, oldhash, newhash);
            slurped = string.gsub(slurped, "\n#####+", "\n#####");
            -- handle the H6 headings
            slurped = string.gsub(slurped, "\n:#", "\n######");
       end; -- if level
  end; -- if not no_parse
  return slurped;
end -- function

local function unpack_yaml_tree(yaml_tree, comment)
  comment = comment or "";
  -- vprint("==================", "------------------");
  -- vprint(comment .. ":before", tprint(yaml_tree));
  if     yaml_tree == nil
  then   eprint("Error!", "yaml_tree = nil");
         os.exit(1);
  elseif yaml_tree and type(yaml_tree) ~= "table"
  then   eprint("Error! unpacking", "type(" .. comment .. ") = " .. type(yaml_tree));
         vprint("Should be:", "table");
         os.exit(1);
  elseif comment and type(comment) ~= "string"
  then   eprint("Error!", "type(" .. comment .. ") = " .. type(comment));
         vprint("Should be:", "string");
         os.exit(1);
  end;

  local flat_tree = {};

  for k, v in pairs(yaml_tree)
  do  if   type(v) == "table"
      then for i, j in pairs(v)
           do  if   type(i) == "string"
               then flat_tree[i] = j;
               end;
           end;
      end;
      flat_tree[k] = v;
  end;

  return flat_tree;

end;

local function get_sorted_keys(t)

  local function ignore_case(a, b)
    a = (a or "") .. "";
    b = (b or "") .. "";
    local aa = a:gsub("^The ","");
    local bb = b:gsub("^The ","");
    return string.lower(aa) < string.lower(bb);
  end;

  local keys = {}
  local n    = 0;
  for k, v in pairs(t)
  do  n       = n + 1;
      -- vprint("==============", "===============");
      if     type(k) == "string"
      then   keys[n] = k;
             table.insert(keys, k);
      end;
  end;
  table.sort(keys, ignore_case);
  return keys;
end;

local format_yaml     = {};

local function yaml_error(yaml_tree, unknown_xformat, filename, return_text)
  return_text = return_text == nil or return_text;
  eprint("Unknown xformat:", unknown_xformat);
  eprint("> in file:", filename);
  if return_text then return "" else return {} end;
end;

local function yaml_common(yaml_tree, slurped)
  local common_error;
  slurped = slurped or "\n\n";
  local flat_tree = unpack_yaml_tree(yaml_tree, "yaml_common") or {};
  local metadata;

  if   flat_tree.metadata
  then metadata = unpack_yaml_tree(flat_tree.metadata, "yaml_common : metadata") or {};
  else metadata = nil;
       common_error = true
  end;

  return yaml_tree, metadata, slurped, common_error;
end;

local function yaml_char_group(bio_group_affiliation)
  local markdown = "";
  -- vprint("we have group affiliation");
  markdown = markdown .. "\n- **Group Affiliation:** ";
  local group_list = {};
  local group_memberships = unpack_yaml_tree(bio_group_affiliation, "group_memberships");
  for group_name, data in pairs(group_memberships)
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
      end;
  end;
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
  -- vprint("We have picture!");
  if   picture.alt and picture.url
  then markdown = markdown .. "![" .. picture.alt .. "]";
  else markdown = markdown .. "![]";
       eprint("We don't have picture alt text", ":(");
  end;

  if   picture.url
  then markdown = markdown .. "(" .. picture.url .. ")";
       -- vprint("We have picture url!", picture.url);
  else eprint("We don't picture have url :(");
  end;
  return markdown;
end;

local function yaml_char_base(bio_base)
  if type(bio_base) == "string" then return "\n- **Base of Operations:** " .. bio_base; end;
  local markdown  = "\n- **Base of Operations:** ";
  local base_list = {};
  local bases     = unpack_yaml_tree(bio_base, "base");
  for base_name, base_data in pairs(bases)
  do  if     type(base_name) == "string" and type(base_data) == "string"
      then   table.insert(base_list, base_data);
      elseif type(base_name) == "string"
      then   local data         = unpack_yaml_tree(base_data, "base_data");
             local str          = base_name;
             local base_details = {};

             if   #bases > 1 and data.active
             then table.insert(base_details, "current");
             end;

             if   data.former
             then table.insert(base_details, "formerly");
             end;

             if   data.temporary
             then table.insert(base_details, "temporarily");
             end;

	     if   data.status
             then table.insert(base_details, data.status);
             end;

	     if   #base_details >= 1
             then str = str .. " (" .. table.concat(base_details, ", ") .. ")";
             end;

             table.insert(base_list, str);
      end;
  end;
  markdown = markdown .. table.concat(base_list, "; ");
  return markdown;
end;

local function yaml_char_gender(bio_gender)
  local markdown = "";
  if     type(bio_gender) == "string"
  then   return "\n- **Gender:** " .. bio_gender;
  -- elseif type(bio_gender) == "table"
  -- then   vprint("we have gender!", "it's a table");
  end;
  local gender = unpack_yaml_tree(bio_gender, "gender");
  if gender.desc     then markdown = markdown .. "\n- **Gender:** " .. gender.desc; end;
  if gender.pronouns then markdown = markdown .. " (" .. gender.pronouns .. ")";    end;
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

  if stats.fighting_style and type(stats.fighting_style) == "table"
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
  then markdown = markdown .. "\n[" .. stats.volume .. "]{.pregen-volume .box .v1}";
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
       vprint("found sheet-config!");
       vprint("::::::: start sheet-config ::::::::::");
       -- vprint(inspect(sheet_config));
       vprint(":::::::: end sheet-config :::::::::::");
       if sheet_config.shrink
       then local shrink = unpack_yaml_tree(sheet_config.shrink, "sheet-config.shrink");
            sheet_config.shrink = shrink;
       end;
  end;

  local markdown = [===[
:::::::::::::::::::::::::::: {.herosheet} :::::::::::::::::::::::::::::::::
[Hero Sheet]{#anchor-herosheet .anchor}

![Cosmic Legends of the Universe](art/clu-logo-black-medium.png){.clu-logo} \

![Driven by Harmony](art/DrivenByHarmonyLogo.png){.hd-logo} \

[A.K.A.]{.label .nickname}
[Name]{.label .name}
[Pronouns]{.label .pronouns}
[Max]{.label .health-max}
[Max]{.label .might-max}
[Class]{.label .class}
[Nova Power Words]{.label .nova}
[Core Power Words]{.label .core}
[Personal Power Words]{.label .personal}
[Class Ability]{.label .class-ability}
[Skills]{.label .skills}
[Fighting Styles]{.label .fighting-styles}
[Volume 1 Ability]{.label .volume-ability .v1}

[Health]{.label .health}
[Might]{.label .might}

[Volume]{.label .volume}
[]{.box .b5 .volume-boxes}
[]{.box .b1 .motiv .m1}
[]{.box .b1 .motiv .m2}
[]{.box .b1 .motiv .m3}
[]{.box .b1 .motiv .m4}
[]{.box .b1 .motiv .m5}
[Ideal]{.label .motiv .m1}
[Ideal]{.label .motiv .m2}
[Ideal]{.label .motiv .m3}
[Ideal]{.label .motiv .m4}
[Ideal]{.label .motiv .m5}
[]{.box .b1 .nova-unlocked}
[Unlocked]{.label .nova-unlocked}
[]{.box .b1 .arc-complete}
[Completed]{.label .arc-complete}

[Volume 2 Ability]{.label .volume-ability .v2}
[Volume 3 Ability]{.label .volume-ability .v3}
[Volume 4 Ability]{.label .volume-ability .v4}
[Volume 5 Ability]{.label .volume-ability .v5}

[Appearance]{.label .bio}
[Storyline]{.label .story-arc}

[Action]{.label .facet .action}
[Adventure]{.label .facet .adventure}
[Detective]{.label .facet .detective}
[Mystery]{.label .facet .mystery}
[Suspense]{.label .facet .suspense}

[Goals ]{.goal .label .g0}
[Smash ]{.goal .label .g1}
[Outwit]{.goal .label .g2}
[Allay ]{.goal .label .g3}
[Rescue]{.goal .label .g4}

[Symbol]{.label .symbol}

[Ethos            ]{.label .ethos .e0}
[Self Expression  ]{.label .ethos .e1}
[Teamwork         ]{.label .ethos .e2}
[Difficult Choices]{.label .ethos .e3}

[Retcon             ]{.safety .label .s1}
[Continued Next Page]{.safety .label .s2}
[Meanwhile, ...     ]{.safety .label .s3}
[Later That Day, ...]{.safety .label .s4}

[Driven by Harmony logo &copy; Cat McDonald, used with permission.]{.hd-logo-copy}

[Crisis Countdown           ]{.label .crisis .c0}
[5. Set the Scene           ]{.label .crisis .c5}
[4. Hero Roll-Call          ]{.label .crisis .c4}
[3. Define the Goals        ]{.label .crisis .c3}
[2. Assemble Teamwork Pool  ]{.label .crisis .c2}
[1. Crisis Begins!          ]{.label .crisis .c1}
[Hero Turn                  ]{.label .crisis .cht}
[Crisis Turn                ]{.label .crisis .cct}
[Post-Crisis                ]{.label .crisis .cpost}

[Hero Turn                  ]{.label .action .aht}
[General Alert              ]{.label .action .a1}
[Timely Arrival             ]{.label .action .a2}
[Advance a Goal             ]{.label .action .a3}
[Join a Power Combo         ]{.label .action .a4}
[Add to Teamwork Pool       ]{.label .action .a5}
[Crisis Turn                ]{.label .action .act}
[Take the Hit               ]{.label .action .a6}
[Counter a Crisis Effect    ]{.label .action .a7}

]===];

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
  -- vprint("yaml xformat is:", "character");

  if   metadata
  then -- vprint("we have metadata!")
       if metadata.title  then markdown = markdown .. "# "  .. metadata.title;         end
       if metadata.anchor then markdown = markdown .. " {#" .. metadata.anchor .. "}"; end;
       markdown = markdown .. "\n\n";
  else vprint("we don't have metadata :(");
  end;

  if   character
  then -- vprint("we have character!")

       if   character.art -- and type(character.picture) == "table"
       then markdown = markdown .. yaml_char_picture(character.art);
       else eprint("We don't have picture :(");
       end; -- character.picture

       if   character.bio
       then -- vprint("We have bio!");

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
                   -- eprint("relatives not parsing");
                   -- eprint("value:",      bio.known_relatives);
                   -- eprint("value type:", type(bio.known_relatives));

                   -- if   type(bio.known_relatives) == "table"
                   -- then eprint("dump:",       tprint(bio.known_relatives));
                   -- end;

            end;   -- bio.relatives

            if     bio.base and type(bio.base) == "table"
            then   markdown = markdown .. yaml_char_base(bio.base);
            elseif bio.base == "none" then markdown = markdown .. "\n- **Base of Operations:** none";
            end;   -- bio.base

            if     bio.group_affiliation and type(bio.group_affiliation) == "table"
            then   markdown = markdown .. yaml_char_group(bio.group_affiliation);
            elseif bio.group_affiliation == "none"
            then   markdown = markdown .. "\n- **Group Affiliation:** none";
            else   eprint("We don't have group affiliation");
            end;   -- bio.group_affiliation

            markdown = markdown .. "\n\n" .. string.rep(":", 50);

       else eprint("We don't have bio :(");
       end;

       if   character.history
       then -- vprint("we have history!");
            markdown = markdown .. "\n\n" .. "**History:**" .. "\n\n";
            markdown = markdown .. character.history;
       else eprint("we don't have history :(");
            os.exit(1);
            -- local sheet, metadata, markdown = yaml_common(yaml_tree);
            -- return markdown;
       end;

       if   character.powers
       then -- vprint("we have powers!");
            markdown = markdown .. "\n\n" .. "**Powers:**" .. "\n\n";
            markdown = markdown .. character.powers;
       else eprint("we don't have powers :(");
            os.exit(1);
       end;

       if   character.weapons
       then -- vprint("we have weapons!");
            markdown = markdown .. "\n\n" .. "**Weapons:**" .. "\n\n";
            markdown = markdown .. character.powers;
       else -- vprint("we don't have weapons :(");
       end;

       if   character.stats
       then -- vprint("we have stats!");

            markdown = markdown .. "\n\n" .. string.rep(":", 25);
            markdown = markdown .. " stats ";
            markdown = markdown .. string.rep(":", 20) .. "\n";

            local stats = unpack_yaml_tree(character.stats, "stats");

            if stats.name  then markdown = markdown .. "\n## " .. stats.name .. "\n\n";             end;
            if stats.class then markdown = markdown .. "- **" .. "Class:** " .. stats.class .. "\n" end;

            if   stats.approaches
            then -- vprint("We have approaches!");
                 local approach = unpack_yaml_tree(stats.approaches, "approaches");
                 markdown = markdown .. "- **Approaches:**";
                 if approach.action    then markdown = markdown ..  "\n  Action "    .. approach.action;    end;
                 if approach.adventure then markdown = markdown .. ",\n  Adventure " .. approach.adventure; end;
                 if approach.detective then markdown = markdown .. ",\n  Detective " .. approach.detective; end;
                 if approach.mystery   then markdown = markdown .. ",\n  Mystery "   .. approach.mystery;   end;
                 if approach.suspense  then markdown = markdown .. ",\n  Suspense "  .. approach.suspense;  end;
            else vprint("We don't have approaches :(");
            end;

            if stats.health then markdown = markdown .. "\n- **Health:** " .. stats.health; end;
            if stats.might  then markdown = markdown .. "\n- **Might:** "  .. stats.might;  end;

            if   stats.power_words and type(stats.power_words) == "table"
            then -- vprint("We have power words!");
                 markdown = markdown .. yaml_char_power_words(stats.power_words);
            else eprint("We don't have power words :(");
            end;

            if   stats.abilities and type(stats.abilities) == "table"
            then -- vprint("We have abilities!");
                 local abilities = unpack_yaml_tree(stats.abilities, "abilities");
                 markdown = markdown .. "\n- **Abilities:** ";
                 local ab_list = {};
                 for ab_name, ab_data in pairs(abilities)
                 do  -- vprint("ability:", "--------------");
                     -- vprint("ab_name", ab_name);
                     -- vprint("ab_data", ab_data);
                     -- vprint(ab_name, ab_data);
                     if     type(ab_name) == "string"
                     then   table.insert(ab_list, ab_name);
                     elseif type(ab_name) == "number" and type(ab_data) == "string"
                     then   table.insert(ab_list, ab_data);
                     end;
                 end;
                 markdown = markdown .. table.concat(ab_list, ", ");
            else eprint("we don't have abilities :(");
            end;

            if   stats.fighting_styles and type(stats.fighting_styles) == "table"
            then -- vprint("We have fighting styles!");
                 local fighting_styles = unpack_yaml_tree(stats.fighting_styles, "fighting styles");
                 markdown = markdown .. "\n- **Fighting Styles:** " .. table.concat(fighting_styles, ", ");
            elseif stats.fighting_styles and type(stats.fighting_styles) == "string"
            then   vprint("we have fighting style(s?)", "as a string not table");
                   markdown = markdown .. "\n- **Fighting Styles:** " .. stats.fighting_styles;
            else   eprint("We don't have fighting styles :(");
            end;

            if     stats.skills and type(stats.skills) == "table"
            then   -- vprint("We have skills!");
                   local skills = unpack_yaml_tree(stats.skills, "skills");
                   markdown = markdown .. "\n- **Skills:** " .. table.concat(skills, ", ");
            elseif stats.skills and type(stats.skill) == "string"
            then   -- vprint("we have skill(s?)!");
                   markdown = markdown .. "\n-- **Skills:** " .. stats.skills;
            else   eprint("We don't have skills :(");
            end;

            if     stats.ideals and type(stats.ideals) == "table"
            then   -- vprint("we have ideals!");
                   local ideals = unpack_yaml_tree(stats.ideals, "ideals");
                   markdown = markdown .. "\n- **Ideals:** " .. table.concat(ideals, ", ");
            elseif stats.ideals and type(stats.ideals) == "string"
            then   markdown = markdown .. "\n- **Ideals:** " .. stats.ideals;
                   vprint("we have ideal(s?)!", "as a string");
            else   eprint("we don't have ideals", ":(");
            end;

            markdown = markdown .. "\n\n" .. string.rep(":", 50);

       else eprint("we don't have stats :(");
       end;

  else eprint("we don't have flat tree / character :(");
  end;

  markdown = markdown .. "\n\n" .. string.rep(":", 70);
  return markdown;

end;

local function get_item_formatter_func(metadata)
  -- Usage:
  -- local item_formatter, if_error = get_item_formatter_func(metadata);
  --
  -- vprint("looking for item_formatter");
  if not metadata
  then   eprint("Error! Metadata", type(metadata));
         os.exit(1);
  end;

  local metadata_keys = get_sorted_keys(metadata);

  if     not metadata_keys
  then   eprint("MISSING: metadata_keys", metadata_keys);
  elseif not type(metadata_keys) == "table"
  then   eprint("NOT TABLE: type(metadata_keys)", type(metadata_keys));
         os.exit(1);
  end;
  -- vprint("metadata keys", inspect(metadata_keys));

  local item_format = metadata and metadata["item-format"];

  if   not item_format
  then eprint("no item format?!", item_format);
       return format_yaml.unknown, true
  else vprint("YAY: found item format:", item_format);
  end;

  local item_formatter = format_yaml["item:" .. item_format];
  if   not item_formatter
  then eprint("no item formatter?! for ...", item_format);
       return format_yaml.unknown, true
  else vprint("YAY: found item formatter:", item_format);
  end;

  return item_formatter, false
end;

local function yaml_list(yaml_tree)
  vprint("yaml xformat is:", "list");
  local flat_tree, metadata, slurped = yaml_common(yaml_tree);
  local errors = 0;
  if metadata == {} then metadata = nil; end;

  if   metadata and metadata.title
  then slurped = slurped .. "# " .. metadata.title;
       if metadata.anchor then slurped = slurped .. " {#" .. metadata.anchor .. "}"; end;
       slurped = slurped .. "\n";
  else eprint("no title?!", "???");
       errors = errors + 1;
  end;

  if   metadata and metadata.text
  then slurped = slurped .. "\n\n" .. metadata.text .. "\n\n";
  end;

  if   metadata and metadata["list-class"]
  then slurped = slurped .. string.rep(":", 35);
       slurped = slurped .. metadata["list-class"];
       slurped = slurped .. string.rep(":", 35);
  else eprint("no list-class?", "???");
       errors = errors + 1;
  end;

  local item_format = metadata and metadata["item-format"];

  item_format = item_format and ("item:" .. item_format);

  if   item_format and format_yaml[item_format]
  then vprint("item format is ", item_format);
  else eprint("no item-format???!", "???");
       errors = errors + 1;
  end;

  local item_list = flat_tree.list;

  if   item_list
  then -- vprint("found the items list", item_list);
       item_list  = unpack_yaml_tree(item_list, "item list");
       local keys = get_sorted_keys(item_list);
       local item_formatter, if_error = get_item_formatter_func(metadata);
       if   if_error
       then errors = errors + 1;
       else -- vprint("keys:", inspect(keys));
            for _, k in pairs(keys)
            do  local data = item_list[k];
                local term = k;
                -- vprint("term is", k);
                if   not data
                then eprint("error: flat_tree[" .. k .. "]", "NOT EXIST");
                     errors = errors + 1;
                     break;
                end; -- not data

                if   data.definite
                then -- vprint("===================", "---------------------");
                     -- vprint("definite article on", term);
                     term = "The " .. term;
                     -- vprint("===================", "---------------------");
                end;
                slurped         = slurped .. "\n- **" .. term .. "**";
                local item_info = item_formatter(data);
                -- vprint("defined list entry " .. term, item_info);
                -- if   not item_info
                -- then eprint("***** start *****", "******************");
                     -- vprint("item_info is nil for", term);
                     -- vprint(term, inspect(item_info));
                     -- eprint("*****************", "******** end *****");
                -- end;
		-- vprint("item_info is...", inspect(item_info));
                slurped         = slurped .. item_info;
            end; -- for pairs
       -- else eprint("no item list?!", "???");
       --      errors = errors + 1;
       end;

       if   errors > 0
       then eprint("Errors!", errors);
            -- os.exit(1);
       end; -- if errors
       slurped = slurped .. "\n\n" .. string.rep(":", 70) .. "\n\n";
       return slurped;

  end; -- if item_list
end; -- function

local function yaml_minor_character(yaml_tree)
  local char = unpack_yaml_tree(yaml_tree, "minor character");
  local slurped = "";
  if   char.gender
  then slurped = slurped .. "[]{.icon-" .. char.gender .. "} ";
  end;
  if   char.bio
  then slurped = slurped .. char.bio;
  end;
  if   char.cf and type(char.cf) ~= "table"
  then if     type(char.cf) == "string"
       then   slurped = slurped .. " See *" .. char.cf .. "*";
       elseif type(char.cf) == "table"
       then   local char_cf = table.concat(char.cf, ", ");
              slurped = slurped .. " See *" .. char_cf .. "*";
       end;

  end;
  slurped = slurped .. "\n";
  return slurped;
end;

local function yaml_glossary(yaml_tree)
  -- local yaml_tree, slurped, metadata = yaml_common(yaml_tree);
  -- local flat_tree = unpack_yaml_tree(yaml_tree, "yaml_tree");
  local flat_tree, _, slurped = yaml_common(yaml_tree);
  vprint("yaml xformat is:", "=== GLOSSARY ===");
  vprint("number of entries:", #flat_tree);
  local keys = get_sorted_keys(flat_tree);
  vprint("keys:", inspect(keys));
  for _, k in pairs(keys)
  do  -- if k == tonumber(k) then k = tonumber(k) + 0; end;

      vprint("type(" .. k ..")", type(k));
      if   not flat_tree[k]
      then eprint("error 545: flat_tree[" .. k .. "]", "NOT EXIST");
           os.exit(1);
      end;
      local term, data    = k, flat_tree[k];
      if   term ~= "metadata" and term ~= "flat"
      then
           vprint("term", term);
           local glossary_data =  unpack_yaml_tree(data, term);
           local def           =  glossary_data.def
           local hq_equiv      =  glossary_data.hq_equiv;
           if   type(hq_equiv) == "table"
           then hq_equiv       =  unpack_yaml_tree(hq_equiv, term .. ".hq_equiv");
                hq_equiv       =  hq_equiv.term; end;
           local generic_equiv =  glossary_data.generic_equiv;
           if   type(generic_equiv) == "table"
           then generic_equiv  =  unpack_yaml_tree(generic_equiv, term .. ".generic_equiv");
                generic_equiv  =  generic_equiv.term;
           end;
           if   def and type(def) == "string"
           then vprint(term, def);
                vprint("term", type(term));
                vprint("def", type(def));
                vprint(term .. " means:", def);
                slurped = slurped .. term .. "\n";
                slurped = slurped .. ":   " .. def;
           end;
           if     (hq_equiv and type(hq_equiv) == "string") and
                  (generic_equiv and type(generic_equiv) == "string")
           then   slurped = slurped .. "\n    (";
                  slurped = slurped .. "*" .. hq_equiv .. "* in Harmony Drive";
                  slurped = slurped .. "; *" .. generic_equiv .. "* in general TRPG terminology)";

           elseif hq_equiv and type(hq_equiv) == "string"
           then   slurped = slurped .. "\n    (*" .. hq_equiv .. "* in Harmony Drive.)\n\n";
           elseif generic_equiv and type(generic_equiv) == "string"
           then   slurped = slurped .. "\n    (*" .. generic_equiv .. "* in general TRPG terminology.)";
           elseif hq_equiv
           then   eprint("ERROR hq_equiv exists but is", type(hq_equiv));
                  os.exit(1);
           elseif generic_equiv
           then   eprint("ERROR generic_equiv exists but is", type(generic_equiv));
                  os.exit(1);
           end;

           slurped = slurped .. "\n\n";
      else vprint("skipping metadata", "METADATA METADATA");
      end;
  end;
  slurped = slurped .. string.rep(":", 70) .. "\n\n";
  return slurped;
end;

local function yaml_index_entry(yaml_tree)
  vprint("yaml xformat is", "item: index entry");

end;

local function yaml_index(yaml_tree)
  vprint("yaml xformat is", "index");
  local index, _, slurped = yaml_common(yaml_tre);
  if index.list
  then vprint("Found list");
  else eprint("Not found: list", "yaml_index");
       local list = unpack_yaml_tree(index.list);
       for k, v in pairs(list)
       do  print("item:", k);
       end;
  end;
end;

local function yaml_place(yaml_tree)
  vprint("yaml xformat is:", "item:location");
  local place, _, slurped = yaml_common(yaml_tree);
  if   place.where
  then vprint("place.where", place.where);
       slurped = slurped .. " (*" .. place.where .. "*)";
  end;
  if   place.bio
  then vprint("place.bio", place.bio);
       slurped = slurped .. place.bio
  end;
  if   place.cf
  then vprint("place.cf", place.cf);
       slurped = slurped .. "; also see *" .. place.cf .. "*";
  end;
  vprint("place data: ", slurped);
  return slurped;
end;

local function yaml_event(yaml_tree)
  -- vprint("yaml xformat is:", "item:event");
  local event = yaml_common(yaml_tree);
  local elist = {};

  local slurped = " ";

  event = unpack_yaml_tree(event);

  if event.where then table.insert(elist, event.where); end;
  if event.extra then table.insert(elist, event.extra); end;

  if   #elist > 1
  then slurped = slurped .. " (" .. table.concat(elist, "; ") .. ") ";
       elist = {};
  end;

  if event.desc  then table.insert(elist, event.desc                      ); end;
  if event.cf    then table.insert(elist, "See also: *" .. event.cf .. "*"); end;

  slurped = slurped .. table.concat(elist, " ") .. "\n";

  return slurped;
end;

local function yaml_group(yaml_tree)
  -- vprint("yaml xformat is:", "item:group");
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
       slurped = slurped .. "; Members: ";
       local member_entries = {};
       local mem_item = "";
       if   not group["membership-complex"]
       then for name, member in pairs(member_list)
            do  local member_status  = member.active    and "" or              member.resigned and " *resigned* " or
                                       member.deceased  and " *deceased* "  or member.expelled and " *expelled* " or
                                       member.graduated and " *graduated* " or " *status unknown* ";
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
                local complex_status = member.active   and ""             or member.honorary and " *honorary* " or
                                       member.resigned and " *resigned* " or member.defunct  and " *defunct* "  or
                                       member.inactive and " *inactive* " or member.former   and " *former* "   or
                                       member.expelled and " *expelled* " or " *status unknown* ";
                if   complex_status
                then mem_item = mem_item .. complex_status;
                end;
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

format_yaml.character               = yaml_character;
format_yaml.list                    = yaml_list;
format_yaml.glossary                = yaml_glossary;
format_yaml.place                   = yaml_place;
format_yaml.group                   = yaml_group;
format_yaml.unknown                 = yaml_error;
format_yaml["character-sheet"]      = yaml_sheet;
format_yaml["item:minor-character"] = yaml_minor_character;
format_yaml["item:location"]        = yaml_place;
format_yaml["item:group"]           = yaml_group;
format_yaml["item:timeline-entry"]  = yaml_event;

local function slurp_yaml(filename)

  if   not filename
  then eprint("Unknown yaml file location", filename);
       os.exit(1);
  end;

  local yaml_source = slurp(filename, true);

  local yaml_size = yaml_source:len() .. " bytes";

  -- vprint("Reading YAML file now", yaml_size);

  local yaml_tree, metadata = {}, {};
  local success, xformat;

  if   yaml_source
  then vprint("size of yaml_source", yaml_size);
       success = true;
  end;

  if   type(yaml_source) == "string"
  then
       -- vprint("Successfully read YAML file:", filename);
       -- vprint("YAML source size",             yaml_size);
       -- vprint("Attempting to parse",          yaml_size);
       yaml_tree = lyaml.load(yaml_source);
  else eprint("Couldn't read yaml:",          filename);
       success = false;
  end;

  if   success and yaml_tree and yaml_tree ~= {}
  then -- vprint("Successfully parsed ", filename .. " to yaml_tree");
  else eprint("Couldn't parse yaml:", filename);
       success = false;
       os.exit(1);
  end;

  local flat_tree = unpack_yaml_tree(yaml_tree, "yaml_tree (initial)");

  if   yaml_tree and flat_tree.metadata and type(flat_tree.metadata) == "table"
  then
       metadata = unpack_yaml_tree(flat_tree.metadata, "metadata");
       if   metadata["x-format"]
       then xformat = metadata["x-format"];
       else eprint("metadata has no x-format", ":(");
            os.exit(1);
       end;
  else eprint("YAML tree doesn't have",  "metadata :(");
       success = false;
  end;

  if   not xformat
  then eprint("metadata has no x-format", ":( :(");
       return "";
  end;

  local parse_func, slurped;

  if   xformat and not format_yaml[xformat]
  then eprint("Unknown x-format:",     xformat);
       parse_func = format_yaml.unknown;
       slurped    = parse_func(yaml_tree);
  else -- vprint("Known x-format:",       xformat);
       -- vprint("Parsing with x-format", "format_yaml[" .. xformat .. "]");
       parse_func = format_yaml[xformat];
       slurped    = parse_func(flat_tree);
       success    = slurped and slurped ~= "";
  end;

  if   success and slurped
  then return slurped, yaml_tree, metadata;
  else return "",      yaml_tree, metadata;
  end;
end;

local function dump(file, contents)
  local f = io.open(file, "wb");
  f:write(contents);
  f:close();
end

local outtxt = "";
local FILES  = {};
local DIRS   = {};
local BUILD  = {};
local USED   = {};
local ERR    = {};

local function load_fs()
  local files, dirs = file_search(CONFIG.src_dir, CONFIG.ext.filter, true)
  for k, v in pairs(dirs)
    do
      if string.find(v.path, CONFIG.ignore) then vprint("Skipping directory", v.name); break end;
      local filename = slug(v.path .. v.name);
      DIRS[filename] = true;
      vprint("Learning directory location", filename);
      end;

  for k, v in pairs(files)
    do --
      if string.find(v.path, CONFIG.ignore) then break end;
      if string.find(v.name, "%" .. CONFIG.ext.markdown .. "$")
      or string.find(v.name, "%" .. CONFIG.ext.yaml     .. "$")
         then local filename = slug(v.path..v.name);
              -- local pathdirs = split(filename, "/");
              FILES[filename] = true;
          end;
      end;
  return files, dirs;
  end;

local TEMPLATE = {};

local function parse_line(line)
  local asterisk, template = false;
  line = string.gsub(line, "/$", "");

  if   string.find(line, "/%*$")
  then asterisk = true;
       line = string.gsub(line, "/%*$", "");
  end;

  if   string.find(line, "/?::[a-z]+$")
  then vprint("looks like a template", line);
       template = string.match(line, "/?::([a-z]+)$");
       vprint("i think it's this template", template);
       line = string.gsub(line, "/?::[a-z]+$", "");
       if not TEMPLATE[template]
       then   template = nil;
              vprint("the template doesn't exist")
       else   vprint("the template DOES exit!")
       end;
  end;

  if     string.find(line, "^>")
  then   --
         local outfile = string.gsub(line, "^>%s*", "");
         outfile = string.gsub(outfile, ".out$", "");
         CONFIG.outfile = outfile;
         vprint("setting the output file", "\"" .. outfile .. "\"");
  elseif string.find(line, "^#")
  then   vprint("comment", line);
  elseif DIRS[line]
  then   --
         vprint("found a directory", line);
         vprint("looking for index", line .. "/" .. CONFIG.index);
         parse_line(line .. "/" .. CONFIG.index);

         if   template
         then vprint("found a template call", line .. "/::" .. template);
              for k, v in pairs(TEMPLATE[template])
              do  parse_line(v(line));
              end;
         end;

         if   asterisk
         then vprint("found a /* construction", line .. "/*");
              local dir = CONFIG.src_dir .. "/" .. line;
              vprint("looking for files in ", dir)
              local md_files, _ = file_search(dir, CONFIG.ext.filter);

              vprint("found this many", #md_files .. " files");
              for k, v in pairs(md_files)
              do  local sl = v.name;
                  sl = string.gsub(sl, "%" .. CONFIG.ext.filter .. "$", "");
                  parse_line(line .. "/" .. sl)
              end; -- for
         end; -- if asterisk
  elseif not USED[line]
         and (FILES[line] or FILES[line .. CONFIG.ext.yaml] or FILES[line .. CONFIG.ext.markdown])
  then   local md_file   = CONFIG.src_dir .. "/" .. line .. CONFIG.ext.markdown;
         local yaml_file = CONFIG.src_dir .. "/" .. line .. CONFIG.ext.yaml;
         if     file_exists(yaml_file)
         then   table.insert(BUILD, yaml_file)
                USED[line] = true;
         elseif file_exists(md_file)
         then   table.insert(BUILD, md_file)
                USED[line] = true;
         else   eprint("failed to find:", yaml_file .. "/" .. md_file);
         end;
    --elseif FILES[line] and USED[line]
    --then   vprint("skipping used entry", line);
  else   vprint("trying to find this",    line);
         local md_file   = line .. CONFIG.ext.markdown;
         local yaml_file = line .. CONFIG.ext.yaml;
         vprint("FILES[" .. line      .. "]:", FILES[line]      or "nope"         );
         vprint("FILES[" .. yaml_file .. "]:", FILES[yaml_file] or "nope :("      );
         vprint("FILES[" .. md_file   .. "]:", FILES[md_file]   or "nope :( :("   );
         vprint("USED["  .. line      .. "]:", USED[line]       or "nope :( :( :(");
         vprint("> no further info on:", line);
         table.insert(ERR, line);
  end;
end;


local function recipe_list()
   local files, _ = file_search(CONFIG.recipe_dir, CONFIG.recipe_sfx, false)
    sprint("Listing Recipes:", #files .. " known");
    sprint("Recipe directory", CONFIG.recipe_dir);
    for k, v in pairs(files)
    do  print(
	  string.format(
            CONFIG.logformat,
            v.path .. v.name,
            CONFIG.bin_dir .. "/" .. CONFIG.appname .. " " .. string.gsub(v.name, CONFIG.recipe_sfx, "")
          )
	);
    end;
    os.exit(1);
end;

-- ==================================
-- https://lua-cliargs.netlify.com/#/
-- Command line interface

cli:set_name(CONFIG.appname);
cli:set_description("it creates the .md files we need");

cli:splat("RECIPE", "the recipe to build", "", 1);

cli:option("-o, --outfile=OUTFILE", "specify the outfile");
cli:flag(  "-v, --verbose",         "be more wordy than usual",  false);
cli:flag(  "-q, --quiet",           "don't summarize each step", false);
cli:flag(  "-l, --list",            "list the known recipes",    false);
cli:flag(  "-e, --[no-]errors",     "show errors",               true );

local args, err = cli:parse(arg);

if not args then cli:print_help(); os.exit(1); end;

if   err
then print(string.format("%s: %s", cli.name, err));
     os.exit(1);
end;

if args and args.list then recipe_list()                                               end;
if args.quiet         then CONFIG.summary = false else CONFIG.summary = true;          end;
if args.verbose       then CONFIG.verbose = true  else CONFIG.verbose = false;         end;
if args.errors        then CONFIG.errors  = true  else CONFIG.errors  = false;         end;
if args.RECIPE        then CONFIG.recipe  = args.RECIPE; CONFIG.outfile = args.RECIPE; end;
if args.outfile       then CONFIG.outfile = args.outfile                               end;

--

-- =======================================
-- Everything above this is initialization
-- =======================================
-- =======================================
-- =======================================
-- =======================================

-- start run -----------------------------
vprint("Running in verbose mode");
sprint("Showing summaries");

-- read the recipe
sprint("reading recipe", CONFIG.recipe);
local recipe_src = slurp(CONFIG.recipe_dir .. "/" .. CONFIG.recipe .. CONFIG.recipe_sfx, true);

if not recipe_src then print("Error: Can't read that recipe file"); os.exit() end
local recipe = split(recipe_src, "[\r\n]+");
sprint("recipe read", #recipe .. " lines");

-- parse the filesystem tree
sprint("Loading the filesystem map", "source = " .. CONFIG.src_dir );
load_fs();
sprint("Filesystem mapped.");

-- parse the recipe
for _, i in pairs(recipe) do parse_line(i) end;

-- ready now to read files
sprint("reading/parsing files now", #BUILD .. " files");
for _, v in pairs(BUILD)
do  if     v:find("%" .. CONFIG.ext.yaml .. "$")
    then   outtxt = outtxt .. slurp_yaml(v);
    elseif v:find("%" .. CONFIG.ext.markdown .. "$")
    then   outtxt = outtxt .. slurp(v, false, false)
    end;
end;

-- save the output
local outfile = CONFIG.build_dir .. "/" .. CONFIG.outfile .. CONFIG.out_suffix;

sprint("Writing to file", outfile);
sprint("Content size is", string.len(outtxt) .. " characters");
dump(outfile, outtxt);

-- notify of errors
print("number of errors", (#ERR or 0) .. " error" .. ((#ERR and #ERR == 1) and "" or "s" ));

if   #ERR
then for _, v in pairs(ERR)
     do  local errmsg = "Alert: Missing file";
         if   string.find(v, CONFIG.index .. "$")
         then errmsg = "Warning: Missing index";
         end;
         eprint(errmsg, v)
     end; -- do
end; -- if #ERR
