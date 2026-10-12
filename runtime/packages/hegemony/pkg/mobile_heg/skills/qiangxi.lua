
local qiangxi = fk.CreateSkill({
  name = "m_heg__qiangxi",
})

Fk:loadTranslationTable{
  ["m_heg__qiangxi"] = "强袭",
  [":m_heg__qiangxi"] = "出牌阶段限一次，你可以对自己造成1点伤害或弃置一张武器牌，对你攻击范围内的一名其他角色造成1点伤害。",

  ["#m_heg__qiangxi"] = "强袭：弃一张武器牌，或不选牌对自己造成1点伤害，对目标角色造成1点伤害",

  ["$m_heg__qiangxi1"] = "吃我一戟！",
  ["$m_heg__qiangxi2"] = "看我三步之内取你小命！",
}

qiangxi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#m_heg__qiangxi",
  max_phase_use_time = 1,
  max_card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and player:inMyAttackRange(to_select, nil, selected_cards)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if #effect.cards > 0 then
      room:throwCard(effect.cards, qiangxi.name, player, player)
    else
      room:damage{
        from = player,
        to = player,
        damage = 1,
        skillName = qiangxi.name,
      }
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
