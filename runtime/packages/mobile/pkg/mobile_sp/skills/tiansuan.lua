local tiansuan = fk.CreateSkill {
  name = "tiansuan",
}

Fk:loadTranslationTable{
  ["tiansuan"] = "天算",
  [":tiansuan"] = "每轮限一次，出牌阶段，你可以抽取一个“命运签”" ..
    "（在抽签开始前，你可以悄悄作弊，额外放入一个“命运签”增加其抽中的机会）。" ..
    "<br/>然后你选择一名角色，其获得命运签的效果直到你的下回合开始。" ..
    "<br/>若其获得的是“上上签”，你观看其手牌并从其区域内获得一张牌；" ..
    "若其获得的是“上签”，你从其处获得一张牌。" ..
    "<br/>各种“命运签”的效果如下：" ..
    "<br/>上上签：防止受到的伤害。" ..
    "<br/>上签：受到伤害时，若伤害值大于1，则将伤害值改为1；每受到一点伤害后，你摸一张牌。" ..
    "<br/>中签：受到伤害时，将伤害改为火焰伤害，若此伤害值大于1，则将伤害值改为1。" ..
    "<br/>下签：受到伤害时，伤害值+1。" ..
    "<br/>下下签：受到伤害时，伤害值+1；不能使用【桃】和【酒】。 ",
  ["#tiansuan"] = "天算：你可以抽取一个“命运签”（你可额外放入一个任意签）",
  ["tiansuanNone"] = "不作弊",
  ["tiansuanSSR"] = "上上签",
  ["tiansuanS"] = "上签",
  ["tiansuanA"] = "中签",
  ["tiansuanB"] = "下签",
  ["tiansuanC"] = "下下签",
  ["#TiansuanResult"] = "%from 天算的抽签结果是 %arg",
  ["@tiansuan"] = "天算",
  ["#tiansuan-choose"] = "天算：抽签结果是 %arg ，请选择一名角色获得签的效果",

  ['$tiansuan1'] = '汝既持签问卜，亦当应天授命。',
  ['$tiansuan2'] = '尔若居正体道，福寿自当天成。',
}

tiansuan:addEffect("active", {
  card_filter = Util.FalseFunc,
  prompt = "#tiansuan",
  interaction = UI.ComboBox {
    choices = { "tiansuanNone", "tiansuanSSR", "tiansuanS", "tiansuanA", "tiansuanB", "tiansuanC" }
  },
  can_use = function(self, player)
    return player:usedSkillTimes(tiansuan.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = tiansuan.name
    local player = effect.from
    room:setPlayerMark(player, "tiansuan", 1)
    local choices = {
      "SSR", "SSR",
      "S", "S", "S",
      "A", "A", "A", "A",
      "B", "B", "B",
      "C", "C",
    }
    local dat = self.interaction.data
    if dat ~= "tiansuanNone" then
      table.insert(choices, dat:sub(9))
    end
    local result = "tiansuan" .. room:tableRandomPick(choices)
    room:sendLog{ type = "#TiansuanResult", from = player.id, arg = result, toast = true }

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = room:getAlivePlayers(false),
        min_num = 1,
        max_num = 1,
        prompt = "#tiansuan-choose:::" .. result,
        skill_name = skillName,
        cancelable = false,
      }
    )
    local tgt = tos[1]
    room:setPlayerMark(tgt, "@tiansuan", result)

    if result == "tiansuanSSR" then
      local card_data = {}
      if not tgt:isKongcheng() and tgt ~= player then
        table.insert(card_data, { "$Hand", tgt.player_cards[Player.Hand] })
      end
      if #tgt.player_cards[Player.Equip] > 0 then
        table.insert(card_data, { "$Equip", tgt.player_cards[Player.Equip] })
      end
      if #tgt.player_cards[Player.Judge] > 0 then
        table.insert(card_data, { "$Judge", tgt.player_cards[Player.Judge] })
      end
      if #card_data == 0 then return end
      local id = room:askToChooseCard(player, { target = tgt, flag = { card_data = card_data }, skill_name = skillName })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, skillName)
    elseif result == "tiansuanS" then
      if tgt:isNude() then return end
      local id = room:askToChooseCard(player, { target = tgt, flag = "he", skill_name = skillName })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, skillName)
    end
  end,
})

tiansuan:addEffect(fk.DamageInflicted, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains({ "tiansuanB", "tiansuanC" }, player:getMark("@tiansuan"))
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

tiansuan:addEffect(fk.DetermineDamageInflicted, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    local mark = player:getMark("@tiansuan")
    return mark == "tiansuanSSR" or (mark == "tiansuanS" and data.damage > 1) or mark == "tiansuanA"
  end,
  on_use = function(self, event, target, player, data)
    local mark = player:getMark("@tiansuan")
    if mark == "tiansuanSSR" then
      data:preventDamage()
    elseif mark == "tiansuanS" then
      if data.damage > 1 then data:changeDamage(1 - data.damage) end
    elseif mark == "tiansuanA" then
      data.damageType = fk.FireDamage
      if data.damage > 1 then data:changeDamage(1 - data.damage) end
    end
  end,
})

tiansuan:addEffect(fk.Damaged, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@tiansuan") == "tiansuanS"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(data.damage, tiansuan.name)
  end,
})

tiansuan:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return (card.trueName == "peach" or card.trueName == "analeptic") and player:getMark("@tiansuan") == "tiansuanC"
  end,
})

local tiansuanClearSpec = {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("tiansuan") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "tiansuan", 0)
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@tiansuan") ~= 0 then
        room:setPlayerMark(p, "@tiansuan", 0)
      end
    end
  end,
}

tiansuan:addEffect(fk.TurnStart, tiansuanClearSpec)

tiansuan:addEffect(fk.Death, tiansuanClearSpec)

return tiansuan
