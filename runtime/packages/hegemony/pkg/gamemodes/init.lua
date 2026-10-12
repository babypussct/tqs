local extension = Package:new("heg_mode", Package.SpecialPack)
extension:loadSkillSkelsByPath("./packages/hegemony/pkg/gamemodes/skills")

local heg_mode = require "packages.hegemony.pkg.gamemodes.new_hegemony_mode"
extension:addGameMode(heg_mode)
-- local nos_heg = require "packages.hegemony.pkg.gamemodes.nos_hegemony_mode"
-- extension:addGameMode(nos_heg)

Fk:loadTranslationTable{
  ["heg_mode"] = "国战模式",
}

return extension
