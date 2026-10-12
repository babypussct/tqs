local zhenting = fk.CreateSkill {
  name = "zhenting",
  dynamic_desc = function (self, player, lang)
    if player:getMark("mobile__jincui") > 0 then
      return "zhenting_inner"
    end
  end,
}

Fk:loadTranslationTable{
  ["zhenting"] = "镇庭",
  [":zhenting"] = "每回合限一次，当你或你攻击范围内的一名角色成为【杀】或延时锦囊牌的目标时，若你不是此牌的使用者，"..
  "你可以选择一项：1.弃置此牌使用者的一张手牌；2.摸一张牌。背水：你代替其成为此牌的目标。",

  [":zhenting_inner"] = "每回合限一次，当你或你攻击范围内的一名角色成为【杀】或延时锦囊牌的目标时，若你不是此牌的使用者，"..
  "你可以选择一项：1.弃置此牌使用者的一张手牌；2.摸一张牌。",

  ["#zhenting-invoke"] = "镇庭：%src 对 %dest 使用%arg，你可以选择一项",
  ["zhenting_discard"] = "弃置%dest一张手牌",
  ["zhenting_beishui"] = "背水：你代替其成为此牌目标",

  ["$zhenting1"] = "今政事在我，更要持重慎行！",
  ["$zhenting2"] = "国可因外敌而亡，不可因内政而损！",
}

zhenting:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhenting.name) and player:usedSkillTimes(zhenting.name, Player.HistoryTurn) == 0 and
      data.from ~= player and (data.card.trueName == "slash" or data.card.sub_type == Card.SubtypeDelayedTrick) and
      (player:inMyAttackRange(target) or target == player)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = { "draw1" }
    if not data.from.dead and not data.from:isKongcheng() then
      table.insert(choices, 1, "zhenting_discard::"..data.from.id)
      if player:getMark("mobile__jincui") == 0 then
        table.insert(choices, "zhenting_beishui")
      end
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhenting.name,
      prompt = "#zhenting-invoke:"..data.from.id..":"..target.id..":"..data.card:toLogString(),
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice ~= "draw1" and not data.from:isKongcheng() then
      local id = room:askToChooseCard(player, {
        target = data.from,
        flag = "h",
        skill_name = zhenting.name,
      })
      room:throwCard(id, zhenting.name, data.from, player)
      if player.dead then return end
    end
    if not choice:startsWith("zhenting_discard") then
      player:drawCards(1, zhenting.name)
      if player.dead then return end
    end
    if choice == "zhenting_beishui" and not data.from:isProhibited(player, data.card) and not data.cancelled then
      data:cancelCurrentTarget()
      data:addTarget(player)
    end
  end,
})

return zhenting
