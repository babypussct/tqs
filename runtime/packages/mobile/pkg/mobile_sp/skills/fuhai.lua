local fuhai = fk.CreateSkill{
  name = "mobile__fuhaiw",
}

Fk:loadTranslationTable{
  ["mobile__fuhaiw"] = "浮海",
  [":mobile__fuhaiw"] = "出牌阶段限一次，你可以令所有其他角色同时选择“潮起”或“潮落”，然后你摸X张牌（X为从你的下家开始连续选择相同的角色数）。",

  ["#mobile__fuhaiw"] = "浮海：令所有其他角色选择“潮起”或“潮落”，你摸若干张牌",
  ["mobile__fuhaiw1"] = "潮起",
  ["mobile__fuhaiw2"] = "潮落",
  ["#mobile__fuhaiw-choice"] = "浮海：选择一项，有可能令 %src 摸牌",

  ["$mobile__fuhaiw1"] = "宦海沉浮，生死难料！",
  ["$mobile__fuhaiw2"] = "跨海南征，波涛起浮。",
}

fuhai:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#mobile__fuhaiw",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(fuhai.name, Player.HistoryPhase) == 0 and #Fk:currentRoom().alive_players > 1
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = room:getOtherPlayers(player)
    room:doIndicate(player, targets)
    local result = room:askToJointChoice(player, {
      players = targets,
      choices = { "mobile__fuhaiw1", "mobile__fuhaiw2" },
      skill_name = fuhai.name,
      prompt = "#mobile__fuhaiw-choice:"..player.id,
      send_log = true,
    })
    local n, str = 0, ""
    for _, p in ipairs(targets) do
      if str == "" then
        str = result[p]
      end
      if result[p] == str then
        n = n + 1
      else
        break
      end
    end

    room:delay(1000)
    if n > 1 then
      player:drawCards(n, fuhai.name)
    end
  end,
})

return fuhai
