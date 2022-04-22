#!/usr/bin/lua

local M = {};
pack = M;
-- setfenv(1, M);

local g = _G.g or {};

local function empty() end;

assert(g.FUNC,    "g.FUNC doesn't exist");       local FUNC   = g.FUNC;
assert(g.CONFIG,  "g.CONFIG doesn't exist");   local CONFIG = g.CONFIG;
assert(FUNC.util, "FUNC.util doesn't exist"); local util   = FUNC.util;

local split, file_search, vprint, eprint, sprint, yprint, pprint, yamlfuncs;
local unpack_yaml_tree, get_alpha_keys, get_sorted_keys;

assert(FUNC.file,        "FUNC.file doesn't exist");
assert(FUNC.file.search, "FUNC.file.search doesn't exist"); file_search = FUNC.file.search;

assert(util.vprint, "util.vprint doesn't exist"); vprint = util.vprint;
assert(util.eprint, "util.eprint doesn't exist"); eprint = util.eprint;
assert(util.sprint, "util.sprint doesn't exist"); sprint = util.sprint;
assert(util.yprint, "util.yprint doesn't exist"); yprint = util.yprint;
assert(util.pprint, "util.pprint doesn't exist"); pprint = util.pprint;
assert(util.ignore, "util.ignore doesn't exist"); ignore = util.ignore;

assert(FUNC.yaml, "FUNC.yaml doesn't exist"); yamlfuncs = FUNC.yaml;
assert(yamlfuncs.unpack_yaml_tree, "yamlfuncs.unpack_yaml_tree doesn't exist"); unpack_yaml_tree = yamlfuncs.unpack_yaml_tree;
assert(yamlfuncs.get_alpha_keys, "yamlfuncs.get_alpha_keys doesn't exist"); get_alpha_keys = yamlfuncs.get_alpha_keys;
assert(yamlfuncs.get_sorted_keys, "yamlfuncs.get_sorted_keys doesn't exist"); get_sorted_keys = yamlfuncs.get_sorted_keys;

assert(FUNC.meta, "FUNC.meta doesn't exist"); local meta = FUNC.meta;
assert(meta.register_cat, "meta.register_cat doesn't exist"); local register_func_category = meta.register_cat;
assert(meta.register_func, "meta.register_func doesn't exist"); local register_func = meta.register_func;
-- local util                   = FUNC.util;
-- local split                  = util and util.split or empty;
-- local file_search            = FUNC.file.search;
-- local vprint                 = util.vprint;
-- local eprint                 = util.eprint;
-- local sprint                 = util.sprint;
-- local yprint                 = util.yprint;
-- local pprint                 = util.pprint;
-- local yamlfuncs              = FUNC.yaml;
-- local unpack_yaml_tree       = yamlfuncs.unpack_tree;
-- local get_alpha_keys         = yamlfuncs.get_alpha_keys;
-- local get_sorted_keys        = yamlfuncs.get_sorted_keys;
-- local register_func_category = g.FUNC.register;
--
register_func_category("char");

assert(FUNC.char, "FUNC.char doesn't exist"); local CHAR = FUNC.char;
assert(FUNC.util, "FUNC.util doesn't exist"); local UTIL = FUNC.util;

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

local function register_char_func(name, func_func)
  if     not name      then eprint("Can't register CHAR no name",      name); os.exit();
  elseif not func_func then eprint("Can't register CHAR no func_func", name); os.exit();
  elseif CHAR[name]    then eprint("Already registered CHAR",          name); os.exit();
  end;

  vprint("Registering CHAR func", name);
  CHAR[name] = func_func;
end;

register_char_func("char",         yaml_character        );
register_char_func("power_words",  yaml_char_power_words );
register_char_func("gender",       yaml_char_gender      );
register_char_func("base",         yaml_char_base        );
register_char_func("group",        yaml_char_group       );
register_char_func("relatives",    yaml_char_relatives   );
register_char_func("picture",      yaml_char_picture     );

local register_yaml_func = g.FUNC.yaml.register;
register_yaml_func("character", yaml_character, "character");

-- CHAR.char        = yaml_character;
-- CHAR.power_words = yaml_char_power_words;
-- CHAR.gender      = yaml_char_gender;
-- CHAR.base        = yaml_char_base;
-- CHAR.group       = yaml_char_group;
-- CHAR.relatives   = yaml_char_relatives;
-- CHAR.picture     = yaml_char_picture;
 
-- g.YAML.character               = yaml_character;

-- start run -----------------------------
-- vprint("Loaded: g.FUNC.CHAR", "x-format: character");

