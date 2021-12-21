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

  if   type(tbl) ~= "table" then print("Error: not a table"); os.exit(1); end;

  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
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
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

-- =====================================================================================================================
-- code by GianlucaVespignani - 2012-03-04; 2013-01-26
-- Search files in a path, alternative in sub directory
-- @param dir_path string (";" for multiple paths supported)
-- @param filter string - eg.: ".txt" or ".mp3;.wav;.flac"
-- @param s bool - search in subdirectories
-- @param pformat format of data - 'system' for system-dependent number; nil or string with formatting directives
-- @return  files, dirs - files and dir are tables {name, modification, path, size}

function file_search(dir_path, filter, s, pformat)
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
        local extensions = filter:split(";")
        s = s or false -- as /s : subdirectories

        if pformat == 'system' then        -- if 4th arg is explicity 'system', then return the system-dependent number representing date/time
                os_date = function(os_time)
                        return os_time
                end
        else
                -- if 4th arg is nil use default, else it could be a string that respects the Time formatting directives
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
                                                local subf={}
                                                local subd={}
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
end

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
       vprint(slug(file), "should be " .. level .. ", is " .. octo_level);
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
  vprint("unpacking", comment);
  if     yaml_tree == nil
  then   eprint("Error!", "yaml_tree = nil");
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
    -- vprint("sorting a, b: a = ", a);
    -- vprint("sorting a, b: b = ", b);
    a = (a or "") .. "";
    b = (b or "") .. "";
    local aa = a:gsub("^The ","");
    local bb = b:gsub("^The ","");
    return string.lower(aa) < string.lower(bb);
  end;

  -- print("there are this many keys", #t);
  local keys = {}
  local n    = 0;
  for k, v in pairs(t)
  do  n       = n + 1;
      vprint("==============", "===============");
      if     type(k) == "string"
      then   keys[n] = k .. "";
             -- vprint("found key " ..n, k);
             table.insert(keys, k);
      elseif ignore
      then   vprint("ignoring", k);
      else   eprint("OOPS type(" .. k .. ")", type(k));
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
  -- usage:
  -- local flat_tree, metadata, slurped, common_error = yaml_common(yaml_tree);
  vprint("yaml_comment : yaml_tree", type(yaml_tree));
  vprint("yaml_comment : slurped", type(slurped));
  local common_error;
  slurped = slurped or "\n\n";
  local flat_tree = unpack_yaml_tree(yaml_tree, "yaml_common") or {};
  local metadata;
  if   flat_tree.metadata
  then metadata = unpack_yaml_tree(flat_tree.metadata, "yaml_common : metadata") or {};
  else -- vprint("error: no metadata", "in yaml_common");
       metadata = nil;
       common_error = true
  end;
  return yaml_tree, metadata, slurped, common_error;
end;

local function yaml_char_group(bio_group_affiliation)
  local markdown = "";
  vprint("we have group affiliation");
  markdown = markdown .. "\n- **Group Affiliation:** ";
  local group_list = {};
  local membership = unpack_yaml_tree(bio_group_affiliation, "membership");
  for group_name, data in pairs(membership)
  do  local str = group_name
      if   data.inactive or data.reserve or data.founder or data.resigned or data.expelled
      then local memdata = {};
           if data.founder  then table.insert(memdata, "founding member"); end;
           if data.inactive then table.insert(memdata, "inactive");        end;
           if data.resigned then table.insert(memdata, "resigned");        end;
           if data.reserve  then table.insert(memdata, "reserve member");  end;
           if data.status   then table.insert(memdata, data.status);       end;
            str = str .. " (" .. table.concat(memdata, ", ") .. ")";
      end;
      table.insert(group_list, str);
      markdown = markdown .. table.concat(group_list, ", ");
  end;
  return markdown;
end;

local function yaml_char_relatives(bio_relatives)
  local markdown = "\n- **Known Relatives:** ";
  local relatives = unpack_yaml_tree(bio_relatives, "relatives");
  local rel_list = {};
  for rel_name, rel in pairs(relatives)
  do  local rel_string = rel_name;
      local rel_data = unpack_yaml_tree(rel, "rel");
      if rel.gender then rel_string = rel_string .. "[]{.icon-" .. rel_data.gender .. "} "; end;

      if   rel.relationship or rel.deceased or rel.aka
      then rel_string = rel_string .. "(";
           if   rel.relationship
           then rel_string = rel_string .. rel.relationship;
                if rel.deceased or rel.aka then rel_string = rel_string .. ", ";             end;
           end; -- if rel.relationship

           if rel.aka                      then rel_string = rel_string .. rel.aka;          end;
           if rel.deceased                 then rel_string = rel_string .. "*deceased*";     end;
           rel_string = rel_string .. ")";
      end; -- if rel[relationship, deceased, aka]
      table.insert(rel_list, rel_string);
  end; -- for rel.name
  markdown = markdown .. table.concat(rel_list, ", ");
  return markdown;
end;

local function yaml_char_picture(character_picture)
  local markdown = "";
  local picture = unpack_yaml_tree(character_picture, "picture");
  vprint("We have picture!");
  if   picture.alt and picture.url
  then markdown = markdown .. "![" .. picture.alt .. "]";
  else markdown = markdown .. "![]";
       eprint("We don't have alt text", ":(");
  end;
  if   picture.url
  then markdown = markdown .. "(" .. picture.url .. ")";
       vprint("We have url!", picture.url);
  else eprint("We don't have url :(");
  end;
  return markdown;
end;

local function yaml_char_base(bio_base)
  if type(bio_base) == "string" then return "\n- **Base of Operations:** " .. bio_base; end;
  local markdown  = "\n- **Base of Operations:** ";
  local base_list = {};
  local bases     = unpack_yaml_tree(bio_base, "base");
  for base_name, base_data in pairs(bases)
  do  if   type(base_data) == "string"
      then table.insert(base_list, base_data);
      else local data         = unpack_yaml_tree(base_data, "base_data");
           local str          = base_name;
           local base_details = {};
           if #bases > 1 and data.active then table.insert(base_details, "current");   end;
           if data.former                then table.insert(base_details, "formerly");  end;
           if data.temporary             then table.insert(base_details, "temporary"); end;
           str = str .. " (" .. table.concat(base_details, ", ") .. ")";
           table.insert(base_list, str);
      end;
  end;
  markdown = markdown .. table.concat(base_list, "; ");
  return markdown;
end;

local function yaml_char_gender(bio_gender)
  if type(bio_gender) == "string" then return "\n- **Gender:** " .. bio_gender; end;
  vprint("we have gender!");
  local markdown = "\n- **Gender:** ";
  local gender = unpack_yaml_tree(bio_gender, "gender");
  if gender.desc     then markdown = markdown .. "\n- **Gender:** " .. gender.desc; end;
  if gender.pronouns then markdown = markdown .. " (" .. gender.pronouns .. ")";    end;
  return markdown;
end;

local function yaml_char_power_words(stats_power_words)
  local markdown = "\n- **Power Words:**";
  local power_words = unpack_yaml_tree(stats_power_words);

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

local function yaml_character(yaml_tree)
  local character, metadata, markdown = yaml_common(yaml_tree);
  vprint("yaml xformat is:", "character");

  if   metadata
  then vprint("we have metadata!")
       if metadata.title  then markdown = markdown .. "# "  .. metadata.title;         end
       if metadata.anchor then markdown = markdown .. " {#" .. metadata.anchor .. "}"; end;
       markdown = markdown .. "\n\n";
  else vprint("we don't have metadata :(");
  end;

  if   character
  then vprint("we have character!")

       if   character.picture
       then markdown = markdown .. yaml_char_picture(character.picture);
       else eprint("We don't have picture :(");
       end; -- character.picture

       if   character.bio
       then vprint("We have bio!");

            markdown = markdown .. "\n" .. string.rep(":", 15) .. " {.bio} " ;
            markdown = markdown .. "\n" .. string.rep(":", 15) .. "\n";

            local bio = unpack_yaml_tree(character.bio, "bio");

            if bio.real_name    then markdown = markdown .. "\n- **Real Name:** "    .. bio.real_name;    end;
            if bio.occupation   then markdown = markdown .. "\n- **Occupation:** "   .. bio.occupation;   end;
            if bio.legal_status then markdown = markdown .. "\n- **Legal Status:** " .. bio.legal_status; end;

            if   bio.gender
            then markdown = markdown .. yaml_char_gender(bio.gender);
            else eprint("we don't have gender :(");
            end;

            if bio.identity       then markdown = markdown .. "\n- **Identity:** "       .. bio.identity;       end;
            if bio.place_of_birth then markdown = markdown .. "\n- **Place of Birth:** " .. bio.place_of_birth; end;
            if bio.marital_status then markdown = markdown .. "\n- **Marital Status:** " .. bio.marital_status; end;

            if     bio.relatives and type(bio.relatives) == "table"
            then   markdown = markdown .. yaml_char_relatives(bio.relatives);
            elseif bio.relatives == "none"
            then   markdown = markdown .. "- **Known Relatives:** none";
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
       then vprint("we have history!");
            markdown = markdown .. "\n\n" .. "**History:**" .. "\n\n";
            markdown = markdown .. character.history;
       else eprint("we don't have history :(");
       end;

       if   character.powers
       then vprint("we have powers!");
            markdown = markdown .. "\n\n" .. "**Powers:**" .. "\n\n";
            markdown = markdown .. character.powers;
       else eprint("we don't have powers :(");
       end;

       if   character.weapons
       then vprint("we have weapons!");
            markdown = markdown .. "\n\n" .. "**Weapons:**" .. "\n\n";
            markdown = markdown .. character.powers;
       else vprint("we don't have weapons :(");
       end;

       if   character.stats
       then vprint("we have stats!");

            markdown = markdown .. "\n\n" .. string.rep(":", 25);
            markdown = markdown .. " stats ";
            markdown = markdown .. string.rep(":", 20) .. "\n";

            local stats = unpack_yaml_tree(character.stats, "stats");

            if stats.name  then markdown = markdown .. "\n## " .. stats.name .. "\n\n";             end;
            if stats.class then markdown = markdown .. "- **" .. "Class:** " .. stats.class .. "\n" end;

            if   stats.approaches
            then vprint("We have approaches!");
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
            then vprint("We have power words!");
	            markdown = markdown .. yaml_char_power_words(stats.power_words);
            else eprint("We don't have power words :(");
            end;

            if   stats.abilities and type(stats.abilities) == "table"
            then vprint("We have abilities!");
                 local abilities = unpack_yaml_tree(stats.abilities, "abilities");
                 markdown = markdown .. "\n- **Abilities:** " .. table.concat(abilities, ", ");
            else eprint("we don't have abilities :(");
            end;

            if   stats.fighting_styles and type(stats.fighting_styles) == "table"
            then vprint("We have fighting styles!");
                 local fighting_styles = unpack_yaml_tree(stats.fighting_styles, "fighting styles");
                 markdown = markdown .. "\n- **Fighting Styles:** " .. table.concat(fighting_styles, ", ");
            elseif stats.fighting_styles and type(stats.fighting_styles) == "string"
            then vprint("we have fighting style(s?)");
                 markdown = markdown .. "\n- **Fighting Styles:** " .. stats.fighting_styles;
            else eprint("We don't have fighting styles :(");
            end;

            if   stats.skills and type(stats.skills) == "table"
            then vprint("We have skills!");
                 local skills = unpack_yaml_tree(stats.skills, "skills");
                 markdown = markdown .. "\n- **Skills:** " .. table.concat(skills, ", ");
            elseif stats.skills and type(stats.skill) == "string"
            then vprint("we have skill(s?)!");
                 markdown = markdown .. "\n-- **Skills:** " .. stats.skills;
            else eprint("We don't have skills :(");
            end;

            if   stats.ideals and type(stats.ideals) == "table"
            then vprint("we have ideals!");
                 local ideals = unpack_yaml_tree(stats.ideals, "ideals");
                 markdown = markdown .. "\n- **Ideals:** " .. table.concat(ideals, ", ");
            elseif stats.ideals and type(stats.ideals) == "string"
            then markdown = markdown .. "\n- **Ideals:** " .. stats.ideals;
                 vprint("we have ideal(s?)!");
            else eprint("we don't have ideals", ":(");
            end;

            markdown = markdown .. "\n\n" .. string.rep(":", 50);

       else eprint("we don't have stats :(");
       end;

  else eprint("we don't have flat tree / character :(");

  end;
  return markdown;

end;

local function get_item_formatter_func(metadata)
  -- Usage:
  -- local item_formatter, if_error = get_item_formatter_func(metadata);
  --
  vprint("looking for item_formatter");
  if not metadata then eprint("Error! Metadata", type(metadata)); end;
  local metadata_keys = get_sorted_keys(metadata);

  if     not metadata_keys
  then   eprint("metadata_keys", metadata_keys);
         os.exit(1);
  elseif not type(metadata_keys) == "table"
  then   eprint("type(metadata_keys)", type(metadata_keys));
         os.exit(1);
  end;
  vprint("metadata keys", inspect(metadata_keys));

  if   not metadata.flat
  then eprint("Error! Metadata", "not flattened");
  end;
  local item_format = metadata and metadata["item-format"];
  if   not item_format
  then eprint("no item format?!", item_format);
       return format_yaml.unknown, true
  end;

  local item_formatter = format_yaml["item:" .. item_format];
  if   not item_formatter
  then eprint("no item formatter?! for ...", item_format);
       return format_yaml.unknown, true
  end;

  return item_formatter, false
end;

local function get_item_list(yaml_tree)
end;

local function yaml_list(yaml_tree)
  vprint("yaml xformat is:", "list");
  local flat_tree, metadata, slurped, common_error = yaml_common(yaml_tree);
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

  local keys;

  if   item_list
  then vprint("found the items list", item_list);
       item_list  = unpack_yaml_tree(item_list, "item list");
       local keys = get_sorted_keys(item_list);
       local item_formatter, if_error = get_item_formatter_func(metadata);
       if   if_error
       then errors = errors + 1;
       else vprint("keys:", inspect(keys));
            for _, k in pairs(keys)
            do  local data = item_list[k];
                local term = k;
                vprint("term is", k);
                if   not data
                then eprint("error: flat_tree[" .. k .. "]", "NOT EXIST");
                     errors = errors + 1;
                     break;
                end; -- not data

                if   data.definite
                then vprint("===================", "---------------------");
                     vprint("definite article on", term);
                     term = "The " .. term;
                     vprint("===================", "---------------------");
                end;
                slurped         = slurped .. "\n- **" .. term .. "**";
                local item_info = item_formatter(data);
                vprint("defined list entry " .. term, item_info);
                if   not item_info
                then eprint("***** start *****", "******************");
                     vprint("item_info is nil for", term);
                     vprint(term, inspect(item_info));
                     eprint("*****************", "******** end *****");
                end;
                slurped         = slurped .. inspect(item_info);
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
  local flat_tree, metadata, slurped, common_error = yaml_common(yaml_tree);
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
           vprint("data", data);
           local glossary_data = unpack_yaml_tree(data, term);
           local def           = glossary_data.def
           local hq_equiv      = glossary_data.hq_equiv;
           if   type(hq_equiv) == "table"
           then hq_equiv       = unpack_yaml_tree(hq_equiv, term .. ".hq_equiv");
                hq_equiv       = hq_equiv.term; end;
           local generic_equiv = glossary_data.generic_equiv;
           if   type(generic_equiv) == "table"
           then generic_equiv  = unpack_yaml_tree(generic_equiv, term .. ".generic_equiv");
                generic_equiv  = generic_equiv.term;
           end;
           if   def and type(def) == "string"
           then vprint(term, def);
                vprint("term", type(term));
                vprint("def", type(def));
                vprint(term .. " means:", def);
                slurped = slurped .. term .. "\n";
                slurped = slurped .. ":   " .. def;
           else vprint("==============", "===============");
                vprint("ERROR " .. term, "no def");
                -- print(inspect(glossary_data));
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

local function yaml_place(yaml_tree)
  vprint("yaml xformat is:", "item:location");
  local place, metadata, slurped, common_error = yaml_common(yaml_tree);
  if place.where then vprint("place.where", place.where); slurped = slurped .. " (*" ..          place.where .. "*)"; end;
  if place.bio   then vprint("place.bio", place.bio);     slurped = slurped ..                   place.bio            end;
  if place.cf    then vprint("place.cf", place.cf);       slurped = slurped .. "; also see *" .. place.cf .. "*";     end;
  vprint("place data: ", slurped);
  return slurped;
end;

local function yaml_group(yaml_tree)
  vprint("yaml xformat is:", "item:group");
  local group, metadata, slurped, common_error = yaml_common(yaml_tree);
  local status = group.active and " " or group.disbanded and " *defunct* " or " *status unknown* ";
  slurped = slurped .. status;
  if   group.bio                              then slurped = slurped .. group.bio;                    end;
  if   group.cf and type(group.cf) == "table" then slurped = slurped .. table.concat(group.cf, ", "); end;
  if   group.members and type(group.members) == "table"
  then local member_list = unpack_yaml_tree(group.members);
       slurped = slurped .. "; Members: ";
       local member_entries = {};
       local member_entry = "";
       if   not group["membership-complex"]
       then for name, member in pairs(member_list)
            do  local member_status  = member.active    and "" or              member.resigned and " *resigned* " or
                                       member.deceased  and " *deceased* "  or member.expelled and " *expelled* " or
                                       member.graduated and " *graduated* " or " *status unknown* ";
                if member.title        then member_entry = member_entry .. " " .. member.title;                 end;
                if name or member.name then member_entry = member_entry .. (name or member.name) .. " ";        end;
                if member.aka          then member_entry = member_entry .. " (" .. member.aka .. ")";           end;
                if member.gender       then member_entry = member_entry .. "[]{.icon-" .. member.gender .. "}"; end;
                if member_status       then member_entry = member_entry .. member_status;                       end;
                if member.bio          then member_entry = member_entry .. " " .. member.bio;                   end;
            end; -- for name, member
       else -- membership-complex
            for name, member in pairs(member_list)
            do  member_entry = member_entry .. name .. " ";
                local complex_status = member.active   and ""             or member.honorary and " *honorary* " or
                                       member.resigned and " *resigned* " or member.defunct  and " *defunct* "  or
                                       member.inactive and " *inactive* " or member.former   and " *former* "   or
                                       member.expelled and " *expelled* " or " *status unknown* ";
                if   complex_status
                then member_entry = member_entry .. complex_status;
                end;
                if   member.active and member.rep and type(member.rep) == "table"
                then local rep = unpack_yaml_tree(member.rep);
                     if   not string.match(rep.name, "none")
                     then -- if rep.active then member_entry = member_entry .. " [ represented by ";              end;
                          -- if rep.former then member_entry = member_entry .. " [ formerly represented by ";     end;
                          -- if rep.title  then member_entry = member_entry .. rep.title .. " ";                  end;
                          -- if rep.name   then member_entry = member_entry .. rep.name;                          end;
                          -- if rep.gender then member_entry = member_entry .. "[]{.icon-" .. rep.gender .. "}";  end;
                          -- if rep.aka    then member_entry = member_entry .. " (" .. rep.aka .. ") ";           end;
                          member_entry = member_entry .. "]";
                     else                    member_entry = member_entry .. " [ represented by: *no one* ]"
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
format_yaml["item:minor-character"] = yaml_minor_character;
format_yaml["item:location"]        = yaml_place;
format_yaml["item:group"]           = yaml_group;

local function slurp_yaml(filename)

  -- local function yprint(tab, comment)
    -- if   type(tab) ~= "table"
    -- then eprint("Error!", comment .. " is not a table");
    -- else local yaml_text = lyaml.dump(tab);
         -- vprint("=== start " .. comment .. " Yprint", "==============");
         -- print(yaml_text);
         -- vprint("=== end   " .. comment .. " Yprint", "==============");
    -- end;
  -- end;

  if filename then vprint("Recognized as YAML location", filename); end;

  local yaml_source = slurp(filename, true);

  vprint("Reading YAML file now", yaml_source:len() .. " bytes");

  local yaml_tree = {};
  local success   = false;
  local metadata  = {};
  local xformat;
  local slurped   = "\n<!-- above: " .. filename .. " -->\n";

  if   yaml_source
  then vprint("size of yaml_source", string.len(yaml_source) .. " bytes");
  end;

  -- filename = "(inline YAML)";

  if   type(yaml_source) == "string"
  then
       vprint("Successfully read YAML file:", filename);
       vprint("YAML source size",             yaml_source:len() .. " bytes");
       yaml_tree = lyaml.load(yaml_source);
  else eprint("Couldn't read yaml:",          filename);
       success = false;
  end;

  if   yaml_tree and yaml_tree ~= {}
  then vprint("Successfully parsed ", filename .. " to yaml_tree");
       success = true;

  else eprint("Couldn't parse yaml:", filename);
       success = false;
  end;

  vprint("yaml_tree type is", type(yaml_tree));
  vprint("#yaml_tree is",     #yaml_tree     );

  local flat_tree = unpack_yaml_tree(yaml_tree, "yaml_tree (initial)");

  if   yaml_tree and flat_tree.metadata
  then
       vprint("YAML tree has metadata!");
       vprint("metadata type is", type(metadata));
       metadata = unpack_yaml_tree(flat_tree.metadata, "metadata");
       if   metadata["x-format"]
       then xformat = metadata["x-format"];
            vprint("metadata has x-format!", xformat);
       else eprint("metadata has no x-format", ":(");
            os.exit(1);
       end;
  else eprint("YAML tree doesn't have",  "metadata :(");
       success = false;
  end;

  if   xformat
  then vprint("metadata has x-format!", xformat);
  else eprint("metadata has no x-format", ":( :(");
       success = false;
       xformat = nil;
       return "";
  end;

  local parse_func;

  if   xformat and not format_yaml[xformat]
  then eprint("Unknown x-format:",     xformat);
       parse_func = format_yaml.unknown;
       slurped    = parse_func(yaml_tree);
  else vprint("Known x-format:",       xformat);
       vprint("Parsing with x-format", "format_yaml[" .. xformat .. "]");
       parse_func = format_yaml[xformat];
       slurped    = parse_func(flat_tree);

       success = slurped and slurped ~= "";

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
  files, dirs = file_search(CONFIG.src_dir, CONFIG.ext.filter, true)
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
              local pathdirs = split(filename, "/");
              FILES[filename] = true;
          end;
      end;
  return files, dirs;
  end;

local TEMPLATE = { };

local function parse_line(line)
  local asterisk, template = false;
  line = string.gsub(line, "/$", "");
  vprint("parsing line:", line);
  if string.find(line, "/%*$")
     then asterisk = true;
          line = string.gsub(line, "/%*$", "");
          end;
  if string.find(line, "/?::[a-z]+$")
     then
          vprint("looks like a template", line);
          template = string.match(line, "/?::([a-z]+)$");
          vprint("i think it's this template", template);
          line = string.gsub(line, "/?::[a-z]+$", "");
          if not TEMPLATE[template]
             then template = nil;
                  vprint("the template doesn't exist")
             else vprint("the template DOES exit!")
             end;
          end;
  if string.find(line, "^>")
    then --
         local outfile = string.gsub(line, "^>%s*", "");
               outfile = string.gsub(outfile, ".out$", "");
         CONFIG.outfile = outfile;
         vprint("setting the output file", "\"" .. outfile .. "\"");
    elseif string.find(line, "^#")
    then --
         vprint("comment", line);
    elseif DIRS[line]
    then --
         vprint("found a directory", line);
         vprint("looking for index", line .. "/" .. CONFIG.index);
         parse_line(line .. "/" .. CONFIG.index);

         if template
            then
              vprint("found a template call", line .. "/::" .. template);
              for k, v in pairs(TEMPLATE[template])
                  do parse_line(v(line));
                  end;
            end;

         if asterisk
            then
              vprint("found a /* construction", line .. "/*");
              local dir = CONFIG.src_dir .. "/" .. line;
              vprint("looking for files in ", dir)
              local md_files, _ = file_search(dir, CONFIG.ext.filter);

              vprint("found this many", #md_files .. " files");
              for k, v in pairs(md_files)
                  do local sl = v.name;
                     sl = string.gsub(sl, "%" .. CONFIG.ext.filter .. "$", "");
                     parse_line(line .. "/" .. sl)
              end; -- for
            end; -- if asterisk
    elseif FILES[line]                        and not USED[line]
        or FILES[line .. CONFIG.ext.yaml]     and not USED[line]
        or FILES[line .. CONFIG.ext.markdown] and not USED[line]
    then vprint("found an entry", line);
         local md_file   = CONFIG.src_dir .. "/" .. line .. CONFIG.ext.markdown;
         local yaml_file = CONFIG.src_dir .. "/" .. line .. CONFIG.ext.yaml;
         if     file_exists(yaml_file)
         then   vprint("found yaml", yaml_file);
                table.insert(BUILD, yaml_file)
                vprint("added to BUILD list", yaml_file);
                USED[line] = true;
         elseif file_exists(md_file)
         then   table.insert(BUILD, md_file)
                vprint("found markdown", md_file);
                USED[line] = true;
         else   eprint("failed to find:", yaml_file .. "/" .. md_file);
         end;
    elseif FILES[line] and USED[line]
    then vprint("skipping used entry", line);
    else vprint("trying to find this",    line);
         local md_file   = line .. CONFIG.ext.markdown;
         local yaml_file = line .. CONFIG.ext.yaml;
         vprint("FILES[" .. line      .. "]:", FILES[line]      or "nope");
         vprint("FILES[" .. yaml_file .. "]:", FILES[yaml_file] or "nope :(");
         vprint("FILES[" .. md_file   .. "]:", FILES[md_file]   or "nope :( :(");
         vprint("USED["  .. line      .. "]:", USED[line]       or "nope :( :( :(");
         vprint("> no further info on:", line);
         table.insert(ERR, line);

    end;
end;


local function recipe_list()
   local files, dirs = file_search(CONFIG.recipe_dir, CONFIG.recipe_sfx, false)
    sprint("Listing Recipes:", #files .. " known");
    sprint("Recipe directory", CONFIG.recipe_dir);
    for k, v in pairs(files)
        do print(string.format(CONFIG.logformat,
              v.path .. v.name,  CONFIG.bin_dir .. "/" .. CONFIG.appname .. " " .. string.gsub(v.name, CONFIG.recipe_sfx, "")
              )); end;

    os.exit(1);
end;

-- =======================================================================================================================
-- Command line interface
-- https://lua-cliargs.netlify.com/#/

cli:set_name(CONFIG.appname);
cli:set_description("it creates the .md files we need");

cli:splat("RECIPE", "the recipe to build", "", 1);
-- cli:argument("RECIPE", "the recipe to build");

cli:option("-o, --outfile=OUTFILE", "specify the outfile");

cli:flag( "-v, --verbose", "be more wordy than usual", false);
cli:flag("-q, --quiet", "don't summarize each step", false);
cli:flag("-l, --list", "list the known recipes", false);
cli:flag("-e, --[no-]errors", "show errors", true);

local args, err = cli:parse(arg);
if not args then cli:print_help(); os.exit(1); end;
if err then print(string.format("%s: %s", cli.name, err)); os.exit(1); end;

if args and  args.list then recipe_list() end;

if args.quiet   then CONFIG.summary = false else CONFIG.summary = true;  end;
if args.verbose then CONFIG.verbose = true  else CONFIG.verbose = false; end;
if args.errors  then CONFIG.errors  = true  else CONFIG.errors  = false; end;

if args.RECIPE
   then CONFIG.recipe  = args.RECIPE;
        CONFIG.outfile = args.RECIPE;
   end;

if args.outfile then CONFIG.outfile = args.outfile end;

--

-- =======================================================================================================================
-- Everything above this is initializion
-- =======================================================================================================================
-- =======================================================================================================================
-- =======================================================================================================================
-- =======================================================================================================================

-- start run ------------------------------------------------------------------------------
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

tprint(FILES, 1);

-- for i, v in pairs(FILES) do vprint("FILES[" ..i .."]", v) end;

-- parse the recipe
for _, i in pairs(recipe) do parse_line(i) end;

sprint("Recipe loaded.");

-- ready now to read files
sprint("reading/parsing files now", #BUILD .. " files");
for i, v in pairs(BUILD)
do  if     v:find("%" .. CONFIG.ext.yaml .. "$")
    then   vprint("slurping YAML", v);
           outtxt = outtxt .. slurp_yaml(v);
    elseif v:find("%" .. CONFIG.ext.markdown .. "$")
    then   outtxt = outtxt .. slurp(v, false, false)
           vprint("slurping", v .. CONFIG.ext.markdown);
    end;
end;

-- save the output
local outfile = CONFIG.build_dir .. "/" .. CONFIG.outfile .. CONFIG.out_suffix;

sprint("Writing to file", outfile);
sprint("Content size is", string.len(outtxt) .. " characters");
dump(outfile, outtxt);

-- notify of errors
sprint("number of errors", (#ERR or 0) .. " error" .. ((#ERR and #ERR == 1) and "" or "s" ));
if #ERR
   then for i, v in pairs(ERR)
        do local errmsg = "Alert: Missing file";
           if string.find(v, CONFIG.index .. "$") then errmsg = "Warning: Missing index"; end;
           eprint(errmsg, v)
        end; -- do
   end; -- if #ERR
