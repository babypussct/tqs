local yance = fk.CreateSkill {
  name = "yance",
}

Fk:loadTranslationTable {
  ["yance"] = "演策",
  [":yance"] = "每轮限一次，首轮开始时，或准备阶段，你可以选择一项：从牌堆中随机获得一张锦囊牌；执行<a href='wolongyance'>“卧龙演策”</a>。" ..
  "若你执行“卧龙演策”，当一张牌被使用时，若此牌的类别或颜色与你的预测相同，你摸一张牌（每次执行“卧龙演策”至多因此摸五张牌）。<br>" ..
  "当“卧龙演策”的预测全部验证后，或当你再次执行“卧龙演策”时，若你本次“卧龙演策”正确的预测数量：<br>" ..
  "为0，你失去1点体力，此后“卧龙演策”可预测的牌数-1；<br>" ..
  "不足一半，你弃置一张牌；<br>" ..
  "至少一半（向上取整），你根据本次预测的方式，从牌堆中获得一张符合你声明条件的牌；<br>" ..
  "全部正确，你摸两张牌，此后“卧龙演策”可预测的牌数+1（至多为7）。",

  ["wolongyance"] = "预测此后被使用的指定数量张牌的颜色或类别（初始可预测的牌数为3），“预测的方式”即通过颜色预测或通过类别预测。"..
  "<font color='#5EBF9B'>绿色代表预测成功</font><font color='yellow'>黄色代表预测失败</font>"..
  "此预测在一名角色使用牌时揭示，若所有预测均已揭示，称为全部验证。",
  ["yance_prey"] = "获得一张锦囊牌",
  ["yance_yance"] = "执行“卧龙演策”",
  ["#yance-choice"] = "演策：预测将被使用的牌（第%arg张，共%arg2张）",
  ["@[private]yance"] = "卧龙演策：<br/>",
  ["#yance-prey"] = "演策：获得一张符合声明条件的牌",
  ["red_char"] = "红",
  ["black_char"] = "黑",

  ["$yance1"] = "以今日之时局，唯以此策解之。",
  ["$yance2"] = "今世变化难测，需赖以演策之术。",
  ["$yance3"] = "百策百中，勤在推演而已。",
  ["$yance4"] = "哎，算计百般，终是徒劳。",
  ["$yance5"] = "所谓算无遗策，亦不过如此而已。",
  ["$yance6"] = "吾已尽全力，奈何老天仍胜我一筹。",
  ["$yance7"] = "未思周密，使敌有残喘之机。",

}
local U = require "packages.utility.utility"
---@param room AbstractRoom
---@param player Player
---@param friend string
---@return boolean
local function GongliFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
      not not table.find(room.alive_players, function(p)
        return p.role == player.role and (p.general:endsWith(friend) or p.deputyGeneral:endsWith(friend))
      end)
end

local function DoYance(player)
  local room = player.room
  local results = table.simpleClone(player:getTableMark("yance_results"))
  local choices = table.contains({ "red", "black" }, player:getMark("yance_guess")[1]) and { "red", "black" } or
      { "basic", "trick", "equip" }
  local fangqiu_trigger = 1
  local yes = #table.filter(results, function(n)
    return n == 1
  end)

  if player:getMark("fangqiu_trigger") > 0 then
    room:setPlayerMark(player, "fangqiu_trigger", 0)
    if #player:getTableMark("yance_guess") == #player:getTableMark("yance_results") then
      fangqiu_trigger = 2
      if #player:getTableMark("yance_guess") > 3 and yes == #results then
        player:setSkillUseHistory("fangqiu", 0, Player.HistoryGame)
      end
    end
  end

  room:setPlayerMark(player, "yance_guess", 0)
  room:setPlayerMark(player, "yance_results", 0)
  room:setPlayerMark(player, "@[private]yance", 0)

  if yes < #results / 2 then
    room:notifySkillInvoked(player, yance.name, "negative")
    if yes == 0 then
      player:broadcastSkillInvoke(yance.name, 4)
      room:addPlayerMark(player, "yance_fail", fangqiu_trigger)
      room:loseHp(player, fangqiu_trigger, yance.name)
    else
      player:broadcastSkillInvoke(yance.name, 6)
    end
    if not player.dead then
      room:askToDiscard(player, {
        min_num = fangqiu_trigger,
        max_num = fangqiu_trigger,
        include_equip = true,
        skill_name = yance.name,
        cancelable = false,
      })
    end
  else
    room:notifySkillInvoked(player, yance.name, "drawcard")
    if yes == #results then
      player:broadcastSkillInvoke(yance.name, 3)
    else
      player:broadcastSkillInvoke(yance.name, 7)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = yance.name,
      prompt = "#yance-prey",
    })
    local pattern
    if table.contains({ "basic", "trick", "equip" }, choice) then
      pattern = ".|.|.|.|.|" .. choice
    elseif choice == "red" then
      pattern = ".|.|heart,diamond"
    elseif choice == "black" then
      pattern = ".|.|spade,club"
    end
    local cards = room:getCardsFromPileByRule(pattern, fangqiu_trigger, "drawPile")
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, yance.name, nil, false, player)
    end
    if yes == #results and not player.dead then
      room:addPlayerMark(player, "yance_success", fangqiu_trigger)
      player:drawCards(1 + fangqiu_trigger, yance.name)
    end
  end
