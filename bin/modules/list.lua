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

local function get_item_formatter_func(metadata)
  -- Usage:
  -- local item_formatter, if_error = get_item_formatter_func(metadata);
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

-- function LIST.register(name, func_func, x_format);

local function register_list_type(name, func_func, x_format)
  x_format = x_format or name;
  FUNC.register_format(name, func_func, x_format);
  YAML.register(name, func_func, x_format);
  vprint("Registering list type:", x_format);
end;

LIST.register = register_list_type;

LIST.register( "list"     , yaml_list     );
LIST.register( "glossary" , yaml_glossary );
LIST.register( "place"    , yaml_place    );
LIST.register( "index"    , yaml_index    );

LIST.get_item_formatter = get_item_formatter;
LIST.glossary           = yaml_glossary;
LIST.group_item         = group_item;
LIST.index              = yaml_index;
LIST.list               = yaml_list;
LIST.minor_character    = yaml_minor_character;
LIST.pageref            = yaml_pageref;
LIST.place              = yaml_place;

g.YAML.unknown                 = yaml_error;
g.YAML["item:minor-character"] = yaml_minor_character;
g.YAML["item:location"       ] = yaml_place;
g.YAML["item:group"          ] = yaml_group_item;
g.YAML["item:timeline-entry" ] = yaml_event;
g.YAML["item:index-entry"    ] = yaml_index_entry;

-- start run -----------------------------
vprint("Loaded: g.FUNC.list"                 , "x-format: list"       );
vprint("Loaded: g.FUNC.ITEM.event"           , "item:timeline-entry"  );
vprint("Loaded: g.FUNC.ITEM.minor_character" , "item:minor-character" );
vprint("Loaded: g.FUNC.ITEM.place"           , "item:location"        );
vprint("Loaded: g.FUNC.ITEM.index_entry"     , "item:index-entry"     );

