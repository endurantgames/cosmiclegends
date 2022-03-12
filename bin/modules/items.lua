#!/usr/bin/lua

local g = _G.g or {};

local FUNC             = g.FUNC;
local CONFIG           = g.CONFIG;
local util             = FUNC.util;
local split            = util.split;
local file_search      = FUNC.file.search;
local vprint           = util.vprint;
local eprint           = util.eprint;
local sprint           = util.sprint;
local yprint           = util.yprint;
local pprint           = util.pprint;
local yamlfuncs        = FUNC.yaml;
local unpack_yaml_tree = yamlfuncs.unpack_tree;
local get_alpha_keys   = yamlfuncs.get_alpha_keys;
local get_sorted_keys  = yamlfuncs.get_sorted_keys;
local yaml_common      = yamlfuncs.common;
local LIST             = FUNC.list;
local ITEM             = LIST.item;

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
  yprint("yaml xformat is", "item: index entry");
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

local function register_list_item_type(name, item_func, x_iteme)
  if   ITEM[name]
  then eprint("List item already registered", x_item);
       os.exit();
  end;
  if not item_func
  then eprint("List item function missing", name);
  end;

  ITEM[name] = item_func;
  g.YAML["item:" .. x_item] = item_func;
  vprint("Registered list item type:", name);
end;

ITEM.register           = register_list_item_type;

ITEM.register("event"           , yaml_event           , "timeline-entry"  );
ITEM.register("index-entry"     , yaml_index_entry     , "index-entry"     );
ITEM.register("minor-character" , yaml_minor_character , "minor_character" );
ITEM.register("group-item"      , yaml_group_item      , "group_item"      );
ITEM.register("location"        , yaml_place           , "place"           );

g.YAML.place                   = yaml_place;
g.YAML.group                   = yaml_group_item;
g.YAML.unknown                 = yaml_error;

-- start run -----------------------------
-- vprint("Loaded: g.FUNC.ITEM"                 , "item:[see below]"     );
-- vprint("Loaded: g.FUNC.ITEM.event"           , "item:timeline-entry"  );
-- vprint("Loaded: g.FUNC.ITEM.minor_character" , "item:minor-character" );
-- vprint("Loaded: g.FUNC.ITEM.place"           , "item:location"        );
-- vprint("Loaded: g.FUNC.ITEM.index_entry"     , "item:index-entry"     );
 
