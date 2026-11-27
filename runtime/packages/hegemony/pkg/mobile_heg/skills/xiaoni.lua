
local xiaoni = fk.CreateSkill {
  name = "m_heg__xiaoni",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__xiaoni"] = "嚣逆",
  [":m_heg__xiaoni"] = "锁定技，当你使用牌或你被使用牌时，若场上有势力与你相同的其他角色且你是同势力角色中手牌数最多的角色，目标角色不能响应此牌。",

  ["$m_heg__xiaoni1"] = "织席贩履之辈，果无用人之能乎？",
  ["$m_heg__xiaoni2"] = "古今天下，岂有重屠沽之流而轻贤达者乎？",
}

local H = require "packages.hegemony.util"

xiaoni:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(xiaoni.name) and data.firstTarget and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return H.compareKingdomWith(player, p)
      end) and
      table.every(player.room:getOtherPlayers(player, false), function (p)
        return not H.compareKingdomWith(player, p) or player:getHandcardNum() >= p:getHandcardNum()
      end)
  end,
  on_use = function(self, event, target, player, data)
    data:setDisresponsive(data.use.tos)
  end,
})

xiaoni:addEffect(fk.TargetConfirmed, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(xiaoni.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return H.compareKingdomWith(player, p)
      end) and
      table.every(player.room:getOtherPlayers(player, false), function (p)
        return not H.compareKingdomWith(player, p) or player:getHandcardNum() >= p:getHandcardNum()
      end)
  end,
  on_use = function(self, event, target, player, data)
    data:setDisresponsive(data.use.tos)
  end,
})

return xiaoni
