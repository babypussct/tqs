
local shantong = fk.CreateSkill{
  name = "ol_heg__shantong",
}

Fk:loadTranslationTable{
  ["ol_heg__shantong"] = "擅统",
  [":ol_heg__shantong"] = "同势力角色的准备阶段，若其武将牌均明置，其可以暗置一张武将牌，令其此回合使用的下一张牌无距离和次数限制。"..
  "若如此做，此回合其明置该武将牌后，你对其造成1点伤害并获得其所有手牌。",

  ["#ol_heg__shantong-invoke"] = "擅统：你可以暗置一张武将牌，本回合使用下一张牌无距离次数限制",
  ["@@ol_heg__shantong-turn"] = "擅统",

  ["$ol_heg__shantong1"] = "肩负元帅之责，当督领上军。",
  ["$ol_heg__shantong2"] = "戎武事略皆经我，哪由你放肆！",
}

local H = require "packages.hegemony.util"

shantong:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shantong.name) and target.phase == Player.Start and
      H.compareKingdomWith(target, player) and H.allGeneralsRevealed(target) and not target.dead
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = shantong.name,
      prompt = "#ol_heg__shantong-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "@@ol_heg__shantong-turn", 1)
    local general = H.doHideGeneral(room, target, target, shantong.name) == true and target:getMark("__heg_deputy") or
      target:getMark("__heg_general")
    room:setPlayerMark(player, "ol_heg__shantong-turn", general)
  end,
})

shantong:addEffect(fk.GeneralRevealed, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not target.dead and player.room:getCurrent() == target and
      player:getMark("ol_heg__shantong-turn") ~= 0 then
      for _, v in pairs(data) do
        if v == player:getMark("ol_heg__shantong-turn") then
          return true
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = shantong.name,
    }
    if not player.dead and not target:isKongcheng() and target ~= player then
      room:moveCardTo(target:getCardIds("h"), Card.PlayerHand, player, fk.ReasonPrey, shantong.name, nil, false, player)
    end
  end
})

shantong:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@ol_heg__shantong-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
    player.room:setPlayerMark(player, "@@ol_heg__shantong-turn", 0)
  end,
})

shantong:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card, to)
    return card and player:getMark("@@ol_heg__shantong-turn") > 0
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return card and player:getMark("@@ol_heg__shantong-turn") > 0
  end,
})

return shantong
