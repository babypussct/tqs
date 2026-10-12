-- SPDX-License-Identifier: GPL-3.0-or-later

local prefix = "packages.ol.pkg."

local ol_shzl = require(prefix .. "ol_shzl")
local ol_yj = require(prefix .. "ol_yj")
local ex_shzl = require(prefix .. "ol_ex")
local ex_yj = require(prefix .. "ol_exyj")
local wende = require(prefix .. "wende")
local xinghe = require(prefix .. "xinghe")
local ol_mou = require(prefix .. "ol_mou")
local ol_mo = require(prefix .. "ol_mo")
local menfa = require(prefix .. "menfa")
local jsrg = require(prefix .. "jsrg")
local qifu = require(prefix .. "qifu")
local ol_sp = require(prefix .. "ol_sp")
local ol_test = require(prefix .. "ol_test")
local ol_other = require(prefix .. "ol_other")
local ol_gamemode = require(prefix .. "ol_gamemode")
local longbench_cards = require(prefix .. "ol_gamemode.longbench.cards")
local ol_derived = require(prefix .. "ol_derived")

Fk:loadTranslationTable { ["ol"] = "OL", }

return {
  ol_shzl,
  ol_yj,
  ex_shzl,
  ex_yj,
  wende,
  xinghe,
  ol_mou,
  ol_mo,
  menfa,
  jsrg,
  qifu,
  ol_sp,
  ol_test,
  ol_other,
  ol_gamemode,
  longbench_cards,
  ol_derived,
}
