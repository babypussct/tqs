
local chuanxin = fk.CreateSkill{
  name = "m_heg__chuanxin",
  tags = { Skill.Compulsory },
  dynamic_desc = function (self, player, lang)
    if player:getMark(self.name) > 0 then
      return "m_heg__chuanxin_update"
    end
  end,
}

Fk:loadTranslationTable{
  ["m_heg__chuanxin"] = "穿心",
  [":m_heg__chuanxin"] = "锁定技，你使用【杀】或【决斗】对一名角色造成伤害后，其每满足一项便弃置一张牌：<br>"..
  "1.与你势力不同；<br>2.副将与你状态相同。<br>乘势：移除其副将，然后失去乘势效果。",

  [":m_heg__chuanxin_update"] = "锁定技，你使用【杀】或【决斗】对一名角色造成伤害后，其每满足一项便弃置一张牌：<br>"..
  "1.与你势力不同；<br>2.副将与你状态相同。",

  ["$m_heg__chuanxin1"] = "一箭穿心，哪里可逃？",
  ["$m_heg__chuanxin2"] = "穿心之痛，细细品吧，哈哈哈哈！",
}

local H = require "packages.hegemony.util"

chuanxin:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(chuanxin.name) and
      data.card and table.contains({ "slash", "duel" }, data.card.trueName) and not data.to.dead and
      (H.compareKingdomWith(player, data.to, true) or
      (player.deputyGeneral == "anjiang" and data.to.deputyGeneral == "anjiang") or
      (player.deputyGeneral ~= "anjiang" and data.to.deputyGeneral ~= "anjiang"))
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    if H.compareKingdomWith(player, data.to, true) then
      n = 1
    end
    if (player.deputyGeneral == "anjiang" and data.to.deputyGeneral == "anjiang") or
      (player.deputyGeneral ~= "anjiang" and data.to.deputyGeneral ~= "anjiang") then
      n = n + 1
    end
    local yes = n == 2 and player:getMark(chuanxin.name) == 0
    room:askToDiscard(data.to, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = chuanxin.name,
      cancelable = false,
    })
    if yes and not data.to.dead then
      room:setPlayerMark(player, chuanxin.name, 1)
      H.removeGeneral(data.to, true)
    end
  end,
})

return chuanxin
