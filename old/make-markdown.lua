#!/usr/bin/lua

local CONFIG = {
  appname    = "make-markdown.lua",
  bin_dir    = "./bin",
  build_dir  = "./build",
  errors     = true,
  ext        = { 
                 yaml     = ".yaml",
                 recipe   = ".recipe",
                 markdown = ".md",
--               filter   = ".yaml"
                 filter   = ".yaml;.md",
               },
  ignore     = "(%.git|Makefile|%.test|%.|%.swp)",
  index      = "intro",
  logformat  = "  %-20s %-20s",
  out_suffix = ".md",
  outdir     = "./out",
  outfile    = "build",
  recipe     = "test",
  recipe_dir = "./",
  src_dir    = "./src",
  summary    = true,
  verbose    = true,
  yaml       = true,
  };

-- CONFIG.ext.filter = table.concat(CONFIG.ext, ";");

local lfs = require "lfs"
local cli =  require "cliargs";

local function slug(filename)
  filename = string.gsub(filename, "^%"  .. CONFIG.src_dir, "");
  for e, v in ipairs(CONFIG.ext)
  do  filename = string.gsub(filename, "%" .. v .. "$", "");
  end;
  filename = string.gsub(filename, "^/", "");
  filename = string.gsub(filename, "/$", "");
  return filename;
end;

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

-- =======================================================================================================================
-- code by GianlucaVespignani - 2012-03-04; 2013-01-26
-- Search files in a path, alternative in sub directory
-- @param dir_path string (";" for multiple paths supported)
-- @param filter   string - eg.: ".txt" or ".mp3;.wav;.flac"
-- @param s bool - search in subdirectories
-- @param pformat format of data - 'system' for system-dependent number; nil or string with formatting directives
-- @return  files, dirs - files and dir are tables {name, modification, path, size}

