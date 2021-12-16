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
  };

local lfs   = require "lfs"
local cli   = require "cliargs";
local lyaml = require "lyaml";   -- https://github.com/gvvaughan/lyaml

function yprint(tbl, comment)
  print("yprint!", comment);

  if type(tbl) ~= "table" then print("Error: not table"); os.exit(1); end;

  local yaml_table = lyaml.dump(tbl);
  if   not yaml_table
  then print("Error: no yaml_table");
       os.exit(1);
  else print(yaml_table);
  end;

  print("/yprint", comment);
end;

function tprint(tbl, indent)
  indent = indent or 1;

  if   type(tbl) ~= "table" 
  then print("Error: not a table"); 
       os.exit(1); 
  end;

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

-- =======================================================================================================================
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
        dir_path   = dir_path or cwd
        filter     = string.lower(filter) or "*"
        extensions = filter:split(";")
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
--  vprint("considering this", path);
  local pathdirs = split(path, "/");
  local level = #pathdirs;
  if   string.find(path, CONFIG.index) 
  then vprint("*** found an index", path) 
  else level = level + 1;
  end; -- if string.find
  return level;
end; -- function

-- see if the file exists
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

local function flatten_yaml_tree(yaml_tree, comment)
  vprint("About to start", "FLATTEN_YAML_TREE " .. comment);
  comment = comment or "yaml_tree(?)";
  if type(yaml_tree) ~= "table"
  then eprint("Error!", "type(" .. comment .. ") = " .. type(yaml_tree));
       vprint("Should be:", "table");
       os.exit(1);
  else vprint("It's a table so", "here's the tprint");
       vprint("==================", "before!");
       -- yprint(yaml_tree);
       tprint(yaml_tree);
       vprint("==================", "after!");
  end;

  local flat_tree = {};

--   for k, v in pairs(yaml_tree)
--   do  if   type(v) == "table"
--       then local values = {};
--            for _, val in pairs(v)
--            do  local valtype = type(val);
--                if   valtype == "table"
--                then local valsize = #val;
--                     table.insert(values, "(" .. valtype .. " of " .. valsize ..")");
--                     for i, p in pairs(val)
--                     do  print("> " .. i, p);
--                     end;
--                else table.insert(values, val)
--                end;
--                values = table.concat(values, ", ");
--            end;
--            print(k, "{ " .. values .. " }");
--       else print(k, v);
--       end;
--   end;
--   
     return yaml_tree;
