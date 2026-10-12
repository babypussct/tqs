
local qiangxi = fk.CreateSkill{
  name = "hs__qiangxi",
}
qiangxi:addEffect("active", {
  anim_type = "offensive",
  max_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if #effect.cards > 0 then
      room:throwCard(effect.cards, self.name, player)
    else
      room:loseHp(player, 1, self.name)
    end
    if target:isAlive() then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
})

Fk:loadTranslationTable{
  ["hs__qiangxi"] = "强袭",
  [":hs__qiangxi"] = "出牌阶段限一次，你可以失去1点体力或弃置一张武器牌，并选择一名其他角色，对其造成1点伤害。",

  ["$hs__qiangxi1"] = "吃我一戟！",
  ["$hs__qiangxi2"] = "看我三步之内取你小命！",
}

return qiangxi
