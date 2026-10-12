local jieyue = fk.CreateSkill {
  name = "jianan__ld__jieyue",
}

Fk:loadTranslationTable {
  ["jianan__ld__jieyue"] = "节钺",
  [":jianan__ld__jieyue"] = "准备阶段，你可将一张手牌交给不是魏势力或没有势力的一名角色，对其发起“军令”。若其：执行，你摸一张牌；不执行，摸牌阶段，你令额定摸牌数+3。",

  ["#jianan__ld__jieyue-target"] = "节钺：你可将一张手牌交给不是魏势力或没有势力的一名角色，对其发起军令",
  ["$jianan__ld__jieyue1"] = "孤之股肱，谁敢不从？嗯？",
  ["$jianan__ld__jieyue2"] = "泰山之高，群山不可及，文则之重，泰山不可及！",
}

local H = require "packages.hegemony.util"

jieyue:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieyue.name) and player.phase == Player.Start and
        not player:isKongcheng()
        and table.find(player.room.alive_players, function(p) return p.kingdom ~= "wei" and p ~= player end)
  end,
  on_cost = function(self, event, target, player, data)
    local plist, cid = player.room:askToChooseCardsAndPlayers(player, {
      targets = table.filter(player.room.alive_players, function(p) return p.kingdom ~= "wei" and p ~= player end),
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      pattern = ".|.|.|hand",
      prompt = "#jianan__ld__jieyue-target",
      skill_name = jieyue.name,
      cancelable = true,
    })
    if #plist > 0 then
      event:setCostData(self, { tos = plist, card = cid })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(event:getCostData(self).card, Player.Hand, to, fk.ReasonGive, jieyue.name, nil, false, player)
    if H.askToCommand(player, { tos = { to }, skill_name = jieyue.name }) then
      player:drawCards(1, jieyue.name)
    else
      room:addPlayerMark(player, "_ld__jieyue-turn")
    end
  end
})

jieyue:addEffect(fk.DrawNCards, {
  mute = true,
  is_delay_effect = true,
  can_use = function(self, event, target, player, data)
    return target == player and target:getMark("_ld__jieyue-turn") > 0 and player:hasSkill(jieyue.name)
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 3 * target:getMark("_ld__jieyue-turn")
  end,
})

return jieyue
