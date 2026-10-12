local xiangmian = fk.CreateSkill {
  name = "xiangmian",
}

Fk:loadTranslationTable{
  ["xiangmian"] = "相面",
  [":xiangmian"] = "出牌阶段限一次，你可以令一名其他角色进行一次判定，当该角色使用判定花色的牌或使用第X张牌后（X为判定点数），"..
  "其失去所有体力。每名其他角色限一次。",

  ["#xiangmian"] = "相面：令一名其他角色判定",
  ["@xiangmian"] = "相面",

  ["$xiangmian1"] = "以吾之见，阁下命不久矣。",
  ["$xiangmian2"] = "印堂发黑，将军危在旦夕。",
}

xiangmian:addEffect("active", {
  anim_type = "offensive",
  prompt = "#xiangmian",
  can_use = function(self, player)
    return player:usedSkillTimes(xiangmian.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and
      not table.contains(player:getTableMark(xiangmian.name), to_select)
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, xiangmian.name, target)
    local judge = {
      who = target,
      reason = xiangmian.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card and not target.dead then
      local mark = target:getTableMark("xiangmian_results")
      table.insert(mark, { judge.card:getSuitString(true), judge.card.number })
      room:setPlayerMark(target, "xiangmian_results", mark)
      local str = {}
      for _, result in ipairs(mark) do
        table.insert(str, Fk:translate(result[1])..result[2])
      end
      room:setPlayerMark(target, "@xiangmian", table.concat(str, " "))
    end
  end,
})

xiangmian:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and target:getMark("xiangmian_results") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("xiangmian_results")
    local new_mark, yes = {}, false
    for _, result in ipairs(mark) do
      result[2] = result[2] - 1
      if data.card:getSuitString(true) == result[1] or result[2] < 1 then
        yes = true
      else
        table.insert(new_mark, { result[1], result[2] })
      end
    end
    if #mark > 0 then
      room:setPlayerMark(player, "xiangmian_results", new_mark)
      local str = {}
      for _, result in ipairs(new_mark) do
        table.insert(str, Fk:translate(result[1])..result[2])
      end
      room:setPlayerMark(player, "@xiangmian", table.concat(str, " "))
    else
      room:setPlayerMark(player, "xiangmian_results", 0)
      room:setPlayerMark(player, "@xiangmian", 0)
    end
    if yes then
      room:loseHp(target, target.hp, xiangmian.name)
    end
  end,
})

return xiangmian
