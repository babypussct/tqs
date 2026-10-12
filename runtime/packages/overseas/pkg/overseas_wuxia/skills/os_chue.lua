local osChue = fk.CreateSkill {
  name = "os__chue"
}

Fk:loadTranslationTable{
  ["os__chue"] = "除恶",
  [":os__chue"] = "①当你使用【杀】指定唯一目标时，若存在能成为此【杀】目标的一名角色，你可失去1点体力，额外指定至多X个目标。" ..
  "②当你受到伤害或失去体力后，你获得1枚“勇”。③每个回合结束时，你可弃X枚“勇”，视为使用一张【杀】，此【杀】的伤害值基数+1且额外选择X个目标。（X为你的体力值）",

  ["@os__bravery"] = "勇",
  ["#os__chue-loseHp"] = "除恶：你可失去1点体力，然后此【杀】额外指定至多你的体力值个目标",
  ["#os__chue-use"] = "除恶：你可弃%arg枚“勇”，视为使用一张伤害值基数+1且额外选择%arg个目标的【杀】",
  ["#os__chue-choose"] = "除恶：为此%arg额外指定至多%arg2个目标",
  ["#os__chue-slash"] = "除恶：视为使用一张伤害值基数+1的【杀】，目标至多%arg个",

  ["$os__chue1"] = "关某此生，誓斩天下恶徒！",
  ["$os__chue2"] = "政法不行，羽当替天行之！"
}

osChue:addEffect(fk.TargetSpecifying, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(osChue.name) then return false end
    if target ~= player then return false end
    return data.card.trueName == "slash" and player.hp > 0 and data:isOnlyTarget(data.to) and
      #data:getExtraTargets({ bypass_times = true, bypass_distances = true }) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = osChue.name, prompt = "#os__chue-loseHp" })
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osChue.name
    local room = player.room
    room:loseHp(player, 1, skillName)
    if not player:isAlive() then return end
    local availableTargets = data:getExtraTargets({ bypass_times = true, bypass_distances = true })
    local num = player.hp
    if #availableTargets > 0 and num > 0 then
      local targets = room:askToChoosePlayers(player, {
        targets = availableTargets,
        min_num = 1,
        max_num = num,
        prompt = "#os__chue-choose:::" .. data.card:toLogString() .. ":" .. num,
        skill_name = skillName
      })
      if #targets > 0 then
        table.forEach(targets, function(p) data:addTarget(p) end)
      end
    end
  end,
})

osChue:addEffect(fk.Damaged, {
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@os__bravery")
  end,
})

osChue:addEffect(fk.HpLost, {
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@os__bravery")
  end,
})

osChue:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(osChue.name) then return false end
    return player:getMark("@os__bravery") >= player.hp and player:canUse(Fk:cloneCard("slash"), { bypass_times = true, bypass_distances = true })
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = osChue.name, prompt = "#os__chue-use:::" .. player.hp })
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osChue.name
    local room = player.room
    room:removePlayerMark(player, "@os__bravery", player.hp)
    local card = Fk:cloneCard("slash")
    card.skillName = skillName
    local availableTargets = table.filter(room:getOtherPlayers(player, false), function(p) return player:canUseTo(card, p, { bypass_times = true, bypass_distances = true }) end)
    local num = card.skill:getMaxTargetNum(player, card) + player.hp
    if #availableTargets > 0 and num > 0 then
      local targets = room:askToChoosePlayers(player, {
        targets = availableTargets,
        min_num = 1,
        max_num = num,
        prompt = "#os__chue-slash:::" .. num,
        skill_name = skillName,
        cancelable = false
      })
      local use = { ---@class UseCardDataSpec
        from = player,
        tos = targets,
        card = card,
        extraUse = true,
      }
      use.additionalDamage = (use.additionalDamage or 0) + 1
      room:useCard(use)
    end
  end,
})

return osChue
