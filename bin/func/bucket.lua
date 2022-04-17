#!/usr/bin/lua

local _G     = _G;
_G.g         = _G.g or {};
local g      = _G.g;
g.FUNC       = g.FUNC or {};
g.CONFIG     = g.CONFIG or {};
local FUNC   = g.FUNC;
local CONFIG = g.CONFIG;
local FUNC   = g.FUNC;
local UTIL   = FUNC.util;

print("-------------------------------- bucket --------------------------------");
local register_func, register_cat;

local ignore, split;
local vprint, eprint, sprint, pprint, yprint;

if UTIL.ignore            then ignore            = UTIL.ignore             else eprint("Error: no function", "ignore"           ); os.exit(); end;
if UTIL.split             then split             = UTIL.split              else eprint("Error: no function", "split"            ); os.exit(); end;
if UTIL.vprint            then vprint            = UTIL.vprint             else eprint("Error: no function", "vprint"           ); os.exit(); end;
if UTIL.eprint            then eprint            = UTIL.eprint             else eprint("Error: no function", "eprint"           ); os.exit(); end;
if UTIL.sprint            then sprint            = UTIL.sprint             else eprint("Error: no function", "sprint"           ); os.exit(); end;
if UTIL.pprint            then pprint            = UTIL.pprint             else eprint("Error: no function", "pprint"           ); os.exit(); end;
if UTIL.yprint            then yprint            = UTIL.yprint             else eprint("Error: no function", "yprint"           ); os.exit(); end;
if UTIL.register_func     then register_func     = UTIL.register_func;     else eprint("Error: no function", "register_func"    ); os.exit(); end;
if UTIL.register_cat then register_cat = UTIL.register_cat; else eprint("Error: no function", "register_cat"); os.exit(); end;
register_cat("bucket");
local function register_bucket_func(n, ff) register_func("bucket", n, ff); end;

-- == bucket functions ========================================================
local function bucket_exists(bucket)
  bucket = bucket or "";
  bucket = bucket:upper();
  return g.bucket[bucket] and true or false;
end;

local function bucket_count(bucket)
  bucket = bucket or "";
  bucket = bucket:upper();
  if   not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Can't get count");
  else return g.count[bucket]
  end;
end;

local function bucket_contents(bucket)
  bucket = bucket or "";
  bucket = bucket:upper();
  if not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Can't get contents");
  else return g.bucket[bucket];
  end; -- if not bucket_exists
end; -- function

local function bucket_dump(bucket, printfunc)
  printfunc = printfunc or pprint;
  bucket = bucket or "";
  bucket = bucket:upper();
  if not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Can't do dump");
       return nil;
  else printfunc("Dump starts ===========", bucket);
       for i, line in pairs(bucket_contents(bucket))
       do printfunc(bucket .. "[" .. i .. "]", line);
       end;
       printfunc("Dump ends ===========", bucket);
  end; -- if not bucket_exists
end;

local function bucket_fetch(bucket, key)
  key    = key or "";
  bucket = bucket or "";
  bucket = bucket:upper();
  if not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Can't do lookup");
       return nil;
  else bucket_list = bucket_contents(bucket);
       if not bucket_list
       then   eprint("Error: can't get bucket list", bucket)
              return nil;
       elseif not bucket_list[key]
              then eprint("Error: no value for", bucket .. "[" .. key .. "]");
              return nil;
       end; -- if not bucket_list
  end; -- if not bucket_exists

end;

local function bucket_test(bucket, key)
  key    = key or "";
  bucket = bucket or "";
  bucket = bucket:upper();
  if not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Can't do test");
       return false;
  else local value = bucket_fetch(bucket, key)
       if value then return true else return false; end;
  end; -- not bucket_exists
end; -- function

local function bucket_add(bucket, data)
  bucket = bucket or "";
  bucket = bucket:upper();
  if   not bucket_exists(bucket)
  then eprint("Error: unknown bucket", bucket);
       eprint("Unsaved data:", inspect(data));
       os.exit(1);
  else table.insert(g.bucket[bucket], data);
       g.count[bucket] = bucket_count(bucket) + 1;
  end;
end;

register_bucket_func("exists",    bucket_exists   );
register_bucket_func("count",     bucket_count    );
register_bucket_func("contents",  bucket_contents );
register_bucket_func("dump",      bucket_dump     );
register_bucket_func("fetch",     bucket_fetch    );
register_bucket_func("test",      bucket_test     );
register_bucket_func("add",       bucket_add      );

print("------------------------------- /bucket --------------------------------");
