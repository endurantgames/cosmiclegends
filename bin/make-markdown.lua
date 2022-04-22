#!/usr/bin/lua

local g       = _G.g     or {};
local FUNC    = g.FUNC   or {};
local CONFIG  = g.CONFIG or {};

local function load(path, pkgname)
  package.path = path .. ";" .. package.path;
  require(pkgname);
end;

load("./bin/config.lua",                     "config");
load("./bin/?/load.lua",                     "func");
load("./bin/?/load.lua;./bin/modules/?.lua", "modules");

-- local tmp_pkg_path = package.path;
-- package.path  = "./bin/config.lua;./bin/?/load.lua/;./bin/?.lua;" .. package.path;

-- print(package.path); os.exit(0);

-- local blerp   = require("blerp"   ); assert(blerp,   "blerp is not loaded, of course" );
local config  = require("config"  ); -- assert(config,  "config is not loaded"           );
local func    = require("func"    ); -- assert(func,    "func is not loaded"             );
local modules = require("modules" ); -- assert(modules, "modules is not loaded"          );
local content = require("content" ); -- assert(content, "content is not loaded"          );
local lfs     = require("lfs"     ); assert(lfs,     "lfs is not loaded"              );
local lyaml   = require("lyaml"   ); assert(lyaml,   "lyaml is not loaded"            ); -- https://github.com/gvvaughan/lyaml
local inspect = require("inspect" ); assert(inspect, "inspect is not loaded"          ); -- https://github.com/kikito/inspect.lua
local cli     = require("cliargs" ); assert(cli,     "cli is not loaded"              ); -- https://github.com/amireh/lua_cliargs

-- local function nop(...) return ...; end; -- access to functions
--
assert(FUNC, "FUNC does not exist");
assert(FUNC.bucket, "FUNC.bucket does not exist");                       local BUCKET            = FUNC.bucket;
assert(FUNC.file, "FUNC.file does not exist");                           local FILE              = FUNC.file;
assert(FUNC.line, "FUNC.line does not exist");                           local LINE              = FUNC.line;
assert(FUNC.recipe, "FUNC.recipe does not exist");                       local RECIPE            = FUNC.recipe;
assert(FUNC.util, "FUNC.util does not exist");                           local UTIL              = FUNC.util;
assert(FUNC.yaml, "FUNC.yaml does not exist");                           local YAML              = FUNC.yaml;

assert(BUCKET.add, "BUCKET.add does not exist");                         local bucket_add        = BUCKET.add;
assert(BUCKET.contents, "BUCKET.contents does not exist");               local bucket_contents   = BUCKET.contents;
assert(BUCKET.count, "BUCKET.count does not exist");                     local bucket_count      = BUCKET.count;
assert(BUCKET.dump, "BUCKET.dump does not exist");                       local bucket_dump       = BUCKET.dump;
assert(BUCKET.exists, "BUCKET.exists does not exist");                   local bucket_exists     = BUCKET.exists;
assert(BUCKET.fetch, "BUCKET.fetch does not exist");                     local bucket_fetch      = BUCKET.fetch;
assert(BUCKET.test, "BUCKET.test does not exist");                       local bucket_test       = BUCKET.test;

assert(FILE.adjust_md_level, "FILE.adjust_md_level does not exist");     local adjust_md_level   = FILE.adjust_md_level;
assert(FILE.dump, "FILE.dump does not exist");                           local dump              = FILE.dump;
assert(FILE.exists, "FILE.exists does not exist");                       local file_exist        = FILE.exists;
assert(FILE.find, "FILE.find does not exist");                           local find_file         = FILE.find;
assert(FILE.map_src_fs, "FILE.map_src_fs does not exist");               local map_src_fs        = FILE.map_src_fs;
assert(FILE.path_level, "FILE.path_level does not exist");               local path_level        = FILE.path_level;
assert(FILE.search, "FILE.search does not exist");                       local file_search       = FILE.search;
assert(FILE.slurp, "FILE.slurp does not exist");                         local slurp             = FILE.slurp;

assert(LINE.mark_used, "LINE.mark_used does not exist");                 local mark_line_used    = LINE.mark_used;
assert(LINE.parse_recipe_line, "LINE.parse_recipe_line does not exist"); local parse_recipe_line = LINE.parse_recipe_line;
assert(LINE.was_used, "LINE.was_used does not exist");                   local was_used_line     = LINE.was_used;

assert(RECIPE.list, "RECIPE.list does not exist");                       local recipe_list       = RECIPE.list;

