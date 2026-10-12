local jichao = fk.CreateSkill {
  name = "jichao",
}

Fk:loadTranslationTable{
  ["jichao"] = "激潮",
  [":jichao"] = "出牌阶段限一次，你可以选择一项：1.令一名其他角色随机将一半数量的手牌（向上取整）和装备区里的牌置于武将牌上称为“溟”；" ..
  "2.令所有其他角色同时将其所有牌置于武将牌上称为“溟”，然后此项失效直到你累计造成3点伤害。",

  ["#jichao-active"] = "激潮：你可选择一项执行",
  ["jichao_half"] = "令一名其他角色随机将一半数量的手牌（向上取整）和装备区里的牌置为“溟”",
  ["jichao_all"] = "令所有其他角色将所有牌置为“溟”，然后此项失效直到你累计造成3点伤害",

  ["$jichao1"] = "逆我者，沧浪覆之！",
  ["$jichao2"] = "鱼龙百变，挟沧海以令众生！",
}

jichao:addEffect("active", {
  prompt = "#jichao-active",
  interaction = function(self, player)
    local choices = { "jichao_half" }
    if
      player:getMark("jichao_all_used") == 0 and
      table.find(Fk:currentRoom().alive_players, function(p) return p ~= player and not p:isNude() end)
    then
      table.insert(choices, "jichao_all")
    end

    return UI.ComboBox { choices = choices, all_choices = { "jichao_half", "jichao_all" } }
  end,
  card_num = 0,
  target_num = function(self)
    return self.interaction.data == "jichao_all" and 0 or 1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(jichao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if self.interaction.data == "jichao_half" then
      return #selected == 0 and to_select ~= player and not to_select:isNude()
    end
  end,
  on_use = function(self, room, effect)
    if self.interaction.data == "jichao_all" then
      local from = effect.from
      local others = room:getOtherPlayers(from)
      room:doIndicate(from, others)

      local moveList = {}
      table.forEach(room:getOtherPlayers(from), function(p)
        if not p:isNude() then
          table.insert(moveList, {
            ids = p:getCardIds("he"),
            from = p,
            to = p,
            toArea = Card.PlayerSpecial,
            moveReason = fk.ReasonJustMove,
            specialName = "$cangming_ming",
            moveVisible = false,
          })
        end
      end)

      room:moveCards(table.unpack(moveList))

      room:setPlayerMark(from, "jichao_all_used", 3)
    else
      local to = effect.tos[1]
      local handcards = to:getCardIds("h")
      local toPut = room:tableRandomPick(handcards, math.ceil(#handcards / 2))
      table.insertTable(toPut, to:getCardIds("e"))
      to:addToPile("$cangming_ming", toPut, false, jichao.name, to)
    end
  end,
})

jichao:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:isAlive() and player:getMark("jichao_all_used") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "jichao_all_used")
  end,
})

jichao:addAcquireEffect(function(self, player)
  local room = player.room
  if not room:hasSkill("cangming") then
    room:addSkill("cangming")
  end
end)

return jichao
