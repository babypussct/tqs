local wuling = fk.CreateSkill {
  name = "wuling",
}

Fk:loadTranslationTable{
  ["wuling"] = "五灵",
  [":wuling"] = "出牌阶段限两次，你可以选择一名没有“五灵”标记的角色，按照你选择的顺序向其传授“五禽戏”。拥有“五灵”标记的角色在其准备阶段"..
  "按照传授的顺序依次切换为下一种效果：<br>"..
  "虎：当你使用指定唯一目标的牌对目标角色造成伤害时，此伤害+1。<br>"..
  "鹿：回复1点体力并弃置判定区里的所有牌，你不能成为延时锦囊牌的目标。<br>"..
  "熊：每回合限一次，当你受到伤害时，此伤害-1。<br>"..
  "猿：获得一名其他角色装备区里的一张牌。<br>"..
  "鹤：你摸三张牌。",

  ["#wuling"] = "五灵：向一名角色传授“五禽戏”",
  ["Please arrange WuLing cards"] = "请拖动分配“五禽戏”的顺序（从左至右）",
  ["#wuling-choice"] = "五灵：选择向 %dest 传授“五禽戏”的顺序<br>已选择：%arg",
  ["wuling1"] = "虎",
  ["wuling2"] = "鹿",
  ["wuling3"] = "熊",
  ["wuling4"] = "猿",
  ["wuling5"] = "鹤",
  ["wulingHu"] = "虎灵",
  ["wulingLu"] = "鹿灵",
  ["wulingXiong"] = "熊灵",
  ["wulingYuan"] = "猿灵",
  ["wulingHe"] = "鹤灵",
  ["@[wuling]"] = "五灵",
  ["#wuling-choose"] = "五灵：请选择一名其他角色，获得其装备区里的一张牌",

  ["$wuling1"] = "吾创五禽之戏，君可作以除疾。",
  ["$wuling2"] = "欲解万般苦，驱身仿五灵。",
}

Fk:addQmlMark{
  name = "wuling",
  how_to_show = function(name, value, p)
    if type(value) == "table" then
      local wulingMarkMap = {
        ["wulingHu"] = "wuling1",
        ["wulingLu"] = "wuling2",
        ["wulingXiong"] = "wuling3",
        ["wulingYuan"] = "wuling4",
        ["wulingHe"] = "wuling5",
      }
      return Fk:translate(wulingMarkMap[value[1][value[2]]])
    end
    return " "
  end,
  qml = { url = "packages/mobile/qml/WuLingMark.qml" },
}

wuling:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    local mark = p:getMark(wuling.name)
    if type(mark) == "table" and mark[2] == player.id then
      room:setPlayerMark(p, wuling.name, 0)
      room:setPlayerMark(p, "wuling_invoke", 0)
      room:setPlayerMark(p, "@[wuling]", 0)
    end
  end
end)

local wuLingMarkGainedEffect = function(mark, player)
  local room = player.room
  if mark == "wuling2" then
    room:notifySkillInvoked(player, "wulingLu", "support")
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = wuling.name,
      }
    end
    if not player.dead and #player:getCardIds("j") > 0 then
      player:throwAllCards("j", wuling.name)
    end
  elseif mark == "wuling4" then
    room:notifySkillInvoked(player, "wulingYuan", "control")
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return #p:getCardIds("e") > 0
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = wuling.name,
      prompt = "#wuling-choose",
      cancelable = false,
    })[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "e",
      skill_name = wuling.name,
    })
    room:obtainCard(player, card, true, fk.ReasonPrey, player, wuling.name)
  elseif mark == "wuling5" then
    room:notifySkillInvoked(player, "wulingHe", "drawcard")
    player:drawCards(3, wuling.name)
  end
end

wuling:addEffect("active", {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#wuling",
  times = function(self, player)
    return player.phase == Player.Play and 2 - player:usedEffectTimes(wuling.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(wuling.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select:getMark(wuling.name) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local result = room:askToCustomDialog(player, {
      skill_name = wuling.name,
      component = {
        url = "packages/mobile/qml/WuLingBox.qml",
        prop = {},
      }
    })
    local wulingMarkMap = {
      ["wulingHu"] = "wuling1",
      ["wulingLu"] = "wuling2",
      ["wulingXiong"] = "wuling3",
      ["wulingYuan"] = "wuling4",
      ["wulingHe"] = "wuling5",
    }
    local names = {}
    if result == "" then
      names = { "wulingHe", "wulingHu", "wulingXiong", "wulingYuan", "wulingLu" }
    else
      names = result.sort
    end
    result = table.map(names, function(name) return wulingMarkMap[name] end)
    room:setPlayerMark(target, wuling.name, { result, player.id })
    room:setPlayerMark(target, "wuling_invoke", tonumber(result[1][7]))
    room:setPlayerMark(target, "@[wuling]", { names, 1 })
    wuLingMarkGainedEffect(result[1], target)
  end,
})
wuling:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("wuling_invoke") == 1 and data.card then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data
        return #use.tos == 1 and use.tos[1] == data.to
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})
wuling:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("wuling_invoke") == 3 and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
  end,
})
wuling:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return to:getMark("wuling_invoke") == 2 and card and card.sub_type == Card.SubtypeDelayedTrick
  end,
})
wuling:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("wuling_invoke") ~= 0 and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = player:getMark(wuling.name)[1]
    local n = player:getMark("wuling_invoke")
    local new_index = table.indexOf(result, wuling.name..n) + 1
    if new_index > 5 then
      room:setPlayerMark(target, wuling.name, 0)
      room:setPlayerMark(target, "wuling_invoke", 0)
      room:setPlayerMark(target, "@[wuling]", 0)
      return false
    end
    room:setPlayerMark(player, "wuling_invoke", tonumber(result[new_index][7]))
    local mark = player:getMark("@[wuling]")
    mark[2] = new_index
    room:setPlayerMark(player, "@[wuling]", mark)
    wuLingMarkGainedEffect(result[new_index], player)
  end,
})

return wuling