assert(UTIL.eprint, "UTIL.eprint does not exist");                       local eprint            = UTIL.eprint;
assert(UTIL.ignore, "UTIL.ignore does not exist");                       local ignore            = UTIL.ignore;
assert(UTIL.split, "UTIL.split does not exist");                         local split             = UTIL.split;
assert(UTIL.sprint, "UTIL.sprint does not exist");                       local sprint            = UTIL.sprint;
assert(UTIL.vprint, "UTIL.vprint does not exist");                       local vprint            = UTIL.vprint;
assert(UTIL.yprint, "UTIL.yprint does not exist");                       local yprint            = UTIL.yprint;

assert(YAML.unpack_tree, "YAML.unpack_tree does not exist");             local unpack_yaml_tree  = YAML.unpack_tree;

-- local bucket_add        = FUNC and FUNC.bucket and FUNC.bucket.add           or nop;
-- local bucket_contents   = FUNC and FUNC.bucket and FUNC.bucket.contents      or nop;
-- local bucket_count      = FUNC and FUNC.bucket and FUNC.bucket.count         or nop;
-- local bucket_dump       = FUNC and FUNC.bucket and FUNC.bucket.dump          or nop;
-- local bucket_exists     = FUNC and FUNC.bucket and FUNC.bucket.exists        or nop;
-- local bucket_fetch      = FUNC and FUNC.bucket and FUNC.bucket.fetch         or nop;
-- local bucket_test       = FUNC and FUNC.bucket and FUNC.bucket.test          or nop;
-- local adjust_md_level   = FUNC and FUNC.file   and FUNC.file.adjust_md_level or nop;
-- local dump              = FUNC and FUNC.file   and FUNC.file.dump            or nop;
-- local file_exists       = FUNC and FUNC.file   and FUNC.file.exists          or nop;
-- local find_file         = FUNC and FUNC.file   and FUNC.file.find            or nop;
-- local get_slug          = FUNC and FUNC.file   and FUNC.file.get_slug        or nop;
-- local path_level        = FUNC and FUNC.file   and FUNC.file.path_level      or nop;
-- local map_src_fs        = FUNC and FUNC.file   and FUNC.file.map_src_fs      or nop;
-- local slurp             = FUNC and FUNC.file   and FUNC.file.slurp           or nop;
-- local mark_line_used    = FUNC and FUNC.line   and FUNC.line.mark_used       or nop;
-- local was_used_line     = FUNC and FUNC.line   and FUNC.line.was_used        or nop;
-- local parse_recipe_line = FUNC and FUNC.recipe and FUNC.recipe.parse_line    or nop;
-- local file_search       = FUNC and FUNC.util   and FUNC.util.search          or nop;
-- local eprint            = FUNC and FUNC.util   and FUNC.util.eprint          or nop;
-- local ignore            = FUNC and FUNC.util   and FUNC.util.ignore          or nop;
-- local pprint            = FUNC and FUNC.util   and FUNC.util.pprint          or nop;
-- local split             = FUNC and FUNC.util   and FUNC.util.split           or nop;
-- local sprint            = FUNC and FUNC.util   and FUNC.util.sprint          or nop;
-- local vprint            = FUNC and FUNC.util   and FUNC.util.vprint          or nop;
-- local yprint            = FUNC and FUNC.util   and FUNC.util.yprint          or nop;
-- local recipe_list       = FUNC and FUNC.util   and FUNC.util.recipe.list     or nop;
-- local unpack_yaml_tree  = FUNC and FUNC.yaml   and FUNC.yaml.unpack_tree     or nop;
-- 

-- ==========================================================
-- Command line interface: https://lua-cliargs.netlify.com/#/

-- for foo, bar in pairs(cli) do print("cli." .. foo, bar); end;

-- print("CONFIG.appname is", CONFIG.appname);

cli:set_name(CONFIG.appname);
cli:command(CONFIG.appname);
cli:set_description("it creates the .md files we need"                 );
cli:splat("RECIPE",                 "the recipe to build", "", 1       );
cli:option("-o, --outfile=OUTFILE", "specify the outfile"              );
cli:flag(  "-v, --verbose",         "be more wordy than usual",  false );
cli:flag(  "-q, --quiet",           "don't summarize each step", false );
cli:flag(  "-l, --list",            "list the known recipes",    false );
cli:flag(  "-y, --debugyaml",       "be verbose about yaml",     false );
cli:flag(  "-e, --[no-]errors",     "show errors",               true  );

