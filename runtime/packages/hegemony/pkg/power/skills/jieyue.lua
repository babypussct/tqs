local jieyue = fk.CreateSkill{
  name = "ld__jieyue",
}

Fk:loadTranslationTable{
  ["ld__jieyue"] = "节钺",
  [":ld__jieyue"] = "准备阶段，你可以将一张手牌交给一名不是魏势力的其他角色，对其发起“军令”。"..
  "若其执行，你摸一张牌，否则你本回合摸牌阶段额定摸三张牌。",

  ["#ld__jieyue-target"] = "节钺：将一张手牌交给一名角色，对其发起“军令”",

  ["$ld__jieyue1"] = "杀我？你做不到！",
  ["$ld__jieyue2"] = "阳关大道，你不选吗？",
}

local H = require "packages.hegemony.util"

jieyue:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieyue.name) and player.phase == Player.Start and
      not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player, false), function(p) return
        p.kingdom ~= "wei"
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p) return
      p.kingdom ~= "wei"
    end)
    local tos, cards = player.room:askToChooseCardsAndPlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      max_card_num = 1,
      min_card_num = 1,
      skill_name = jieyue.name,
      pattern = ".|.|.|hand",
      prompt = "#ld__jieyue-target",
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos, cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(event:getCostData(self).cards, Player.Hand, to, fk.ReasonGive, jieyue.name, nil, false, player)
    if H.askToCommand(player, { tos = { to }, skill_name = jieyue.name }) then
      if not player.dead then
        player:drawCards(1, jieyue.name)
      end
    else
      room:addPlayerMark(player, "ld__jieyue-turn")
    end
  end
})

jieyue:addEffect(fk.DrawNCards, {
  is_delay_effect = true,
  mute = true,
  can_use = function(self, event, target, player, data)
    return target == player and target:getMark("ld__jieyue-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 3 * target:getMark("ld__jieyue-turn")
  end,
})

return jieyue
