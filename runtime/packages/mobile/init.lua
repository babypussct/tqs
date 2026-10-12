-- SPDX-License-Identifier: GPL-3.0-or-later

Fk:loadTranslationTable(require 'packages/mobile/i18n/en_US', 'en_US')

local prefix = "packages.mobile.pkg."

local mobile_bingshi = require (prefix.."mobile_bingshi")
--local mobile_mougong = require (prefix.."mobile_mougong")
local mobile_shiji = require (prefix.."mobile_shiji")
local ex_shzl = require (prefix.."shzl_ex")
local ex_yj = require (prefix.."yj_ex")
local mobile_sp = require (prefix.."mobile_sp")
local mobile_lxxh = require (prefix.."mobile_lxxh")
local mobile_rare = require (prefix.."mobile_rare")
local mobile_jsrg = require (prefix.."mobile_jsrg")
local mobile_test = require (prefix.."mobile_test")

local mobile_derived = require (prefix.."mobile_derived")

return {
    mobile_bingshi,
    --mobile_mougong,
    mobile_shiji,
    ex_shzl,
    ex_yj,
    mobile_sp,
    mobile_lxxh,
    mobile_rare,
    mobile_jsrg,
    mobile_test,

    mobile_derived,
}
