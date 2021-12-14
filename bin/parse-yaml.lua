local lyaml = require "lyaml";

local function vprint() end;
local function eprint() end;

local function parse_yaml_to_tree(str)
  if not str then return false, nil end;

  str = type(str) == "table" and table.concat(str, "\n");

  if type(str) == "table" then str = table.concat(str, "\n"); end;

  if type(str) ~= "string" then eprint("Error: yaml is not string"); end;

  local yaml_tree = lyaml.load(str);
  return yaml_structure ~= nil, yaml_structure;
end

local function parse_lines_to_yaml_tree(lines)
  if not lines then return false, nil end;
  local yaml_source = table.concat(tree, "\n");
  local successful_parse, yaml_tree = parse_yaml_to_tree(yaml_source);
  if   not successful_parse
  then eprint("YAML did not parse successfully.") 
       return false, nil;
  else vprint("YAML parse successful!");
       return true, yaml_tree
  end;
end;

function tprint(tbl, indent)
  if not indent then indent = 0 end
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

local format_yaml = {}

format_yaml.glossary = 
function(yaml_structure, return_format) -- glossary file
  if not return_format == "table" or not return_format == "text"
  then eprint("Unknown return format to format_yaml.glossary:", return_format);
  end;

  if type(yaml_structure) ~= "table"
  then eprint("YAML structure is not table. (Parse it first?)");
  end;

  local markdown_section_started = false;
  for item, value in pairs(yaml_structure)
  do  vprint("Found a glossary file:")
      local term, def = "", "";
      local indent    = "    ";
      local lines     = {};
      if   item == "metadata"
      then -- skip it
      else -- not metadata, don't skip
           if   not markdown_section_started
           then table.insert(slurped, string.rep(":", 20) .. " glossary " .. string.rep(":", 40));
                markdown_section_started = true;
           end; -- not markdown section started

           if   value.def and type(value.def) == "string" 
           then slurped = slurped .. "\n"             .. item;
                slurped = slurped .. "\n\n" .. indent .. value.def;

                if   value.hd_equiv
                then slurped = slurped .. "(*" .. value.hd_equiv .. "* in Harmony Drive.)";
                end; -- if value hd_equiv

                slurped = slurped .. "\n\n";
           else eprint("Undefined term: " .. item .. " has no definition!");
           end;  -- if value.def = string
  
        end; -- else item not metadata
    end;   -- for item, value in pairs

    if     return_format == "string"
    then   return table.concat(slurped, "\n");
    elseif not return_format or return_format == "table"
    then   return slurped; 
    elseif return_format == "yaml"
    then   return lyaml.load( table.concat(slurped, "\n")), true;
    end;
end;

