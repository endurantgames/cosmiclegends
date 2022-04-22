#!/usr/bin/lua

local g = _G.g or {};
local YAML = g.YAML or {};

assert(g.FUNC,      "g.FUNC does not exist"      ); local FUNC        = g.FUNC;
assert(g.CONFIG,    "g.CONFIG does not exist"    ); local CONFIG      = g.CONFIG;
assert(FUNC.util,   "FUNC.util does not exist"   ); local util        = FUNC.util;
assert(FUNC.yaml,   "FUNC.yaml does not exist"   ); local yamlfuncs   = FUNC.yaml;
assert(FUNC.file,   "FUNC.file does not exist"   ); local FILE        = FUNC.file;
assert(util.split,  "util.split does not exist"  ); local split       = util.split;
assert(util.vprint, "util.vprint does not exist" ); local vprint      = util.vprint;
assert(util.eprint, "util.eprint does not exist" ); local eprint      = util.eprint;
assert(util.sprint, "util.sprint does not exist" ); local sprint      = util.sprint;
assert(util.yprint, "util.yprint does not exist" ); local yprint      = util.yprint;
assert(util.pprint, "util.pprint does not exist" ); local pprint      = util.pprint;
assert(util.ignore, "util.ignore does not exist" ); local ignore      = util.ignore;
assert(util.split,  "util.split does not exist"  ); local split       = util.split;
assert(FILE.search, "FILE.search does not exist" ); local file_search = FILE.search;
assert(FUNC.char,   "FUNC.char does not exist"   ); local CHAR        = FUNC.char;
assert(FUNC.sheet,  "FUNC.sheet does not exist"  ); local SHEET       = FUNC.sheet;
assert(FUNC.list,   "FUNC.list does not exist"   ); local LIST        = FUNC.list;
assert(FUNC.item,   "FUNC.item does not exist"   ); local ITEM        = FUNC.item;
assert(yamlfuncs.register_format, "FUNC.yaml.register_format does not exist"); local register_format = yamlfuncs.register_format;

-- local file_search      = FUNC.file.search;
-- local eprint           = util.eprint;
-- local sprint           = util.sprint;
-- local yprint           = util.yprint;
-- local pprint           = util.pprint;
-- local yamlfuncs        = FUNC.yaml;
-- local unpack_yaml_tree = yamlfuncs.unpack_tree;
-- local get_alpha_keys   = yamlfuncs.get_alpha_keys;
-- local get_sorted_keys  = yamlfuncs.get_sorted_keys;
-- local yaml_error       = yamlfuncs.error;
-- local CHAR             = FUNC.char;
-- local SHEET            = FUNC.sheet;
-- local LIST             = FUNC.list;
-- local ITEM             = LIST.item;
 
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

register_cat("sheet");
register_func("sheet", "abilities",  yaml_sheet_abilities);
register_func("sheet", "approaches", yaml_sheet_approaches);
register_func("sheet", "basics",     yaml_sheet_basics);
register_func("sheet", "bio",        yaml_sheet_bio);
register_func("sheet", "face",       yaml_sheet_face);
register_func("sheet", "ideals",     yaml_sheet_ideals);
register_func("sheet", "power_words",yaml_sheet_power_words);
register_func("sheet", "sheet",      yaml_sheet);
register_func("sheet", "skills",     yaml_sheet_skills);

-- SHEET.abilities   = yaml_sheet_abilities;
-- SHEET.approaches  = yaml_sheet_approaches;
-- SHEET.basics      = yaml_sheet_basics;
-- SHEET.bio         = yaml_sheet_bio;
-- SHEET.face        = yaml_sheet_face;
-- SHEET.ideals      = yaml_sheet_ideals;
-- SHEET.power_words = yaml_sheet_power_words;
-- SHEET.sheet       = yaml_sheet;
-- SHEET.skills      = yaml_sheet_skills;
 
register_format("unknown",               yaml_error           );
register_format("character-sheet",       yaml_sheet           );
register_format("item:minor-character",  yaml_minor_character );
register_format("item:location",         yaml_place           );
register_format("item:group",            yaml_group_item      );
register_format("item:timeline-entry",   yaml_event           );
register_format("item:index-entry",      yaml_index_entry     );

-- g.YAML.unknown                 = yaml_error;
-- g.YAML["character-sheet"     ] = yaml_sheet;
-- g.YAML["item:minor-character"] = yaml_minor_character;
-- g.YAML["item:location"       ] = yaml_place;
-- g.YAML["item:group"          ] = yaml_group_item;
-- g.YAML["item:timeline-entry" ] = yaml_event;
-- g.YAML["item:index-entry"    ] = yaml_index_entry;
 
-- start run -----------------------------
vprint("Loaded: g.FUNC.SHEET", "x-format: character-sheet");

