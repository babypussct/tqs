local tanbei = fk.CreateSkill {
  name = "chaos__tanbei",
}

Fk:loadTranslationTable{
  ["chaos__tanbei"] = "贪狈",
  [":chaos__tanbei"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.你获得其一张手牌，本回合不能再对其使用牌；"..
  "2.你本回合对其使用牌无距离和次数限制。",

  ["#chaos__tanbei"] = "贪狈：令一名角色选择：你获得其手牌，或你对其使用牌无次数距离限制",
  ["chaos__tanbei1"] = "%src获得你一张手牌，本回合不能对你使用牌",
  ["chaos__tanbei2"] = "%src本回合对你使用牌无距离次数限制",
  ["@@chaos__tanbei-turn"] = "贪狈",
}

tanbei:addEffect("active", {
  anim_type = "offensive",
  prompt = "#chaos__tanbei",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(tanbei.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choices = { "chaos__tanbei2:"..player.id }
    if not target:isKongcheng() then
      table.insert(choices, 1, "chaos__tanbei1:"..player.id)
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = tanbei.name,
    })
    if choice:startsWith("chaos__tanbei1") then
      room:addTableMark(player, "chaos__tanbei1-turn", target.id)
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "h",
        skill_name = tanbei.name,
      })
      room:obtainCard(player, card, false, fk.ReasonPrey, player, tanbei.name)
    else
      room:addTableMark(player, "chaos__tanbei2-turn", target.id)
      room:setPlayerMark(target, "@@chaos__tanbei-turn", 1)
    end
  end,
})

tanbei:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and
      table.find(data.tos, function (p)
        return table.contains(player:getTableMark("chaos__tanbei1-turn"), p.id)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

tanbei:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return from and table.contains(from:getTableMark("chaos__tanbei1-turn"), to.id)
  end,
})

tanbei:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("chaos__tanbei2-turn"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and to and table.contains(player:getTableMark("chaos__tanbei2-turn"), to.id)
  end,
})

return tanbei
