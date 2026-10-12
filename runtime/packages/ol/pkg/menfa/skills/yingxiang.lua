
local yingxiang = fk.CreateSkill{
  name = "yingxiang",
}

Fk:loadTranslationTable{
  ["yingxiang"] = "迎乡",
  [":yingxiang"] = "结束阶段，你可以声明一种基本牌或普通锦囊牌的牌名，并与一名角色拼点。"..
  "赢的角色可以视为使用你声明的牌，且你获得所有拼点牌。"..
  "若声明的牌与拼点牌牌名相同，你视为未发动过〖恤民〗；若均不同，你失去一个技能。",

  ["#yingxiang-choose"] = "迎乡：声明一种牌名并与一名角色拼点，赢者可以视为使用此牌，你获得双方拼点牌",
  ["#yingxiang-use"] = "迎乡：你可以视为使用【%arg】",
  ["#yingxiang-lose"] = "迎乡：失去一个技能",

  ["$yingxiang1"] = "颍川冲要，不捍大难，冀州虽鄙，堪留余谷。",
  ["$yingxiang2"] = "西山冷冷，众卿莫怀守土依依。",
  ["$yingxiang3"] = "遣骑迎乡人，则韩氏不来唯荀姓独往。",
}

local U = require "packages.utility.utility"

yingxiang:addAuxActiveSkill("#yingxiang_active", {
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  interaction_helper = function (self, player, selected_cards, selected_targets, extra_data)
    return UI.CardNameBox { choices = Fk:getAllCardNames("bt") }
  end,
})

yingxiang:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yingxiang.name) and player.phase == Player.Finish and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#yingxiang_active",
      prompt = "#yingxiang-choose",
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    room:sendLog{
      type = "#Choice",
      from = player.id,
      arg = choice,
      toast = true,
    }
    local pindian = player:pindian({to}, yingxiang.name)
    local winner = pindian.results[to].winner
    if not winner then return end
    if not winner.dead then
      room:askToUseVirtualCard(winner, {
        name = choice,
        skill_name = yingxiang.name,
        prompt = "#yingxiang-use:::"..choice,
        cancelable = true,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
      })
    end
    if player.dead then return end
    local cards = {}
    if pindian.fromCard then
      cards = table.filter(Card:getIdList(pindian.fromCard), function (id)
        return table.contains(room.discard_pile, id)
      end)
    end
    if pindian.results[to].toCard then
      for _, id in ipairs(Card:getIdList(pindian.results[to].toCard)) do
        if table.contains(room.discard_pile, id) then
          table.insertIfNeed(cards, id)
        end
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, yingxiang.name, nil, true, player)
    end
    if player.dead then return end
    local yes = false
    if pindian.fromCard and (pindian.fromCard.name == choice or pindian.fromCard.trueName == choice) then
      yes = true
    end
    if pindian.results[to].toCard and (pindian.results[to].toCard.name == choice or pindian.results[to].toCard.trueName == choice) then
      yes = true
    end
    if yes then
      player:setSkillUseHistory("xumin", 0, Player.HistoryGame)
    else
      if #player:getSkillNameList() > 0 then
        choice = U.askToChooseSkills(player, {
          skill_name = yingxiang.name,
          prompt = "#yingxiang-lose",
          min_num = 1, max_num = 1,
          skills = player:getSkillNameList(),
        })
        room:handleAddLoseSkills(player, "-"..choice[1])
      end
    end
  end,
})

return yingxiang
