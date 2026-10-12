local extension = Package:new("ol_gamemode", Package.SpecialPack)
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_gamemode/rule_skills")

extension:addGameMode(require "packages.ol.pkg.ol_gamemode.rougelike1v1.init")
extension:addGameMode(require "packages.ol.pkg.ol_gamemode.longbench.init")

Fk:loadTranslationTable{ ["ol_gamemode"] = "OL游戏模式" }

return extension
