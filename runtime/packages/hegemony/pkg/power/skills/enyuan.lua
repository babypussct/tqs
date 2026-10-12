local enyuan = fk.CreateSkill{
  name = "ld__enyuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ld__enyuan"] = "恩怨",
  [":ld__enyuan"] = "锁定技，当你成为【桃】的目标后，若使用者不为你，其摸一张牌；当你受到伤害后，伤害来源需交给你一张手牌，否则失去1点体力。",

  ["#ld__enyuan-give"] = "恩怨：交给 %src 一张手牌，否则失去1点体力",

  ["$ld__enyuan1"] = "伤了我，休想全身而退！",
  ["$ld__enyuan2"] = "报之以李，还之以桃。",
}

enyuan:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  audio_index = { 2 },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(enyuan.name) and
      data.card.trueName == "peach" and data.from ~= player and not data.from.dead
  end,
  on_use = function(self, event, target, player, data)
    data.from:drawCards(1, enyuan.name)
  end,
})

enyuan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  audio_index = { 1 },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(enyuan.name) and
      data.from and not data.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from == player then
      room:loseHp(player, 1, enyuan.name)
    else
      local card = room:askToCards(data.from, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = enyuan.name,
        prompt = "#ld__enyuan-give:"..player.id,
        cancelable = true,
      })
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, enyuan.name, nil, false, player)
      else
        room:loseHp(data.from, 1, enyuan.name)
      end
    end
  end,
})

return enyuan
