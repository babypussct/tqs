local mumu = fk.CreateSkill{
  name = "mobile__mumu",
}

Fk:loadTranslationTable{
  ["mobile__mumu"] = "穆穆",
  [":mobile__mumu"] = "出牌阶段开始时，你可以选择一项：弃置场上一张装备牌；获得场上一张防具牌，然后你本回合不能使用或打出【杀】。",

  ["mobile__mumu_discard"] = "弃置一名角色装备区里的一张牌",
  ["mobile__mumu_get"] = "获得场上一张防具牌，本回合不可出杀",
  ["#mobile__mumu-discard"] = "穆穆：选择一名角色，弃置其一张装备",
  ["#mobile__mumu-get"] = "穆穆：选择一名角色，获得其一张防具",
  ["#mobile__mumu-prey"] = "穆穆：获得其中一张防具牌",
  ["@@mobile__mumu-turn"] = "禁止出杀",

  ["$mobile__mumu1"] = "储君之争，乱在当下，祸及千秋呀！",
  ["$mobile__mumu2"] = "夏至岁首之时，不可妄兴刀兵。",
}

mumu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mumu.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function (p)
        return #p:getCardIds("e") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"mobile__mumu_discard", "Cancel"}
    if table.find(room.alive_players, function(p)
      return #p:getEquipments(Card.SubtypeArmor) > 0
    end) then
      table.insert(choices, 2, "mobile__mumu_get")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = mumu.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "mobile__mumu_discard" then
      local targets = table.filter(room.alive_players, function(p)
        return #p:getCardIds("e") > 0
      end)
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = mumu.name,
        prompt = "#mobile__mumu-discard",
        cancelable = false,
      })[1]
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "e",
        skill_name = mumu.name,
      })
      room:throwCard(id, mumu.name, to, player)
    else
      local targets = table.filter(room.alive_players, function(p)
        return #p:getEquipments(Card.SubtypeArmor) > 0
      end)
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = mumu.name,
        prompt = "#mobile__mumu-get",
        cancelable = false,
      })[1]
      local ids = to:getEquipments(Card.SubtypeArmor)
      room:setPlayerMark(player, "@@mobile__mumu-turn", 1)
      if #ids > 1 then
        ids = room:askToChooseCard(player, {
          target = to,
          flag = { card_data = {{ to.general, ids }} },
          skill_name = mumu.name,
          prompt = "#mobile__mumu-prey",
        })
      end
      room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonPrey, mumu.name, nil, true, player)
    end
  end,
})
mumu:addEffect("prohibit", {
  prohibit_response = function(self, player, card)
    return card and card.trueName == "slash" and player:getMark("@@mobile__mumu-turn") > 0
  end,
  prohibit_use = function(self, player, card)
    return card and card.trueName == "slash" and player:getMark("@@mobile__mumu-turn") > 0
  end,
})

return mumu
