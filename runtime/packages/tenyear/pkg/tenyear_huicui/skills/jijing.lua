local jijing = fk.CreateSkill {
  name = "jijing",
}

Fk:loadTranslationTable{
  ["jijing"] = "吉境",
  [":jijing"] = "当你受到伤害后，你可以判定，然后你可以弃置任意张点数之和等于判定结果的牌，若如此做，你回复1点体力。",

  ["#jijing-discard"] = "吉境：你可以弃置任意张点数之和为%arg的牌，回复1点体力",

  ["$jijing1"] = "吉梦赐福，顺应天命。",
  ["$jijing2"] = "梦之指引，必为吉运。",
}

jijing:addAuxActiveSkill("#jijing_active", {
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if not player:prohibitDiscard(to_select) then
      local num = 0
      for _, id in ipairs(selected) do
        num = num + Fk:getCardById(id).number
      end
      return num + Fk:getCardById(to_select).number <= self.jijing_number
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    local num = 0
    for _, id in ipairs(selected_cards) do
      num = num + Fk:getCardById(id).number
    end
    return num == self.jijing_number
  end,
})

jijing:addEffect(fk.Damaged, {
  anim_type = "defensive",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = jijing.name,
    }
    room:judge(judge)
    if player.dead or player:isNude() or judge.card.number == 0 then return end
    local n = judge.card.number
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#jijing_active",
      prompt = "#jijing-discard:::" .. n,
      cancelable = true,
      extra_data = {
        jijing_number = n,
      }
    })
    if success and dat then
      room:throwCard(dat.cards, jijing.name, player, player)
      if not player.dead and player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = jijing.name,
        }
      end
    end
  end,
})

return jijing
