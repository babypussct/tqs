-- SPDX-License-Identifier: GPL-3.0-or-later

Fk:loadTranslationTable(require 'packages/overseas/i18n/en_US', 'en_US')

local prefix = "packages.overseas.pkg."

local overseas_ex = require (prefix .. "overseas_ex")
local overseas_if = require (prefix .. "overseas_if")
local overseas_wuxia = require (prefix .. "overseas_wuxia")
local overseas_strategizing = require (prefix .. "overseas_strategizing")
local overseas_sp = require (prefix .. "overseas_sp")
local overseas_yizhu = require (prefix .. "overseas_yizhu")
local overseas_rare = require (prefix .. "overseas_rare")
local overseas_mougong = require (prefix .. "overseas_mougong")
local overseas_bingshi = require (prefix .. "overseas_bingshi")
local overseas_sxrm = require (prefix .. "overseas_sxrm")
local overseas_other = require (prefix .. "overseas_other")

local overseas_derived = require (prefix .. "overseas_derived")

Fk:loadTranslationTable{
  ["overseas"] = "国际服",
}

return {
  overseas_ex,
  overseas_if,
  overseas_wuxia,
  overseas_strategizing,
  overseas_sp,
  overseas_yizhu,
  overseas_rare,
  overseas_mougong,
  overseas_bingshi,
  overseas_sxrm,
  overseas_other,

  overseas_derived,
}
