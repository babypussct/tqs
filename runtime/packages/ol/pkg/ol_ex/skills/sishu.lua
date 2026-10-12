
local sishu = fk.CreateSkill {
  name = "sishu",
}

Fk:loadTranslationTable {
  ["sishu"] = "思蜀",
  [":sishu"] = "出牌阶段开始时，你可选择一名角色，其本局游戏【乐不思蜀】的判定结果反转。",

  ["#sishu-choose"] = "思蜀：选择一名角色，令其本局游戏【乐不思蜀】的判定结果反转",
  ["@@sishu_effect"] = "思蜀",

  ["$sishu1"] = "蜀乐乡土，怎不思念？",
  ["$sishu2"] = "思乡心切，徘徊惶惶。",
}

sishu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sishu.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#sishu-choose",
      skill_name = sishu.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:setPlayerMark(to, "@@sishu_effect", 1 - to:getMark("@@sishu_effect"))
  end,
})


sishu:addEffect(fk.StartJudge, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@@sishu_effect") > 0 and target == player and data.reason == "indulgence"
  end,
  on_refresh = function(self, event, target, player, data)
    data:reversePattern()
  end,
})

return sishu