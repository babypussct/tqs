local zuici = fk.CreateSkill {
  name = "zuici",
}

Fk:loadTranslationTable{
  ["zuici"] = "罪辞",
  [":zuici"] = "每回合限一次，你受到伤害后，可以令一名有“定仪”效果的角色从牌堆中获得一张你选择的智囊牌，然后移去其“定仪”效果。",

  ["#zuici-choose"] = "罪辞：你可以令一名角色获得你指定的一种智囊并移去“定仪”效果",

  ["$zuici1"] = "既为朝堂宁定，吾请辞便是。",
  ["$zuici2"] = "国事为先，何惧清名有损！",
}

zuici:addAuxActiveSkill("#zuici_active", {
  card_num = 0,
  target_num = 1,
  interaction = UI.OptionBox { options = { "dismantlement", "ex_nihilo", "nullification" }, direct_send = true },
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0 and
      table.find({ 1, 2, 3, 4 }, function (i)
        return to_select:getMark("@@dingyi"..i) > 0
      end)
  end,
})

zuici:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zuici.name) and
      player:usedSkillTimes(zuici.name, Player.HistoryTurn) == 0 and
      table.find(player.room.alive_players, function (p)
        return table.find({ 1, 2, 3, 4 }, function (i)
          return p:getMark("@@dingyi"..i) > 0
        end) ~= nil
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#zuici_active",
      prompt = "#zuici-choose",
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = room:getCardsFromPileByRule(event:getCostData(self).choice)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonJustMove, zuici.name, nil, false, player)
    end
    for i = 1, 4 do
      room:setPlayerMark(to, "@@dingyi"..i, 0)
    end
  end,
})

return zuici
