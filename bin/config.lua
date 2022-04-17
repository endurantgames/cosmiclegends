#!/usr/bin/lua

local _G     = _G;
_G.g         = _G.g or {};
local g      = _G.g;
g.FUNC       = g.FUNC   or {};
g.LOADED     = g.LOADED or {};
local CONFIG = g.CONFIG;

if not g                           then g                           = {}; end;
if not g[ "FILES"  ]               then g[ "FILES"  ]               = {}; end;
if not g[ "YAML"   ]               then g[ "YAML"   ]               = {}; end;
if not g[ "outtxt" ]               then g[ "outtxt" ]               = {}; end;
if not g[ "bucket" ]               then g[ "bucket" ]               = {}; end;
if not g[ "count"  ]               then g[ "count"  ]               = {}; end;
if not g[ "bucket" ] [ "BUILD"   ] then g[ "bucket" ] [ "BUILD"   ] = {}; end;
if not g[ "count"  ] [ "BUILD"   ] then g[ "count"  ] [ "BUILD"   ] = 0;  end;
if not g[ "bucket" ] [ "CONTENT" ] then g[ "bucket" ] [ "CONTENT" ] = {}; end;
if not g[ "bucket" ] [ "DIRS"    ] then g[ "bucket" ] [ "DIRS"    ] = {}; end;
if not g[ "count"  ] [ "DIRS"    ] then g[ "count"  ] [ "DIRS"    ] = 0;  end;
if not g[ "bucket" ] [ "ERR"     ] then g[ "bucket" ] [ "ERR"     ] = {}; end;
if not g[ "count"  ] [ "ERR"     ] then g[ "count"  ] [ "ERR"     ] = 0;  end;
if not g[ "bucket" ] [ "FILES"   ] then g[ "bucket" ] [ "FILES"   ] = {}; end;
if not g[ "count"  ] [ "FILES"   ] then g[ "count"  ] [ "FILES"   ] = 0;  end;

if not g.CONFIG
then print("------------------------------- config.lua ----------------------");
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
       pkg_path       = "./bin/func/?.lua;./?.lua;.bin/func/?/load.lua;" .. package.path;
       maxerrors      = 2,
       outfile        = "build",
       src_in_comment = true,
       summary        = true,
       verbose        = true,
       yaml_ignore    = "^(metadata|flat|%d+)"
  };
  print("------------------------------ /config.lua ----------------------");
end;
