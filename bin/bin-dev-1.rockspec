package = "bin"
version = "dev-1"
source = {
   url = "git+https://github.com/endurantgames/cosmiclegends.git"
}
description = {
   homepage = "https://github.com/endurantgames/cosmiclegends",
   license = "*** please specify a license ***"
}
build = {
   type = "builtin",
   modules = {
      config = "config.lua",
      ["content.load"] = "content/load.lua",
      ["func.bucket"] = "func/bucket.lua",
      ["func.file"] = "func/file.lua",
      ["func.func-wr.bucket"] = "func/func-wr/bucket.lua",
      ["func.func-wr.file"] = "func/func-wr/file.lua",
      ["func.func-wr.line"] = "func/func-wr/line.lua",
      ["func.func-wr.load"] = "func/func-wr/load.lua",
      ["func.func-wr.recipe"] = "func/func-wr/recipe.lua",
      ["func.func-wr.util"] = "func/func-wr/util.lua",
      ["func.func-wr.yaml"] = "func/func-wr/yaml.lua",
      ["func.line"] = "func/line.lua",
      ["func.load"] = "func/load.lua",
      ["func.recipe"] = "func/recipe.lua",
      ["func.util"] = "func/util.lua",
      ["func.yaml"] = "func/yaml.lua",
      ["make-markdown"] = "make-markdown.lua",
      ["modules.character"] = "modules/character.lua",
      ["modules.items"] = "modules/items.lua",
      ["modules.list"] = "modules/list.lua",
      ["modules.load"] = "modules/load.lua",
      ["modules.module_template"] = "modules/module_template.lua",
      ["modules.sheet"] = "modules/sheet.lua"
   }
}