function file_search(dir_path, filter, s, pformat)
    -- === Preliminary functions ===
    -- comparison function like the IN() function like SQLlite, item in a array
    -- useful for compair table for escaping already processed item
    -- Gianluca Vespignani 2012-03-03

    local c_in = 
      function(value, tab)
        for k,v in pairs(tab)
        do  if v==value then return true end
        end
        return false
      end

    local string = string  -- http://lua-users.org/wiki/SplitJoin
    function string:split(sep)
      local sep, fields = sep or ":", {}
      local pattern = string.format("([^%s]+)", sep)
      self:gsub(pattern, function(c) fields[#fields+1] = c end)
      return fields
    end

    local ExtensionOfFile = 
      function(filename)
        local rev = string.reverse(filename)
        local len = rev:find("%.")
        local rev_ext = rev:sub(1,len)
        return string.reverse(rev_ext)
      end

    -- === Init ===
    dir_path   = dir_path or cwd
    filter     = string.lower(filter) or "*"
    extensions = filter:split(";")
    s          = s or false -- as /s : subdirectories

    if pformat == 'system' -- if 4th arg is explicity 'system', then return the system-dependent number representing date/time
    then os_date = function(os_time) return os_time end;
    else -- if 4th arg is nil use default, else it could be a string that respects the Time formatting directives
         pformat = pformat or "%Y/%m/%d" -- eg.: "%Y/%m/%d %H:%M:%S"
         os_date = function(os_time) return os.date(pformat, os_time) end
    end

    -- == MAIN ==
    local files = {}
    local dirs  = {}
    local paths = dir_path:split(";")
    for i,path in ipairs(paths) 
    do  for f in lfs.dir(path) do
        do  if f ~= "." and f ~= ".." 
            then local attr = lfs.attributes ( path.."/"..f )
                 if   attr.mode == "file" 
                 then if   filter=="*"
                           or c_in( string.lower( ExtensionOfFile(f) ), extensions)
                      then table.insert(files,{
                             name = f,
                             modification = os_date(attr.modification) ,
                             path = path.."/",
                             size = attr.size
                           })
                      end
                 else if   filter=="*" 
                      then -- if attr.mode == "directory" and file ~= "." and file ~= ".." then end
                           table.insert(dirs,{
                             name = f ,
                             modification = os_date(attr.modification) ,
                             path = path.."/",
                             size = attr.size
                           })
                      end
                      if   s and attr.mode == "directory" 
                      then local subf={}
                           local subd={}
                           subf, subd = file_search(path.."/"..f, filter, s, pformat)
                           for i,v in ipairs(subf) 
                           do  table.insert(files,{
                                 name = v.name ,
                                 modification = v.modification ,
                                 path = v.path,
                                 size = v.size
                               })
                           end
                           for i,v in ipairs(subd) 
                           do  table.insert(dirs,{
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
    end;
end

--[=[ ABOUT ATTRIBUTES
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

local lyaml = require "lyaml";

local function parse_yaml_to_tree(str)
  if not str then return false, nil end;

  if type(str) == "table" then str = table.concat(str, "\n"); end;

  if type(str) ~= "string" then eprint("Error: yaml to parse is not string"); end;

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

local function handle_yaml_file(yaml_tree)
  
end;

-- http://lua-users.org/wiki/FileInputOutput

local function path_level(path)
  pathslug = slug(path);
  local pathdirs = split(path, "/");
  local level = #pathdirs;
  if string.find(path, CONFIG.index) 
     then vprint("*** found an index", path) 
     else level = level + 1;
     end;
  return level;
  end;

-- see if the file exists
local function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

local function get_file_data_from_name(file, no_parse)
  local f = {};

  f.no_parse = no_parse;

  f.base = file;
  local filename = f.base;

  if     string.find(f.base, "%" .. CONFIG.ext.yaml     .. "$") then f.type = "yaml";
  elseif string.find(f.base, "%" .. CONFIG.ext.markdown .. "$") then f.type = "markdown";
  elseif string.find(f.base, "%" .. CONFIG.ext.recipe   .. "$") then f.type = "recipe";
  else   f.type = nil;
  end;

  f.path_level = path_level(filename);

  filename = string.gsub(filename, "^%" .. CONFIG.src_dir, "");

  if     f.type == "markdown" then filename = string.gsub(filename, "%" .. CONFIG.ext.markdown .. "$", "");
  elseif f.type == "yaml"     then filename = string.gsub(filename, "%" .. CONFIG.ext.yaml     .. "$", "");
  elseif f.type == "recipe"   then filename = string.gsub(filename, "%" .. CONFIG.ext.recipe   .. "$", "");
  end;

  filename   = string.gsub(filename, "^/", "");
  filename   = string.gsub(filename, "/$", "");
  f.stub     = filename;
  f.yaml     = f.stub .. CONFIG.ext.yaml;
  f.markdown = f.stub .. CONFIG.ext.markdown;
  f.recipe   = f.stub .. CONFIG.ext.recipe;

  vprint("looking for:", filename);

  if     file_exists(f.recipe)   
  then   f.exists = true; 
         f.name = f.recipe;   
         vprint("recipe file found:", f.name);
  elseif file_exists(f.yaml)     
  then   vprint("no recipe file", f.recipe);
         f.exists = true; 
         f.name = f.yaml;     
         vprint("yaml found:", f.name);
  elseif file_exists(f.markdown) 
  then   vprint("no yaml", f.yaml);
         f.exists = true; 
         f.name = f.markdown; 
         vprint("markdown", f.name);
  end;

  return f;

end;

local function get_yaml_metadata(yaml_tree) return yaml_tree.metadata; end;

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
local function slurp(filename, no_parse, yaml_ok)
  file = get_file_data_from_name(filename, no_parse);

  vprint("file.type is:", file.type);

  if not file.exists then vprint("file doesn't exist:", file.name); return nil end;

  lines = {}
  for line in io.lines(file.name) do lines[#lines + 1] = line end
  local slurped = "\n" .. table.concat(lines, "\n") .. "\n";
  

  if   file.type == "yaml"
  then 
       local success, yaml_tree = parse_yaml_to_tree(slurped); 
       if   not success 
       then eprint("Error: parsing yaml from ", file.name); 
            os.exit(1); 
       end;
       slurped        = yaml_tree;
       file.no_parse  = true;
       local metadata = get_yaml_metadata(yaml_tree);
       if not metadata
       then   eprint("Error: no metadata found in YAML", file.name);
       end;
  end;

  if file.no_parse
     then -- normalize the number of octothorpes
   
     local octo, _ = string.match(slurped, "(#+)");
     local octo_level = string.len(octo or "");

     if octo_level > 1
        then local mod = octo_level - 1;
             local oldhash = "\n" .. string.rep("#", mod);
             local newhash = "\n";
             slurped = string.gsub(slurped, oldhash, newhash);
        end;

      local level = file.path_level;
      vprint(file.slug, "level should be " .. level .. ", is " .. octo_level);
      if level >= 1
         then local mod = level - 1;
              local oldhash = "\n#";
              local newhash = "\n#" .. string.rep("#", mod)
              slurped = string.gsub(slurped, oldhash, newhash);
              slurped = string.gsub(slurped, "\n#####+", "\n#####");
              -- handle the H6 headings
              slurped = string.gsub(slurped, "\n:#", "\n######");
         end; -- if
  end;
  return slurped;
end

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
  vprint("CONFIG.ext.filter", CONFIG.ext.filter);
  local files, dirs = file_search(CONFIG.src_dir, CONFIG.ext.filter, true)
  for k, v in pairs(dirs)
  do  if   string.find(v.path, CONFIG.ignore) 
      then vprint("Skipping directory", v.name); 
           break 
      end;
      local filename = slug(v.path .. v.name);
      DIRS[filename] = true;
      print("Learning directory location", filename);
  end;
  
  for k, v in pairs(files)
  do  if string.find(v.path, CONFIG.ignore) then break end;
      local found = true;
      -- vprint("> considering ", v.name);
      for _, ext in pairs(CONFIG.ext)
      do  -- vprint(">> Does it match:", ext);
          if   string.find(v.name, ext)
          then found = true;
               -- vprint(">>> DING DING DING", ext);
          else -- vprint(">>> womp womp");
          end;
      end;
      if string.find(v.name, "%" .. CONFIG.ext.markdown .. "$")
      then --
           local filename = slug(v.path..v.name);
           local pathdirs = split(filename, "/");
           -- vprint(">> filename is", ">>> " .. filename);
           FILES[filename] = true;
           vprint("keeping filename", filename);
           -- vprint(">> it's a keeper!", ext);
      elseif string.find(v.name, "%" .. CONFIG.ext.yaml .. "$")
      then local filename = slug(v.path..v.name);
           local pathdirs = split(filename, "/");
           FILES[filename] = true;
           vprint("keeping filename", filename);
      end;
  end;
  -- vprint("#DIRS",  #DIRS);
  -- vprint("#FILES", #FILES);
  vprint("#files",    #files);
  vprint("#dirs",     #dirs);
  return files, dirs;
end;

local TEMPLATE = { };

local function parse_recipe_line(line)
  local asterisk, template = false;
  line = string.gsub(line, "/$", "");
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
    then   local outfile = string.gsub(line, "^>%s*", "");
                 outfile = string.gsub(outfile, ".out$", "");
           CONFIG.outfile = outfile;
           vprint("setting the output file", "\"" .. outfile .. "\"");
    elseif string.find(line, "^#")
    then 
           vprint("comment", line);
    elseif DIRS[line] 
    then   vprint("found a directory", line);
           vprint("looking for index", line .. "/" .. CONFIG.index);
           parse_recipe_line(line .. "/" .. CONFIG.index);
  
           if   template
           then vprint("found a template call", line .. "/::" .. template);
                for k, v in pairs(TEMPLATE[template]) 
                do  parse_recipe_line(v(line));
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
                    parse_recipe_line(line .. "/" .. sl)
                end; -- for
           end; -- if asterisk
    elseif FILES[line] and not USED[line]
    then   vprint("found an entry", line);
           table.insert(BUILD, CONFIG.src_dir .. "/" .. line .. CONFIG.ext.markdown);
           local md_file   = CONFIG.src_dir .. "/" .. line .. CONFIG.ext.markdown;
           local yaml_file = CONFIG.src_dir .. "/" .. line .. CONFIG.ext.yaml;
           if     file_exists(yaml_file) then table.insert(BUILD, yaml_file);
           elseif file_exists(md_file)   then table.insert(BUILD, md_file);
           end;
           USED[line] = true;
    elseif FILES[line] and USED[line]
    then   vprint("skipping entry", line);
    else   -- vprint("this doesn't exist", line);
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

cli:flag("-v, --verbose",     "be more wordy than usual",  false);
cli:flag("-q, --quiet",       "don't summarize each step", false);
cli:flag("-l, --list",        "list the known recipes",    false);
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
local recipe_src = slurp(CONFIG.recipe_dir .. "/" .. CONFIG.recipe .. CONFIG.ext.recipe, true);

if not recipe_src then print("Error: Can't read that recipe file"); os.exit() end
local recipe = split(recipe_src, "[\r\n]+");
sprint("recipe read", #recipe .. " lines");

-- parse the filesystem tree
sprint("Loading the filesystem map", "source = " .. CONFIG.src_dir );
load_fs();

-- parse the recipe
for _, i in pairs(recipe) do parse_recipe_line(i) end;

vprint("=========== start ==============");
for i, v in pairs(BUILD) do print(i, v) end;
vprint("============ end ===============");

sprint("loading content files now", "> " .. #BUILD .. " files");
for i, v in ipairs(BUILD) do vprint("Loading", v); outtxt = outtxt .. slurp(v) end;
sprint("All loaded!");

-- save the output
local outfile = CONFIG.build_dir .. "/" .. CONFIG.outfile .. CONFIG.out_suffix;

sprint("Writing to file", outfile);
sprint("Content size is", string.len(outtxt) .. " characters");
dump(outfile, outtxt);

-- notify of errors
sprint("number of errors", (#ERR or 0) .. " error" .. ((#ERR and #ERR == 1) and "" or "s" ));
if #ERR 
   then for i, v in pairs(ERR) 
        do local errmsg = "Not located:";
           if   string.find(v, CONFIG.index .. "$") 
           then eprint("Warning: No index", v); 
           else eprint(errmsg,              v)
           end;
        end; -- do
   end; -- if #ERR
