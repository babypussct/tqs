local zhuitao = fk.CreateSkill {
  name = "ty__zhuitao",
  tags = { Skill.Combo },
}

Fk:loadTranslationTable{
  ["ty__zhuitao"] = "追讨",
  [":ty__zhuitao"] = "连招技（黑色牌+伤害牌），你可选择一名本回合未以此法选择过的其他角色并摸2张牌，"..
    "本回合你与其计算距离为1，你对其使用伤害牌或黑色牌结算后，每满足一项可弃置其一张牌。",

  ["#ty__zhuitao-choose"] = "追讨：选择一名其他角色",
  ["@@ty__zhuitao"] = "追讨 +伤害牌",
  ["@@ty__zhuitao-turn"] = "追讨",

  ["$ty__zhuitao1"] = "从来中原恨，须用颅山叠。",
  ["$ty__zhuitao2"] = "汉喉不咽仇，岂教胡马南度！"
}

zhuitao:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuitao.name) and
      data.extra_data and data.extra_data.combo_skill and data.extra_data.combo_skill[zhuitao.name]
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("ty__zhuitao-turn")
    local tos = table.filter(room.alive_players, function(p)
      return p ~= player and not table.contains(mark, p)
    end)
    tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = tos,
      skill_name = zhuitao.name,
      prompt = "#ty__zhuitao-choose",
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ty__zhuitao", 0)
    local to = event:getCostData(self).tos[1]
    room:addPlayerMark(to, "@@ty__zhuitao-turn", 1)
    room:addTableMark(player, "ty__zhuitao-turn", to)
    player:drawCards(2, zhuitao.name)
  end,
})

zhuitao:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhuitao.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("@@ty__zhuitao") > 0 and data.card.is_damage_card then
      data.extra_data = data.extra_data or {}
      data.extra_data.combo_skill = data.extra_data.combo_skill or {}
      data.extra_data.combo_skill[zhuitao.name] = true
    end
    if data.card.color == Card.Black then
      room:setPlayerMark(player, "@@ty__zhuitao", 1)
    else
      room:setPlayerMark(player, "@@ty__zhuitao", 0)
    end
  end,
})

zhuitao:addEffect("distance", {
  fixed_func = function(self, from, to)
    if table.contains(from:getTableMark("ty__zhuitao-turn"), to) then
      return 1
    end
  end,
})

zhuitao:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.from == player and not player.dead and (data.card.color == Card.Black or data.card.is_damage_card) then
      local tos = table.filter(player:getTableMark("ty__zhuitao-turn"), function(p)
        return table.contains(data.tos, p) and not p.dead
      end)
      if #tos > 0 then
        player.room:sortByAction(tos)
        event:setCostData(self, { tos = tos, no_indicate = true })
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = 0
    if data.card.color == Card.Black then
      n = n + 1
    end
    if data.card.is_damage_card then
      n = n + 1
    end
    for _, p in ipairs(event:getCostData(self).tos) do
      if player.dead then break end
      if not p.dead and not p:isNude() then
        local cards = room:askToChooseCards(player, {
          target = p,
          flag = "he",
          skill_name = zhuitao.name,
          min = 1,
          max = n,
          cancelable = true,
        })
        if #cards > 0 then
          room:throwCard(cards, zhuitao.name, p, player)
        end
      end
    end
  end,
})

return zhuitao
