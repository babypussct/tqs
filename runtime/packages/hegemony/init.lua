local prefix = "packages.hegemony.pkg."
local gamemodes = require(prefix .. "gamemodes")

local hegemony_standard = require(prefix .. "standard")
local hegemony_nos = require(prefix .. "hegemony_nos")
local formation = require(prefix .. "formation")
local momentum = require(prefix .. "momentum")
local transformation = require(prefix .. "transformation")
local power = require(prefix .. "power")
local ex = require(prefix .. "lord_ex")
local ziqidonglai = require(prefix .. "jin_zqdl")
local jinyinzishou = require(prefix .. "jin_jyzs")
local zifengxianpei = require(prefix .. "jin_zfxp")

local ol = require(prefix .. "online_heg")
local mobile = require(prefix .. "mobile_heg")
local tenyear = require(prefix .. "tenyear_heg")
local overseas = require(prefix .. "overseas_heg")
local offline = require(prefix .. "offline_heg")

local hegemony_cards = require(prefix .. "standard_cards")
local strategic_advantage = require(prefix .. "strategic_advantage")
local nine_variations = require(prefix .. "nine_variations")
local lord_cards = require(prefix .. "lord_cards")
local m_lord_cards = require(prefix .. "m_lord_cards")

Fk:loadTranslationTable{
  ["hegemony"] = "国战",
  ["heg"] = "国战",
}
Fk:loadTranslationTable(require "packages/hegemony/i18n/en_US", "en_US")

return {
  gamemodes,

  hegemony_standard,
  hegemony_nos,
  formation,
  momentum,
  transformation,
  power,
  ex,
  ziqidonglai,
  jinyinzishou,
  zifengxianpei,

  ol,
  mobile,
  tenyear,
  overseas,
  offline,

  hegemony_cards,
  strategic_advantage,
  nine_variations,
  lord_cards,
  m_lord_cards,
}
