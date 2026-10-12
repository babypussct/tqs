local zhengbing = fk.CreateSkill {
  name = "ol__zhengbing",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = {"qun"},
}

Fk:loadTranslationTable{
  ["ol__zhengbing"] = "整兵",
  [":ol__zhengbing"] = "群势力技，出牌阶段限三次，你可以重铸一张牌，若此牌为：<br>"..
    "⬤【杀】，你的手牌上限+1；<br>⬤【闪】，你摸一张牌；<br>⬤【桃】或【酒】，此回合结束时，你执行一个额外出牌阶段。"..
    "然后若你以此法触发过所有选项，你变更势力至魏。",

  ["#ol__zhengbing"] = "整兵：你可以重铸一张牌，若为基本牌，获得额外效果",
  ["@ol__zhengbing"] = "整兵",

  ["$ol__zhengbing1"] = "厉兵秣马，待敌制胜。",
  ["$ol__zhengbing2"] = "戎装既整，如羽扣弦。",
}

zhengbing:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@ol__zhengbing", 0)
end)

zhengbing:addEffect("active", {
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  prompt = "#ol__zhengbing",
  times = function(self, player)
    return player.phase == Player.Play and 3 - player:usedSkillTimes(zhengbing.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(zhengbing.name, Player.HistoryPhase) < 3
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local name = Fk:getCardById(effect.cards[1]).trueName
    room:recastCard(effect.cards, player, zhengbing.name)
    if player.dead then return end
    local mark = player:getTableMark("@ol__zhengbing")
    if name == "slash" then
      table.insertIfNeed(mark, name)
      room:setPlayerMark(player, "@ol__zhengbing", mark)
      if player:getMark("ol__zhengbing_maxcards") < 20 then
        room:addPlayerMark(player, "ol__zhengbing_maxcards")
        room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
      end
    elseif name == "jink" then
      table.insertIfNeed(mark, name)
      room:setPlayerMark(player, "@ol__zhengbing", mark)
      player:drawCards(1, zhengbing.name)
    elseif name == "peach" or name == "analeptic" then
      table.insertIfNeed(mark, name)
      room:setPlayerMark(player, "@ol__zhengbing", mark)
      room:setPlayerMark(player, "zhengbingExtraPhase-turn", 1)
    end
    if #mark > 2 and table.contains(mark, "slash") and table.contains(mark, "jink") then
      room:changeKingdom(player, "wei", true)
    end
  end,
})

zhengbing:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:getMark("zhengbingExtraPhase-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraPhase(Player.Play, zhengbing.name)
  end,
})

return zhengbing