format_yaml.character = function(yaml, return_format) -- character statblock
  if type(yaml_structure) ~= "table"
  then eprint("YAML structure is not table. (Parse it first?)");
  end;

  if not return_format == "table" or not return_format == "text"
  then eprint("Unknown return format to format_yaml.character:", return_format);
  end;

  vprint("Found a character in YAML!");

  local slurped   = "";
  local yaml_data = file.yaml_structure;
  local bio       = yaml_data.bio;
  local history   = yaml_data.history;
  local powers    = yaml_data.powers;
  local stats     = yaml_data.stats;
  local weapons   = yaml_data.weapons;

  local function slurp_bio_field(yfield, caption)
  vprint("generating bio line " .. caption);
  if bio[yfield] then slurped = slurped .. "\n- **" .. caption .. ":** " .. bio[yfield]; end;
  end;

  local function slurp_stats_field(yfield, caption)
  local field_path = split(yfield, ":");
  local value = stats[yfield];
  if     type(value) ~= "table" and #field_path == 1 then slurped = slurped.."\n- **"..caption..":** "..stats[yfield];
  elseif #field_path == 1 and value[1] == "*"        then value   = table.concat(value, ", ");
  elseif #field_path > 1                             then for i, field in pairs(value) do value = value[field]; end;
  end;
  if   value
  then vprint("generating stat line " .. caption);
  slurped = slurped .. string.rep("  ", 2 * (#field_path)) .. "\n- **" .. caption .. ":**" .. value;
  end;
  end;

  slurped = slurped .. "\n# " .. (metadata.title or "Character");

  if   metadata.anchor or metadata.classes
  then slurped = slurped .. " {";
  if metadata.anchor   then slurped = slurped .. "#" .. metadata.anchor  end;
  if metadata.classes then slurped = slurped .. " ." .. metadata.classes end;
  slurped = slurped .. "}\n";
  end;

  if   bio
  then vprint("generating bio block");
  slurped = slurped .. "::::::::::: { .bio } ::::::::::::::::"
  slurp_bio_field("real_name",    "Real Name"   );
  slurp_bio_field("occupation",   "Occupation"  );
  slurp_bio_field("legal_status", "Legal Status");

  if   bio.gender and bio.gender.desc and bio.gender.pronouns
  then slurped = slurped .. "\n- **Gender:**" .. bio.gender.desc .. " (" ..  bio.gender.pronouns .. ")";
  else slurp_bio_field("gender",     "Gender");
  slurp_bio_field("pronouns", "Pronouns");
  end;

  slurp_bio_field("identity",             "Identity");
  slurp_bio_field("former_aliases", "Former Aliases");
  slurp_bio_field("place_of_birth", "Place of Birth");
  slurp_bio_field("marital_status", "Marital Status");

  if   bio.height or bio.weight or bio.eyes or bio.hair
  then vprint("generating bio2 block");
  slurped = slurped .. ":::::::::::::::::::::::::::::::::::::";
  slurped = slurped .. "::::::::::: { .bio2 } :::::::::::::::";
  slurp_bio_field("height", "Height");
  slurp_bio_field("weight", "Weight");
  slurp_bio_field("eyes",   "Eyes"  );
  slurp_bio_field("hair",   "Hair"  );
  end; 
  slurped = slurped .. ":::::::::::::::::::::::::::::::::::::";
  end; -- if bio
  if history then slurped = slurped .. "\n\n**History:**\n" .. history; end;
  if powers  then slurped = slurped .. "\n\n**Powers:**\n"  .. powers;  end;
  if weapons then slurped = slurped .. "\n\n**Weapons:**\n" .. weapons; end;
  if stats
  then vprint("generating stats block");
  slurped = slurped .. "::::::::::: { .stats } ::::::::::::::";
  if metadata.title then slurped = slurped .. "\n\n## " .. metadata.title .. "\n\n"; end;
  slurp_stats_field("class",                "Class"      );
  slurp_stats_field("approaches",           "Approaches" );
  slurp_stats_field("approaches:action",    "Action"     );
  slurp_stats_field("approaches:adventure", "Adventure"  );
  slurp_stats_field("approaches:detective", "Detective"  );
  slurp_stats_field("approaches:mystery",   "Mystery"    );
  slurp_stats_field("approaches:suspense",  "Suspense"   );
  slurp_stats_field("health",               "Health"     );
  slurp_stats_field("might",                "Might"      );
  slurp_stats_field("power_words",          "Power Words");
  slurp_stats_field("power_words:core",     "Core"       );
  slurp_stats_field("power_words:personal", "Personal"   );
  slurp_stats_field("power_words:nova",     "Nova"       );
  slurp_stats_field("abilities:*",          "Abilities"  );
  slurp_stats_field("skills:*",             "Skills"     );
  slurp_stats_field("ideals:*",             "Ideals"     );
  slurped = slurped .. ":::::::::::::::::::::::::::::::::::::";
  end;
  
end;

format_yaml.list = 
function(yaml, return_format) -- a list of people, places, or things
  if type(yaml_structure) ~= "table"
  then eprint("YAML structure is not table. (Parse it first?)");
  end;

   local markdown_section_started = false;
end;

format_yaml.place = 
function(yaml, return_format) -- a place
  if type(yaml_structure) ~= "table"
  then eprint("YAML structure is not table. (Parse it first?)");
  end;

  local markdown_section_started = false;
end;

format_yaml.unknown = 
function(yaml, unknown_xformat, file, return_format) -- unknown xformat
  if type(yaml_structure) ~= "table"
  then eprint("YAML structure is not table. (Parse it first?)");
  end;

  eprint("Unknown format for yaml block in " .. file .. ": " .. unknown_xformat);
end;

local function get_file_type_from_name(filename)
  if     string.find(filename, "%" .. CONFIG.ext_yaml     .. "$") then return "yaml"
  elseif string.find(filename, "%" .. CONFIG.ext_markdown .. "$") then return "markdown"
  elseif string.find(filename, "%" .. CONFIG.ext_recipe   .. "$") then return "recipe"
                                                                  else return "unknown"
  end;
end;