end

local yance_spec = {
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = { "yance_prey", "yance_yance", "Cancel" },
      skill_name = yance.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(yance.name, room:tableRandomPick { 1, 2 })
    if event:getCostData(self).choice == "yance_prey" then
      room:notifySkillInvoked(player, yance.name, "drawcard")
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick", 1, "drawPile")
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, yance.name, nil, false, player)
      end
    else
      room:notifySkillInvoked(player, yance.name, "control")
      if player:getMark("yance_guess") ~= 0 then
        DoYance(player)
        if player.dead then return end
      end
      local n = 3
      n = n - player:getMark("yance_fail") + player:getMark("yance_success")
      if GongliFriend(room, player, "friend__pangtong") then
        n = n + 1
      end
      if n < 1 then return end
      n = math.min(n, 7)
      local all_choices = { "basic", "trick", "equip", "red", "black" }
      local choice = room:askToChoice(player, {
        choices = all_choices,
        skill_name = yance.name,
        prompt = "#yance-choice:::1:" .. n
      })
      room:addTableMark(player, "yance_guess", choice)
      U.setPrivateMark(player, "yance", { choice .. "_char" })
      if n > 1 then
        local mark = U.getPrivateMark(player, "yance")
        local choices = table.contains({ "red", "black" }, choice) and { "red", "black" } or
            { "basic", "trick", "equip" }
        for i = 2, n, 1 do
          choice = room:askToChoice(player, {
            choices = choices,
            skill_name = yance.name,
            prompt = "#yance-choice:::" .. i .. ":" .. n,
            all_choices = all_choices,
          })
          room:addTableMark(player, "yance_guess", choice)
          table.insert(mark, choice .. "_char")
        end
        U.setPrivateMark(player, "yance", mark)
      end
    end
  end,
}

yance:addEffect(fk.RoundStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yance.name) and player.room:getBanner("RoundCount") == 1 and
        player:usedSkillTimes(yance.name, Player.HistoryRound) == 0
  end,
  on_cost = yance_spec.on_cost,
  on_use = yance_spec.on_use,
})
yance:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yance.name) and player.phase == Player.Start and
        player:usedSkillTimes(yance.name, Player.HistoryRound) == 0
  end,
  on_cost = yance_spec.on_cost,
  on_use = yance_spec.on_use,
})
yance:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("yance_guess") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = 2
    local index = #player:getTableMark("yance_results") + 1
    local choice = player:getTableMark("yance_guess")[index]
    if data.card:getTypeString() == choice or data.card:getColorString() == choice then
      result = 1
    elseif GongliFriend(room, player, "friend__xushu") and index == 1 then
      result = 1
    end
    local mark = U.getPrivateMark(player, "yance")
    if result == 1 then
      mark[index] = "<font color='#5EBF9B'>" .. Fk:translate(mark[index]) .. "</font>"
      if #table.filter(player:getTableMark("yance_results"), function(n)
            return n == 1
          end) < 5 then
        player:broadcastSkillInvoke(yance.name, 5)
        room:notifySkillInvoked(player, yance.name, "drawcard")
        player:drawCards(1, yance.name)
        if player.dead then return end
      end
    else
      mark[index] = "<font color='yellow'>" .. Fk:translate(mark[index]) .. "</font>"
    end
    U.setPrivateMark(player, "yance", mark)
    room:addTableMark(player, "yance_results", result)
    if #player:getTableMark("yance_guess") == #player:getTableMark("yance_results") then
      DoYance(player)
    end
  end,
})

return yance
