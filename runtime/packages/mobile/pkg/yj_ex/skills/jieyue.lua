local jieyue = fk.CreateSkill {
  name = "m_ex__jieyue",
}

Fk:loadTranslationTable{
  ["m_ex__jieyue"] = "节钺",
  [":m_ex__jieyue"] = "结束阶段，你可以将一张牌交给一名其他角色，然后其选择一项：1.保留手牌和装备区内的各一张牌，然后弃置其余的牌；2.令你摸三张牌。",

  ["#m_ex__jieyue-choose"] = "节钺：可以选择一张牌交给一名其他角色",
  ["#m_ex__jieyue-select"] = "节钺：选择一张手牌和一张装备区里的牌保留，弃置其他的牌；或点“取消”令%src摸三张牌",

  ["$m_ex__jieyue1"] = "按丞相之命，此部今由余统摄！",
  ["$m_ex__jieyue2"] = "奉法行令，事上之节，岂有宽宥之理？",
}

jieyue:addAuxActiveSkill("#m_ex__jieyue_active", {
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then
      return Fk:currentRoom():getCardArea(to_select) ~= Fk:currentRoom():getCardArea(selected[1])
    end
    return #selected == 0
  end,
  feasible = function(self, player, selected, selected_cards)
    local x = 0
    if player:getHandcardNum() > 0 then x = x + 1 end
    if #player:getCardIds("e") > 0 then x = x + 1 end
    return #selected_cards == x
  end,
})

jieyue:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:hasSkill(jieyue.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".",
      skill_name = jieyue.name,
      prompt = "#m_ex__jieyue-choose",
      cancelable = true,
    })
    if #tos > 0 and #cards > 0 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:obtainCard(to, event:getCostData(self).cards, false, fk.ReasonGive, player.id, jieyue.name)
    if player.dead or to.dead then return false end
    local success, dat = room:askToUseActiveSkill(to, {
      skill_name = "#m_ex__jieyue_active",
      prompt = "#m_ex__jieyue-select:" .. player.id,
      cancelable = true,
    })
    if success and dat then
      local cards = table.filter(to:getCardIds{Player.Hand, Player.Equip}, function (id)
        return not (table.contains(dat.cards, id) or to:prohibitDiscard(Fk:getCardById(id)))
      end)
      if #cards > 0 then
        room:throwCard(cards, jieyue.name, to)
      end
    else
      room:drawCards(player, 3, jieyue.name)
    end
  end,
})

return jieyue
