local qiangxi = fk.CreateSkill{
  name = "ol__qiangxi",
}

Fk:loadTranslationTable{
  ["ol__qiangxi"] = "强袭",
  [":ol__qiangxi"] = "出牌阶段限两次，你可以失去1点体力或弃置一张武器牌，对一名本回合内未以此法指定过的其他角色造成1点伤害。",

  ["#ol__qiangxi"] = "强袭：弃一张武器牌，或不选牌失去1点体力，对目标角色造成1点伤害",

  ["$ol__qiangxi1"] = "休想靠近主公一步！",
  ["$ol__qiangxi2"] = "人戟合一，所向披靡！",
}

qiangxi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol__qiangxi",
  max_phase_use_time = 2,
  max_card_num = 1,
  target_num = 1,
  times = function (self, player)
    return 2 - player:usedSkillTimes(qiangxi.name, Player.HistoryPhase)
  end,
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and
      not table.contains(player:getTableMark("ol__qiangxi_targets-turn"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMarkIfNeed(player, "ol__qiangxi_targets-turn", target.id)
    if #effect.cards > 0 then
      room:throwCard(effect.cards, qiangxi.name, player, player)
    else
      room:loseHp(player, 1, qiangxi.name)
    end
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = qiangxi.name,
      }
    end
  end,
})

return qiangxi