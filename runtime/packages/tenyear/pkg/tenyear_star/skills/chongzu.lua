local chongzu = fk.CreateSkill {
  name = "chongzu",
}

Fk:loadTranslationTable{
  ["chongzu"] = "冲阻",
  [":chongzu"] = "当你使用牌结算结束后，若目标包含你，你可以选择一项：1.令你使用的下一张牌无次数和距离限制；2.摸两张牌，然后本回合不可选择此选项。（增加选项：" ..
  "3.令你使用下一张牌指定第一个目标后，可对目标中的一名其他角色造成1点伤害）。",

  ["chongzu_unlimited"] = "使用下张牌无次数距离限制",
  ["chongzu_draw"] = "摸两张牌，本回合不可再选此项",
  ["chongzu_damage"] = "使用下张牌对一个目标造成伤害",
  ["@@chongzu_unlimited"] = "冲阻",
  ["#chongzu-damage"] = "冲阻：你可对其中一名角色造成1点伤害",

  ["$chongzu1"] = "黄天已死，北海当立！",
  ["$chongzu2"] = "三日练靶，今日便穿汝喉舌！",
}

chongzu:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chongzu.name) and table.contains(data.tos, player)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = { "chongzu_unlimited", "chongzu_draw", "Cancel" }
    if player:getMark("chongzu_update") > 0 then
      table.insert(choices, 3, "chongzu_damage")
    end
    local allChoices = table.simpleClone(choices)

    if player:getMark("chongzu_drawn-turn") > 0 then
      table.remove(choices, 2)
    end

    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = chongzu.name,
        all_choices = allChoices,
      }
    )

    if choice == "Cancel" then
      return false
    end

    event:setCostData(self, { choice = choice })
    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = chongzu.name
    local room = player.room
    local choice = event:getCostData(self).choice

    if choice == "chongzu_draw" then
      player:drawCards(2, skillName)
      room:setPlayerMark(player, "chongzu_drawn-turn", 1)
    elseif choice == "chongzu_damage" then
      room:setPlayerMark(player, "chongzu_damage", 1)
    else
      room:setPlayerMark(player, "@@chongzu_unlimited", 1)
    end
  end,
})

chongzu:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and player:getMark("@@chongzu_unlimited") > 0
  end,
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:getMark("@@chongzu_unlimited") > 0
  end,
})

chongzu:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and (player:getMark("@@chongzu_unlimited") > 0 or player:getMark("chongzu_damage") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@chongzu_unlimited") > 0 then
      room:setPlayerMark(player, "@@chongzu_unlimited", 0)
      data.extraUse = true
    end

    if player:getMark("chongzu_damage") > 0 then
      room:setPlayerMark(player, "chongzu_damage", 0)
      data.extra_data = data.extra_data or {}
      data.extra_data.chongzuUser = player
    end
  end,
})

chongzu:addEffect(fk.TargetSpecified, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      (data.extra_data or {}).chongzuUser == player and
      data.firstTarget and
      player:isAlive() and
      table.find(data.use.tos, function(p) return p ~= player end)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = chongzu.name
    local room = player.room

    local targets = table.filter(data.use.tos, function(p) return p ~= player end)
    if #targets == 0 then
      return false
    end
    local tos = room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = skillName,
        prompt = "#chongzu-damage",
      }
    )

    if #tos > 0 then
      room:damage{
        from = player,
        to = tos[1],
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

chongzu:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "chongzu_update", 0)
end)

return chongzu
