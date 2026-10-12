local qiangxi = fk.CreateSkill{
  name = "m_ex__qiangxi",
}

Fk:loadTranslationTable{
  ["m_ex__qiangxi"] = "强袭",
  [":m_ex__qiangxi"] = "出牌阶段对每名角色限一次，你可以失去1点体力或弃置一张武器牌，对攻击范围内一名其他角色造成1点伤害。",

  ["#m_ex__qiangxi"] = "强袭：弃置一张武器牌，或点“确定”失去1点体力，对攻击范围内一名本阶段未选择过的角色造成1点伤害",

  ["$m_ex__qiangxi1"] = "铁戟双提八十斤，威风凛凛震乾坤！",
  ["$m_ex__qiangxi2"] = "勇字当头，义字当先！",
}

qiangxi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#m_ex__qiangxi",
  max_card_num = 1,
  target_num = 1,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and
      not table.contains(player:getTableMark("m_ex__qiangxi-phase"), to_select.id) and
      player:inMyAttackRange(to_select, nil, selected_cards)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "m_ex__qiangxi-phase", target.id)
    if #effect.cards > 0 then
      room:throwCard(effect.cards, qiangxi.name, player)
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
