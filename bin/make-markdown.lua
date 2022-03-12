#!/usr/bin/lua

local _G = _G;

_G.g = { -- g for "global"   g = _G.g
  FILES  = { }, YAML = { },
  bucket = { BUILD   = { }, CONTENT = { },
             DIRS    = { }, ERR  = { },
             FILES   = { } },
  count  = { BUILD   = 0,   DIRS   = 0,
             ERR     = 0,   FILES  = 0, },
  outtxt = { },
};

    g.FUNC = { }; -- functions
local FUNC = g.FUNC;
local UTIL = FUNC.util;

g.CONFIG         = {
  recipe         = "clu", -- specific to this project
  appname        = "make-markdown.lua",
  dir            = { bin          = "./bin", build  = "./build",
                     out          = "./out", recipe = "./recipes",
                     source       = "./src", },
  errors         = true,
  ext            = { filter       = ".md;.yaml",
                     markdown     = ".md",  out    = ".md",
                     recipe       = ".rec", source = "(.md|%.yaml)",
                     yaml         = ".yaml", },
  ignore         = "(%.git|Makefile|%.test|%.|backup|markdown)",
  intro          = "intro",
  lsfmt          = "  %-30s %-20s",
  logfmt         = "  %-30s %-20s",
  maxerrors      = 2,
  outfile        = "build",
  src_in_comment = true,
  summary        = true,
  verbose        = true,
  yaml_ignore    = "^(metadata|flat|%d+)"
};

local CONFIG = g.CONFIG;

package.path = "./?.lua;./?/load.lua;" .. package.path;

require "func"   ;
require "content";
require "modules";

local lfs     = require "lfs"    ;
local cli     = require "cliargs";
local lyaml   = require "lyaml"  ; -- https://github.com/gvvaughan/lyaml
local inspect = require "inspect"; -- https://github.com/kikito/inspect.lua

-- access to functions
local adjust_md_level   = FUNC.file.adjust_md_level;
local bucket_add        = FUNC.bucket.add;
local bucket_contents   = FUNC.bucket.contents;
local bucket_count      = FUNC.bucket.count;
local bucket_dump       = FUNC.bucket.dump;
local bucket_exists     = FUNC.bucket.exists;
local bucket_fetch      = FUNC.bucket.fetch;
local bucket_test       = FUNC.bucket.test;
local dump              = FUNC.file.dump;
local eprint            = UTIL.eprint;
local file_exists       = FUNC.file.exits;
local file_search       = FUNC.util.search;
local find_file         = FUNC.file.find;
local get_slug          = FUNC.file.get_slug;
local ignore            = UTIL.ignore;
local map_src_fs        = FUNC.file.map_src_fs;
local mark_line_used    = FUNC.line.mark_used;
local parse_recipe_line = FUNC.recipe.parse_line;
local path_level        = FUNC.file.path_level;
local pprint            = UTIL.pprint;
local slurp             = FUNC.file.slurp;
local split             = UTIL.split;
local sprint            = UTIL.sprint;
local unpack_yaml_tree  = FUNC.yaml.unpack_tree;
local vprint            = UTIL.vprint;
local was_used_line     = FUNC.line.was_used;
local yprint            = UTIL.yprint;
local recipe_list       = UTIL.recipe.list;

-- ==========================================================
-- Command line interface: https://lua-cliargs.netlify.com/#/

cli:set_name(CONFIG.appname);
cli:set_description("it creates the .md files we need"                 );
cli:splat("RECIPE",                 "the recipe to build", "", 1       );
cli:option("-o, --outfile=OUTFILE", "specify the outfile"              );
cli:flag(  "-v, --verbose",         "be more wordy than usual",  false );
cli:flag(  "-q, --quiet",           "don't summarize each step", false );
cli:flag(  "-l, --list",            "list the known recipes",    false );
cli:flag(  "-y, --debugyaml",       "be verbose about yaml",     false );
cli:flag(  "-e, --[no-]errors",     "show errors",               true  );

local args, err = cli:parse(arg);
if not args then cli:print_help(); os.exit(1);                                           end;
if err then print(string.format("%s: %s", cli.name, err)); os.exit(1);                   end;
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
