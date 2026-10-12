local anda = fk.CreateSkill {
  name = "anda",
}

Fk:loadTranslationTable {
  ["anda"] = "谙达",
  [":anda"] = "每轮限一次，当一名角色进入濒死状态时，你可以令伤害来源选择一项：1.交给其两张颜色不同的牌；2.该角色回复1点体力。",

  ["#anda-invoke"] = "谙达：你可以令 %src 交给 %dest 两张不同颜色的牌，否则 %dest 回复1点体力",
  ["#anda-give"] = "谙达：交给 %dest 两张不同颜色的牌，否则其回复1点体力",

  ["$anda1"] = "汝新造江南，其事未集，安可诛此地英士？",
  ["$anda2"] = "于先生亦助军作福，医护将士，不可杀之。",
}

anda:addAuxActiveSkill("#anda_active", {
  card_num = 2,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return table.every(selected, function(id)
      return Fk:getCardById(to_select):compareColorWith(Fk:getCardById(id), true)
    end)
  end,
})

anda:addEffect(fk.EnterDying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(anda.name) and player:usedSkillTimes(anda.name, Player.HistoryRound) == 0 and
      data.damage and data.damage.from and not data.damage.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = anda.name,
      prompt = "#anda-invoke:"..data.damage.from.id..":"..target.id,
    }) then
      event:setCostData(self, {tos = {data.damage.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.damage.from ~= target and #data.damage.from:getCardIds("he") > 1 then
      local success, dat = room:askToUseActiveSkill(data.damage.from, {
        skill_name = "#anda_active",
        prompt = "#anda-give::"..target.id,
        cancelable = true,
      })
      if success and dat then
        room:moveCardTo(dat.cards, Card.PlayerHand, target, fk.ReasonGive, anda.name, nil, false, data.damage.from)
        return
      end
    end
    if target.dead then return end
    room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = anda.name,
    }
  end,
})

return anda
