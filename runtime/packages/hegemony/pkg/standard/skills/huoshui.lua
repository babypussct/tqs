local huoshui = fk.CreateSkill{
  name = "huoshui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["huoshui"] = "祸水",
  [":huoshui"] = "锁定技，你的回合内：其他角色不能明置其武将牌；势力与你不同且有暗置武将牌的角色不能使用或打出【闪】响应你使用的牌。",

  ["$huoshui1"] = "走不动了吗？" ,
  ["$huoshui2"] = "别走了，再玩一会嘛~" ,
}

local H = require "packages.hegemony.util"

local addHuoshui = function(player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    room:addTableMark(p, MarkEnum.RevealProhibited .. "-turn", "m")
    room:addTableMark(p, MarkEnum.RevealProhibited .. "-turn", "d")
  end
end

local removeHuoshui = function(player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    room:removeTableMark(p, MarkEnum.RevealProhibited .. "-turn", "m")
    room:removeTableMark(p, MarkEnum.RevealProhibited .. "-turn", "d")
  end
end

huoshui:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(self) and player.room:getCurrent() == player
  end,
  on_use = function(self, event, target, player, data)
    addHuoshui(player)
  end,
})

huoshui:addEffect(fk.GeneralRevealed, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.room:getCurrent() == player then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), self.name) then return true end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    addHuoshui(player)
  end
})

huoshui:addAcquireEffect(function (self, player, is_start)
  if player.room:getCurrent() == player and player:hasShownSkill(huoshui.name) then
    addHuoshui(player)
  end
end)

huoshui:addLoseEffect(function (self, player, is_death)
  if player.room:getCurrent() == player then
    removeHuoshui(player)
  end
end)

huoshui:addEffect(fk.PreCardEffect, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return data.from == player and player:hasSkill(huoshui.name) and
      player.room:getCurrent() == player and
      not H.compareKingdomWith(data.to, player) and not H.allGeneralsRevealed(data.to)
  end,
  on_use = function (self, event, target, player, data)
    data.prohibitedCardNames = data.prohibitedCardNames or {}
    table.insertIfNeed(data.prohibitedCardNames, "jink")
  end
})

return huoshui
