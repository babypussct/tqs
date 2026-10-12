
local zexing = fk.CreateSkill{
  name = "zexing",
}

Fk:loadTranslationTable{
  ["zexing"] = "择行",
  [":zexing"] = "出牌阶段限一次，你可以展示一张牌并选择一名其他角色，令其选择一项："..
  "1.你观看其手牌并获得两张与展示牌花色不同的牌，然后其获得展示牌；"..
  "2.其失去1点体力，然后你可以重新选择一名其他角色并重复此流程（每回合每名角色限一次）。",

  ["#zexing"] = "择行：展示一张手牌并选择一名角色，其选择你获得其牌或失去1点体力",
  ["zexing_view"] = "%src观看你的手牌并获得两张牌，你获得其展示牌",
  ["#zexing-prey"] = "择行：获得其中两张牌",

  ["$zexing1"] = "",
  ["$zexing2"] = "",
}

zexing:addEffect("active", {
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#zexing",
  can_use = function(self, player)
    return player:usedSkillTimes(zexing.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and
      not table.contains(player:getTableMark("zexing-turn"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "zexing-turn", target)
    local cid = effect.cards[1]
    local suit = Fk:getCardById(cid):getSuitString()
    player:showCards(cid)
    if player.dead or target.dead then return end
    local choices = { "zexing_view:"..player.id, "loseHp" }
    local n = #table.filter(target:getCardIds("he"), function (id)
      return Fk:getCardById(id):getSuitString() == suit
    end)
    if n < 2 then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = zexing.name,
    })
    if choice == "loseHp" then
      room:loseHp(target, 1, zexing.name, player)
      if not player.dead and not player:isNude() and
        #player:getTableMark("zexing-turn") < #room.alive_players - 1 then
        room:askToUseActiveSkill(player, {
          skill_name = zexing.name,
          prompt = "#zexing",
        })
      end
    else
      if not target:isNude() then
        local card_data = {}
        if not target:isKongcheng() then
          table.insert(card_data, { "$Hand", target:getCardIds("h") })
        end
        if #target:getCardIds("e") > 0 then
          table.insert(card_data, { "$Equip", target:getCardIds("e") })
        end
        local cards = room:askToChooseCards(player, {
          target = target,
          min = 2,
          max = 2,
          flag = { card_data = card_data },
          skill_name = zexing.name,
          pattern = ".|.|^"..suit,
          prompt = "#zexing-prey",
        })
        if #cards > 0 then
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, zexing.name, nil, false, player)
        end
      end
      if not target.dead and table.contains(player:getCardIds("he"), cid) then
        room:moveCardTo(cid, Card.PlayerHand, target, fk.ReasonPrey, zexing.name, nil, true, target)
      end
    end
  end,
})

return zexing
