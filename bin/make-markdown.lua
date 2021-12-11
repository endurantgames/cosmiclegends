#!/usr/bin/lua

local CONFIG = {
  appname      = "make-markdown.lua",
  bin_dir      = "./bin",
  build_dir    = "./build",
  errors       = true,
  extension    = ".md",
  extensions   = ".md;.yaml",
  ext_markdown = ".md",
  ext_yaml     = ".yaml",
  ext_recipe   = ".recipe",
  ignore       = "^(%.git|Makefile|%.test|%.)",
  index        = "intro",
  logformat    = "  %-30s %-40s",
  out_suffix   = ".md",
  outdir       = "./out",
  outfile      = "build",
  recipe       = "clu",
  recipe_dir   = "./",
  src_dir      = "./src",
  summary      = true,
  verbose      = false,
  };

local lfs   = require "lfs"
local cli   = require "cliargs";
local lyaml = require "lyaml";

local function parse_yaml(str)
  if not str then return false, nil end;
  local yaml_structure = lyaml.load(str);

  if   yaml_structure 
  then return true,  yaml_structure 
  else return false, nil
  end;

end

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

-- =============================================================================================================
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

    local string = string    -- http://lua-users.org/wiki/SplitJoin
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
    dir_path   = dir_path or cwd
    filter     = string.lower(filter) or "*"
    extensions = filter:split(";")
    s = s or false -- as /s : subdirectories

    if pformat == 'system' then    -- if 4th arg is explicity 'system', then return the system-dependent number representing date/time
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
    local dirs  = {}
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
                    if filter=="*" then            -- if attr.mode == "directory" and file ~= "." and file ~= ".." then end
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

    --[=[    ABOUT ATTRIBUTES
> for k,v in pairs(a) do print(k..' \t'..v..'') end
dev     2
change  1175551262    -- date of file Creation
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
  filename = string.gsub(filename, "^%" .. CONFIG.src_dir,             "");
  filename = string.gsub(filename, "%"  .. CONFIG.ext_markdown .. "$", "");
  filename = string.gsub(filename, "%"  .. CONFIG.ext_yaml ..     "$", "");
  filename = string.gsub(filename, "^/",                               "");
  filename = string.gsub(filename, "/$",                               "");
  return filename;
end;

local function path_level(path)
  if type(path) ~= "string" then return 0 end;
  vprint("path is", path);
  path = slug(path);
--  vprint("considering this", path);
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
end -- function file_exists

-- local function slurp_yaml(filename)
--   if   CONFIG.yaml
--   then if file_exists(filename)
--        then vprint("Gonna try to load YAML from", filename);
--             local yaml_file = slurp(filename, true, true, true);
--             local yaml_structure = lyaml.load(yaml_file);
--             if   yaml_structure 
--             then vprint("YAML loaded!");
--                  return yaml_structure, true 
--             else eprint("YAML not loaded :(");
--                  return nil, false 
--             end;
--        else eprint("Not loading YAML from", filename);
--             eprint("File not found",        filename);
--        end;
--   end; -- if CONFIG.yaml
-- end; -- function slurp_yaml

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
local function slurp(filename, no_parse, no_yaml, return_format)

  string.gsub(filename,"\n$",""); -- remove extra newlines at the end

  local file = {};
  file.base           = filename;
  file.stub           = slug(filename);
  local file_yaml     = "(no yaml)";
  local file_markdown = file;

  -- first let's identify what kind of file we have
  if     string.find(filename, "%" .. CONFIG.ext_yaml .. "$")
  then   file.stub      = file.stub:gsub("%" .. CONFIG.ext_yaml .. "$", "");
         file.yaml      = filename;
         file.ext       = CONFIG.ext_yaml;
         file.is_md     = false;
         file.is_yaml   = true;
         file.markdown  = file.stub .. CONFIG.ext_markdown;
         if return_format == "string" then return_format = "yaml" end;
         vprint("Identified " .. file.base .. " as:", "YAML");
  elseif string.find(filename, "%" .. CONFIG.ext_markdown .. "$")
  then   file.stub      = file.stub:gsub("%" .. CONFIG.ext_markdown .. "$", "");
         file.yaml      = file.stub .. CONFIG.ext_yaml;
         file.markdown  = file.base;
         file.ext       = CONFIG.ext_markdown;
         vprint("Identified " .. file.base .. " as:", "Markdown");
  elseif string.find(filename, "%" .. CONFIG.ext_recipe .. "$")
  then   file.stub      = file.stub:gsub("%" .. CONFIG.ext_recipe .. "$", "");
         file.recipe    = filename;
         file.is_recipe = true;
         file.markdown  = "(no markdown)";
         file.yaml      = "(no yaml)";
         file.ext       = CONFIG.ext_recipe;
         vprint("Identified " .. file.base .. " as:", "Recipe");
  end;

  vprint("looking for: " .. file.yaml .. " or " .. file.markdown .. " (" .. file.base ..")");

  if     file.is_recipe and file_exists(file.base)     then vprint("File found: "   ..file.base    );
  elseif file.is_yaml   and file_exists(file.yaml)     then vprint("File found: "   ..file.yaml    );
  elseif file.is_md     and file_exists(file.markdown) then vprint("File found: "   ..file.markdown);
  elseif file.is_md     and file_exists(file.yaml)     
  then   vprint("Markdown not found: ", file.markdown);
         vprint("File YAML found: ",    file.yaml    );
         file.is_md, file.is_yaml = false, true;       
  else   eprint("Couldn't find: "..file.base.." or "..file.yaml.." or "..file.markdown);
  end;

  if   file.is_yaml and CONFIG.yaml and not no_yaml
  then -- load the YAML

       sprint("This is a YAML file:", file.yaml);
       file.yaml_structure, file.yaml_loaded = slurp(file.yaml, nil, nil, "yaml");
       if   file.yaml_structure and file.yaml_loaded
       then -- create the text representation
            -- if   not file.yaml_structure 
            -- then vprint("no yaml_structure!"); 
            -- else vprint( "we have some structure:", #file.yaml_structure .. " blocks worth"); 
            --      -- for k, v in pairs(file.yaml_structure) do vprint(tprint(v, 2)); end;
            -- end;

            local slurped = {};

            local metadata;

            if file.yaml_structure[1] and file.yaml_structure[1].metadata
            then vprint(tprint(file.yaml_structure[1].metadata, 2));
                 metadata = file.yaml_structure[1].metadata;
            else vprint(tprint(file.yaml_structure[1], 2));
            end;
   
            if   metadata  
            then -- local virtfile = metadata.file
                 -- local htitle   = virtfile and virtfile.title      or "YAML Data"
                 -- local hlevel   = virtfile and virtfile["h-level"] or 1;
                 -- local anchor   = virtfile and virtfile.anchor;
                 -- local class    = virtfile and virtfile["css class"];
                 -- local plevel   = path_level(file.base);
   
                 -- if   plevel > hlevel
                 -- then vprint(slug(file.stub), "should be " .. plevel .. ", is " .. hlevel);
                 --      hlevel = plevel + hlevel - 1;
                 -- end; -- if plevel
   
                 -- slurped = slurped .. "\n" .. string.rep("#", hlevel);
                 -- slurped = slurped .. " " .. htitle;

                 if   anchor or class
                 then -- drop a curly brace
                      slurped = slurped .. " {"; 

                      if   anchor
                      then slurped = slurped .. " #" .. anchor .. " "; 
                      end; -- if anchor

                      if   class  
                      then slurped = slurped .. " ." .. class  .. " "; 
                      end; -- if class

                      slurped = slurped .. " }\n"; -- closing curly brace
                 end; -- if anchor or class
            end; -- if metadata and metadata.file

            local xformat = nil;
            local defaults = {};

            if not metadata
            then vprint("No metadata found.");
            else vprint("metadata found!   ");
            end;

            if   metadata and metadata["x-format"] 
            then xformat = metadata["x-format"]; 
            else vprint("No x-format found.");
            end; -- if metadata.x-format

            if   metadata and metadata.default     
            then defaults = metadata.default;     
            end; -- if metadata.default

            -- x-formats we recognize --------------------------------------------------------

            if   xformat == "glossary"
            then -- glossary file
                 local markdown_section_started = false;
                 for item, value in pairs(yaml_structure)
                 do  vprint("Found a glossary file:")
                     local term, def = "", "";
                     local indent = "     ";
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

            elseif xformat == "character"
            then   -- character statblock
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
                      if   bio[yfield] then slurped = slurped .. "\n- **" .. caption .. ":** " .. bio[yfield]; end;
                   end;

                   local function slurp_stats_field(yfield, caption)
                         local field_path = split(yfield, ":");
                         local value = stats[yfield];
                         if     type(value) ~= "table" and #field_path == 1 then slurped = slurped .. "\n- **" .. caption .. ":** " .. stats[yfield]; 
                         elseif #field_path == 1 and value[1] == "*"        then value = table.concat(value, ", ");
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
                   
            elseif xformat == "list"
            then   -- a list of people, places, or things
                   local markdown_section_started = false;
            elseif xformat
            then   eprint("Unknown format for yaml block in " .. file .. ": " .. xformat);
            end; -- if xformat
    end -- if   yaml_structure and yaml_loaded
    else lines = {};
         for line in io.lines(file.base) 
         do  lines[#lines + 1] = line 
         end; -- for line in io.lines(file.base)
       
         local slurped = "\n" .. table.concat(lines, "\n") .. "\n";
       
         if   not no_parse
         then -- normalize the number of octothorpes
              local octo, _    = string.match(slurped, "(#+)");
              local octo_level = string.len(octo or "");
               if   octo_level > 1
               then local mod     = octo_level - 1;
                    local oldhash = "\n" .. string.rep("#", mod);
                    local newhash = "\n";
                    slurped       = string.gsub(slurped, oldhash, newhash);
               end; -- if octo_leel
          
               local level = path_level(file);
               -- vprint(slug(file), "### should be " .. level .. ", is " .. octo_level);
          
               if   level >= 1
               then local mod = level - 1;
                    local oldhash = "\n#";
                    local newhash = "\n#" .. string.rep("#", mod)
                    slurped = string.gsub(slurped, oldhash, newhash);
                    slurped = string.gsub(slurped, "\n#####+", "\n#####");
                    -- handle the H6 headings
                    slurped = string.gsub(slurped, "\n:#", "\n######");
               end; -- if level
       
               if is_markdown
               then slurped = slurped .. "<!-- source file of preceeding: " .. file .. " -->"
               end;
         end; -- if not no_parse

         return slurped;
        
  end; -- if is_yaml

end; -- function slurp
   
local function get_file_contents(filename, no_parse, no_yaml, return_format)
  if   return_format ~= "string" and return_format ~= "table" and return_format ~= "yaml table"
  then eprint("Error: invalid return_format, return_format);
       return nil;
  end;
end;

local function dump_to_file(file, contents)
      local f = io.open(file, "wb");
      f:write(contents);
      f:close();
end; -- function dump_to_file

local outtxt = ""; local FILES  = {}; local DIRS   = {};
local BUILD  = {}; local USED   = {}; local ERR    = {};

local function load_fs()
  files, dirs = file_search(CONFIG.src_dir, "*", true)
  for k, v in pairs(dirs)
    do  if   string.find(v.path, CONFIG.ignore) 
        then vprint("Skipping directory", v.name); 
             break 
        end;
        local filename = slug(v.path .. v.name);
        DIRS[filename] = true;
        vprint("Learning directory location", filename);
    end; -- for k, v
  
  for k, v in pairs(files)
  do --
     if     string.find(v.path, CONFIG.ignore) 
     then   break 
     elseif string.find(v.name, "%" .. CONFIG.ext_markdown .. "$") 
         or string.find(v.name, "%" .. CONFIG.ext_yaml     .. "$")
     then   --
            local filename  = slug(v.path..v.name);
            local pathdirs  = split(filename, "/");
            FILES[filename] = true;
     end; -- if markdown or yaml
  end; -- for k, v
  return files, dirs;
end; -- function load_fs

local TEMPLATE = {};

local function add_line(line)
  vprint("ADD LINE BY TEXT: ", line);

  if   USED[line]
  then vprint("trying to add line [", line, "] but it's already used");
  end;

  USED[line] = true;

  if     FILES[line]
  then   vprint("found a FILES entry for: ", line);

         local file_yaml = CONFIG.src_dir .. "/" .. line .. CONFIG.ext_yaml;
         local file_md   = CONFIG.src_dir .. "/" .. line .. CONFIG.ext_markdown;

         if     file_exists(file_md)   then table.insert(BUILD, file_md);
         elseif file_exists(file_yaml) then table.insert(BUILD, file_yaml);
         end;

         USED[line] = true;
  elseif FILES[line] and USED[line]
  then   --
         vprint("skipping entry", line);
  else   --
         eprint("this doesn't exist", line);
  end; -- if FILES[line]
end;

local function parse_line(line)
  vprint("=====================================================================");
  vprint("PARSE LINE", line);
  local asterisk, template = false;
  line = string.gsub(line, "/$", ""); -- strip extraneous ending slash: file/ -> file

  if   string.find(line, "/%*$")
  then asterisk = true;
       line = string.gsub(line, "/%*$", "");
       vprint("Found an asterisk: " .. line);
  end; -- if string.find(line)

  if   string.find(line, "/?::[a-z]+$")
  then vprint("looks like a template", line);
       template = string.match(line, "/?::([a-z]+)$");
       vprint("i think it's this template", template);
       line = string.gsub(line, "/?::[a-z]+$", "");

       if   not TEMPLATE[template] 
       then template = nil; 
            vprint("the template doesn't exist")
       else vprint("the template DOES exist!")
       end; -- if not TEMPLATE[template]

  end; -- if matches template syntax

  if string.find(line, "^>")
  then -- found an output redirect line
         local outfile = string.gsub(line, "^>%s*", "");
               outfile = string.gsub(outfile, ".out$", "");
         CONFIG.outfile = outfile;
         vprint("setting the output file", "\"" .. outfile .. "\"");
  elseif string.find(line, "^#")
  then   -- found a comment
         vprint("comment", line);
  elseif DIRS[line] 
  then   --
         vprint("found a directory", line);
         vprint("looking for index", line .. "/" .. CONFIG.index);
         parse_line(line .. "/" .. CONFIG.index);
  
         if template
         then vprint("found a template call", line .. "/::" .. template);
              for k, v in pairs(TEMPLATE[template]) 
              do  parse_line(v(line));
              end; -- for k, v
          end; -- if template
   
          if asterisk 
          then vprint("found a /* construction", line .. "/*");
               local dir = CONFIG.src_dir .. "/" .. line;
               vprint("looking for files in ", dir)
               local md_files, _ = file_search(dir, CONFIG.extensions);
   
               vprint("found this many", #md_files .. " files");
               for k, v in pairs(md_files)
               do  local sl = v.name;
                   sl = string.gsub(sl, "%" .. CONFIG.ext_markdown .. "$", "");
                   sl = string.gsub(sl, "%" .. CONFIG.ext_yaml     .. "$", "");
                   parse_line(line .. "/" .. sl)
               end; -- for k, v
           end; -- if asterisk
   
    else add_line(line);
    end;
end; 


local function recipe_list()
  local files, dirs = file_search(CONFIG.recipe_dir, CONFIG.ext_recipe, false)
  sprint("Listing Recipes:", #files .. " known");
  sprint("Recipe directory", CONFIG.recipe_dir);
  for k, v in pairs(files) 
  do  print(
         string.format(
           CONFIG.logformat, 
           v.path .. v.name,  
           CONFIG.bin_dir .. "/" .. CONFIG.appname .. " " .. string.gsub(v.name, CONFIG.ext_recipe, "")
         )
       ); 
  end; -- for k, v
          
  os.exit(); -- exits
end; -- function recipe_list

-- ===================================
-- Command line interface
-- https://lua-cliargs.netlify.com/#/
-- ===================================

cli:set_name(CONFIG.appname);
cli:set_description("it creates the .md files we need");

cli:splat("RECIPE", "the recipe to build", "", 1);
-- cli:argument("RECIPE", "the recipe to build");

cli:option("-o, --outfile=OUTFILE", "specify the outfile");

cli:flag("-v, --verbose",     "be more wordy than usual",  false);
cli:flag("-q, --quiet",       "don't summarize each step", false);
cli:flag("-l, --list",        "list the known recipes",    false);
cli:flag("-y, --yaml",        "parse YAML files",           true); -- true = default to ON
cli:flag("-e, --[no-]errors", "show errors",                true); -- true = default to OFF 

local args, err = cli:parse(arg);
if not args then cli:print_help(); os.exit(1); end;
if err then print(string.format("%s: %s", cli.name, err)); os.exit(1); end;

if args and args.list then recipe_list() end;

if args.quiet   then CONFIG.summary = false else CONFIG.summary = true;  end;
if args.verbose then CONFIG.verbose = true  else CONFIG.verbose = false; end;
if args.errors  then CONFIG.errors  = true  else CONFIG.errors  = false; end;
if args.yaml    then CONFIG.yaml    = true  else CONFIG.yaml    = false; end;

if   args.RECIPE  
then CONFIG.recipe  = args.RECIPE;
     vprint("args.RECIPE is " .. args.RECIPE);
     CONFIG.outfile = args.RECIPE;
end; -- if args.RECIPE

if args.outfile then CONFIG.outfile = args.outfile end;

-- =======================================
-- Everything above this is initialization
-- =======================================
-- =======================================
-- =======================================
-- =======================================

-- start run -----------------------------
vprint("Running in verbose mode");
sprint("Showing summaries");

-- read the recipe -----------------------
sprint("reading recipe", CONFIG.recipe or "NIL");
local recipe_src = slurp(CONFIG.recipe_dir .. "/" .. CONFIG.recipe .. CONFIG.ext_recipe, true, true, "string");

if not recipe_src then eprint("Can't read that recipe file: " .. (CONFIG.recipe or "NIL")); os.exit() end;

local recipe = split(recipe_src, "[\r\n]+");
sprint("recipe read", #recipe .. " lines");

-- parse the filesystem tree ---------------------------------------
sprint("Loading the filesystem map", "source = " .. CONFIG.src_dir );
load_fs();

-- parse the recipe ------------------------------------
for _, i in pairs(recipe) 
do  parse_line(i) 
end; -- for _, i in pairs(recipe)

-- list all the files ---------------------------------
-- (for debugging)
-- for i, v in pairs(FILES) do vprint("FILE:", i);  end; -- all the files we've found
-- for i, v in pairs(BUILD) do vprint("BUILD:", v); end; -- all that we've added to the build

-- slurp other files ----------------------------------
sprint("slurping other files now", #BUILD .. " files");
for i, v in pairs(BUILD) 
do  vprint("Slurping ", v);
    outtxt = outtxt .. (slurp(v, true, false)  or "");
end; -- for i, v

-- save the output ------------------------------------------------------------
local outfile = CONFIG.build_dir .. "/" .. CONFIG.outfile .. CONFIG.out_suffix;

sprint("Writing to file", outfile);
sprint("Content size is", string.len(outtxt) .. " characters");
dump_to_file(outfile, outtxt);

-- notify of errors -----------------------------------------------------------
sprint("number of errors", (#ERR or 0) .. " error" .. ((#ERR and #ERR == 1) and "" or "s" ));
if   #ERR 
then for i, v in pairs(ERR) 
     do local errmsg = "Alert: Missing file";
        if string.find(v, CONFIG.index .. "$") then errmsg = "Warning: Missing index"; end;
        eprint(errmsg, v)
     end; -- for i, v in pairs(ERR)
end; -- if #ERR

