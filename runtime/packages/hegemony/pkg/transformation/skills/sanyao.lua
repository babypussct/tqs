local sanyao = fk.CreateSkill{
  name = "ld__sanyao",
}
sanyao:addEffect("active", {
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(sanyao.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.hp > n then
          n = p.hp
        end
      end
      return to_select.hp == n
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, sanyao.name, player, player)
    if target:isAlive() then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = sanyao.name,
      }
    end
  end
})

Fk:loadTranslationTable{
  ["ld__sanyao"] = "散谣",
  [":ld__sanyao"] = "出牌阶段限一次，你可以弃置一张牌并选择一名体力值最大的角色，你对其造成1点伤害。",

  ["$ld__sanyao1"] = "三人成虎，事多有。",
  ["$ld__sanyao2"] = "散谣惑敌，不攻自破！",
}

return sanyao
