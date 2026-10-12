local jiaohua = fk.CreateSkill{
  name = "mobile__jiaohua",
}

Fk:loadTranslationTable{
  ["mobile__jiaohua"] = "教化",
  [":mobile__jiaohua"] = "出牌阶段限两次，你可以令一名角色从牌堆获得一张未以此法选择过的类别的牌；所有类别均被选择后，重置选择过的类别。",

  ["#mobile__jiaohua"] = "教化：令一名角色获得你选择的类别的牌",

  ["$mobile__jiaohua1"] = "教民崇化，以定南疆。",
  ["$mobile__jiaohua2"] = "知礼数，崇王化，则民不复叛矣。",
}

jiaohua:addEffect("active", {
  anim_type = "support",
  prompt = "#mobile__jiaohua",
  card_num = 0,
  target_num = 1,
  times = function(self, player)
    return player.phase == Player.Play and 2 - player:usedSkillTimes(jiaohua.name, Player.HistoryPhase) or -1
  end,
  interaction = function(self, player)
    local choices = {"basic", "trick", "equip"}
    for i = 3, 1, -1 do
      if table.contains(player:getTableMark(jiaohua.name), choices[i]) then
        table.remove(choices, i)
      end
    end
    if #choices == 0 then return end
    return UI.ComboBox {choices = choices}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(jiaohua.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = room:getCardsFromPileByRule(".|.|.|.|.|"..self.interaction.data)
    if #card > 0 then
      room:addTableMark(player, jiaohua.name, self.interaction.data)
      if #player:getTableMark(jiaohua.name) == 3 then
        room:setPlayerMark(player, jiaohua.name, 0)
      end
      room:obtainCard(target, card, false, fk.ReasonJustMove, player, jiaohua.name)
    end
  end,
})

return jiaohua
