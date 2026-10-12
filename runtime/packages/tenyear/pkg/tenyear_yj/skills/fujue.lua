local fujue = fk.CreateSkill {
  name = "fujue",
}

Fk:loadTranslationTable{
  ["fujue"] = "复爵",
  [":fujue"] = "出牌阶段限一次，你可以将你的手牌调整至五张，然后移动场上一张牌。"..
  "若此过程中你获得且失去过牌，本回合你计算与其他角色的距离-1且你下次使用的牌无法被响应。",

  ["#fujue"] = "复爵：将手牌调整至五张，然后移动场上一张牌",
  ["#fujue-move"] = "复爵：移动场上一张牌",

  ["$fujue1"] = "《周礼》有言，爵分公、侯、伯、子、男。",
  ["$fujue2"] = "复五等之爵，明尊卑之序。",
}

fujue:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#fujue",
  can_use = function(self, player)
    return player:usedSkillTimes(fujue.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local yes1, yes2 = false, false
    local n = player:getHandcardNum() - 5
    if n > 0 then
      if #room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = fujue.name,
        cancelable = false,
      }) > 0 then
        yes2 = true
      end
    elseif n < 0 then
      yes1 = true
      player:drawCards(-n, fujue.name)
    end
    if player.dead then return end
    if #room:canMoveCardInBoard() > 0 then
      local targets = room:askToChooseToMoveCardInBoard(player, {
        skill_name = fujue.name,
        prompt = "#fujue-move",
        cancelable = false,
      })
      local result = room:askToMoveCardInBoard(player, {
        target_one = targets[1],
        target_two = targets[2],
        skill_name = fujue.name,
      })
      if player.dead then return end
      if result then
        if result.to == player then
          yes1 = true
        end
        if result.from == player then
          yes2 = true
        end
      end
    end
    if yes1 and yes2 then
      room:addPlayerMark(player, "fujue-turn", 1)
      room:setPlayerMark(player, "fujue_disresponsive", 1)
    end
  end,
})

fujue:addEffect(fk.CardUsing, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("fujue_disresponsive") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "fujue_disresponsive", 0)
    data.disresponsiveList = table.simpleClone(room.players)
  end,
})

fujue:addEffect("distance", {
  correct_func = function(self, from, to)
    return -from:getMark("fujue-turn")
  end,
})

return fujue