--   vprint("", "__________________________");
--   vprint("#" .. comment, #yaml_tree);
--   for i, v in pairs(yaml_tree)
--   do  if type(v) == "table"
--       then vprint("#v is ...",      #v);
--            vprint("type(v) is ...", type(v));
--            vprint("===  tprint ===", comment .. "[" .. i .. "]");
--            tprint(v);
--            vprint("=== /tprint ===", comment .. "[" .. i .. "]");
--       else eprint("type(v) is ...", type(v) .. " :(");
--       end;
--       local key, value = v[1] or "(key)", v[2] or "(value)";
--       vprint("key = " .. key .. "; value = ", value);
--       flat_tree[key] = value;
--   end;
--   return flat_tree;
end;

local function get_node_from_yaml(yaml_tree, node, comment)
  if   not yaml_tree
  then eprint("Error, yaml_tree is", yaml_tree);
       os.exit(1);
  end;

  if   type(yaml_tree) ~= "table"
  then eprint("Error, yaml_tree is", type(yaml_tree)); 
       os.exit(1); 
  end;
  if   yaml_tree[node]
  then vprint("Found the node!", comment .. "[" .. node .. "]");
       return yaml_tree[node];
  else for k, v in pairs(yaml_tree)
       do print(k, v);
       end;
  end;
end;

local function yaml_error(yaml_tree, unknown_xformat, filename, return_text)
  return_text = return_text == nil or return_text;
  eprint("Unknown xformat:", unknown_xformat);
  eprint("> in file:", filename);
  if return_text then return "" else return {} end;
end;

local function yaml_common(yaml_tree)
  local metadata = yaml_common.metadata;
  return "";
end;

local function yaml_character(yaml_tree, return_text)
  return_text = return_text == nil or return_text;
  vprint("yaml xformat is:", "character");
  
  local slurped = yaml_common(yaml_tree);
end;

local function yaml_list(yaml_tree, return_text)
  return_text = return_text == nil or return_text;
  vprint("yaml xformat is:", "list");
  local slurped = yaml_common(yaml_tree);
end;

local function yaml_glossary(yaml_tree, return_text)
  vprint("yaml xformat is:", "=== GLOSSARY ===");
  return_text = return_text == nil or return_text;
  local flat_tree = flatten_yaml_tree(yaml_tree);
  vprint("number of entries:", #yaml_tree);
  local slurped = yaml_common(yaml_tree);
end;

local function yaml_place(yaml_tree, return_text)
  return_text = return_text == nil or return_text;
  vprint("yaml xformat is:", "place");
  local slurped = yaml_common(yaml_tree);
end;

local function yaml_group(yaml_tree, return_text)
  return_text = return_text == nil or return_text;
  vprint("yaml xformat is:", "group");
  local slurped = yaml_common(yaml_tree);
end;

local format_yaml     = {};
format_yaml.character = yaml_character;
format_yaml.list      = yaml_list;
format_yaml.glossary  = yaml_glossary;
format_yaml.place     = yaml_place;
format_yaml.group     = yaml_group;
format_yaml.unknown   = yaml_error;

local function slurp_yaml(filename)

  local function yprint(tab, comment)
    if   type(tab) ~= "table"
    then eprint("Error!", comment .. " is not a table");
    else local yaml_text = lyaml.dump(tab);
         vprint("=== start " .. comment .. " Yprint", "==============");
         print(yaml_text);
         vprint("=== end   " .. comment .. " Yprint", "==============");
    end;
  end;

  local function ttprint(tab, indent, comment)
    comment = comment or "";
    indent  = indent or 2;

    vprint("--- start " .. comment .. " tprint", "-------------");
    tprint(tab, indent);
    vprint("--- end   " .. comment .. " tprint", "-------------");
  end;

  if filename then vprint("Recognized as YAML location", filename); end;

  local yaml_source = slurp(filename, true);

  vprint("Reading YAML file now", yaml_source:len() .. " bytes");

  local yaml_tree   = {};
  local success     = false;
  local metadata    = {};
  local xformat;
  local slurped     = "\n<!-- above: " .. filename .. " -->\n";

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

  local flat_tree = flatten_yaml_tree(yaml_tree, "yaml_tree (initial)");

  metadata = flat_tree.metadata;

  if   yaml_tree and metadata
  then 
       vprint("YAML tree has metadata!");
       vprint("metadata type is", type(metadata));
       if   type(metadata) == "table"
       then vprint("It's a table!", "yes, a table!");
            for k, v in pairs(metadata)
            do  if type(v) == "table"
                then ttprint(v, 2, "metadata[" .. k .. "]");
                else vprint("metadata[" .. k .. "] = ", v);
                end;
            end;
       else eprint("ERROR: metadata is not", "a table :( :(");
       end;
  else eprint("YAML tree doesn't have",  "metadata :(");
       success = false;
       ttprint(yaml_tree, nil, "yaml_tree");
  end;
  
  -- local xformat = get_node_from_yaml(metadata, "x-format", "yaml_tree.metadata");
  
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
       slurped    = parse_func(yaml_tree, true);
  else vprint("Known x-format:",       xformat);
       vprint("Parsing with x-format", "format_yaml[" .. xformat .. "]");
       parse_func = format_yaml[xformat];
       slurped    = parse_func(yaml_tree, true);

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
    then   outtxt = outtxt .. slurp_yaml(v);
           vprint("slurping YAML", v);
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
