local xiongxi = fk.CreateSkill {
  name = "os__xiongxi",
}

Fk:loadTranslationTable{
  ["os__xiongxi"] = "凶袭",
  [":os__xiongxi"] = "出牌阶段限一次，你可弃置X张牌对一名其他角色造成1点伤害。（X=5-<a href='os__baonue_href'>暴虐值</a>，且可为0）",

  ["$os__xiongxi1"] = "凶兵厉袭，片瓦不存！",
  ["$os__xiongxi2"] = "尽起西凉狼兵，袭掠中原之地！",
}

xiongxi.os__baonue = true

xiongxi:addEffect("active", {
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(xiongxi.name, Player.HistoryPhase) < 1
  end,
  card_num = function(self, player)
    return 5 - player:getMark("@os__baonue")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 5 - player:getMark("@os__baonue") and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected_cards == 5 - player:getMark("@os__baonue") and to_select ~= player
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, xiongxi.name, player, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = xiongxi.name,
      }
    end
  end,
})

xiongxi:addAcquireEffect(function(self, player)
  player.room:addSkill("#os__baonue_mark")
end)

return xiongxi
