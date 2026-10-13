-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("gamemode", Package.SpecialPack)

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/gamemodes/rule_skills")

extension:addGameMode(require "packages.gamemode.pkg.gamemodes.1v2")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.1v2_brawl")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.2v2")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.1v1")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.3v3")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.1v3")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.clone")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.chaos_mode")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.espionage")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.variation")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.vanished_dragon")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.kangqin")
extension:addGameMode(require "packages.gamemode.pkg.gamemodes.jiange")

local mobile_cards = require "packages.gamemode.pkg.mobile_cards"
local chaos_mode_cards = require "packages.gamemode.pkg.chaos_mode_cards"
local espionage_cards = require "packages.gamemode.pkg.espionage_cards"
local vanished_dragon_cards = require "packages.gamemode.pkg.vanished_dragon_cards"
local variation_cards = require "packages.gamemode.pkg.variation_cards"
local certamen_cards = require "packages.gamemode.pkg.certamen_cards"
local derived_cards = require "packages.gamemode.pkg.derived_cards"
local v33_cards = require "packages.gamemode.pkg.3v3_cards"
local v11_cards = require "packages.gamemode.pkg.1v1_cards"

local gamemode_generals = require "packages.gamemode.pkg.gamemode_generals"
local m_1v1_generals = require "packages.gamemode.pkg.1v1_generals"
local m_3v3_generals = require "packages.gamemode.pkg.3v3_generals"
local jiange_generals = require "packages.gamemode.pkg.jiange_generals"

Fk:loadTranslationTable{ ["gamemode"] = "游戏模式" }
Fk:loadTranslationTable(require 'packages.gamemode.i18n.en_US', 'en_US')

return {
  extension,

  mobile_cards,
  chaos_mode_cards,
  espionage_cards,
  vanished_dragon_cards,
  variation_cards,
  certamen_cards,
  derived_cards,
  v33_cards,
  v11_cards,

  gamemode_generals,
  m_1v1_generals,
  m_3v3_generals,
  jiange_generals,
}
