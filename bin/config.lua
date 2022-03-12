#!/usr/bin/lua

local _G = _G;
_G.g     = _G.g or {};
local g  = _G.g;

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

package.path = "./?.lua;./?/load.lua;" .. package.path;