-- for foo, bar in pairs(arg) do print("arg." .. foo, bar); end;

local args, err = cli:parse(arg);
if not args           then cli:print_help(); os.exit(1);                                 end;
if err                then print(string.format("%s: %s", cli.name, err)); os.exit(1);    end;
if args and args.list then recipe_list()                                                 end;
if args.quiet         then CONFIG.summary   = false else CONFIG.summary   = true;        end;
if args.verbose       then CONFIG.verbose   = true
                           CONFIG.debugyaml = true  else CONFIG.verbose   = false;       end;
if args.debugyaml     then CONFIG.debugyaml = true  else CONFIG.debugyaml = false;       end;
if args.errors        then CONFIG.errors    = true  else CONFIG.errors    = false;       end;
if args.RECIPE        then CONFIG.recipe    = args.RECIPE; CONFIG.outfile = args.RECIPE; end;
if args.outfile       then CONFIG.outfile   = args.outfile                               end;

-- =======================================
-- Everything above this is initialization
-- =======================================

-- start run -----------------------------
vprint("Running in verbose mode");
sprint("Showing summaries");
yprint("Being wordy about yaml parsing");

-- read the recipe
sprint("reading recipe", CONFIG.recipe);
local recipe_src = slurp(CONFIG.dir.recipe .. "/" .. CONFIG.recipe .. CONFIG.ext.recipe, true);
if not recipe_src then print("Error: Can't read that recipe file"); os.exit() end
local recipe = split(recipe_src, "[\r\n]+");
sprint("recipe read", #recipe .. " lines in recipe");

-- parse the filesystem tree
sprint("Loading the filesystem map", CONFIG.dir.source );
map_src_fs(CONFIG.dir.source);
vprint("Filesystem mapped.", g.count.FILES .. " files");

-- parse the recipe, store in g.bucket.BUILD
for _, i in pairs(recipe)
do  if not string.find(i, "^# ") then parse_recipe_line(i) end;
end;

sprint("recipe read", bucket_count("build") .. " files in build");
-- ready now to read files

for _, v in pairs(g.bucket.BUILD)
do  if     v:find("%" .. CONFIG.ext.yaml     .. "$")
    then   local slurped = slurp_yaml(v);
           -- vprint("slurping ", v);
           table.insert(g.outtxt, slurped);
    elseif v:find("%" .. CONFIG.ext.markdown .. "$")
    then   local slurped = slurp(v);
           -- vprint("slurping ", v);
          table.insert(g.outtxt, slurped);
    end;
end;

sprint("done reading/parsing files", g.count.BUILD .. " files");

-- save the output
local outfile = CONFIG.dir.build .. "/" .. CONFIG.outfile .. CONFIG.ext.out;
local outtxt = table.concat(g.outtxt, "\n");

print("Writing to file", outfile);
-- print("Content type is", type(outtxt));
print("Content size is", string.len(outtxt) .. " characters");
dump(outfile, outtxt);

-- notify of errors
eprint(
  "number of errors",
  (g.count.ERR or 0)
    .. " error"
    .. (bucket_count("err") and bucket_count("err") == 1 and "" or "s")
);

eprint("error count is", inspect(bucket_count("err")));

if   false and bucket_count("err") > 0
then bucket_dump("err", eprint);
     -- eprint("DIRS", inspect(bucket_contents("dirs")));
end;

if   bucket_count("err") > 0
then local err_start = 1;
     local err_stop = math.min(CONFIG.maxerrors, g.count.ERR);
     for i = err_start, err_stop, 1
     do local errmsg;
        local filename = g.bucket.ERR[i];
        if    bucket_fetch("files", filename) -- g.bucket.FILES[filename]
        then  errmsg = "Improperly marked as missing";
        else  errmsg = (string.find(filename, CONFIG.intro .. "$") or
                        string.find(filename, "/$"))
                        and "Warning: Missing index"
                        or  "Alert: Missing file";
        end -- if g.bucket.FILES[filename]
        eprint(errmsg, filename)
     end; -- do
     if   bucket_count("err") > CONFIG.maxerrors
     then eprint("...");
          eprint(bucket_count("err") - CONFIG.maxerrors .. " errors hidden", "not shown");
     end;
     -- vprint(string.rep("-", 25), string.rep("-", 20));
     -- vprint("g.bucket.FILES", inspect(g.FILES));
end; -- if g.count.ERR
