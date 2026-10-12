local duansuo = fk.CreateSkill {
  name = "duansuo",
}

Fk:loadTranslationTable{
  ["duansuo"] = "断索",
  [":duansuo"] = "出牌阶段限一次，你可以重置至少一名角色，然后对这些角色各造成1点火焰伤害。",
  ["#duansuo"] = "断索：重置至少一名角色，对这些角色各造成1点火焰伤害",

  ["$duansuo1"] = "吾心如炬，无碍寒江铁索。",
  ["$duansuo2"] = "熔金断索，克敌建功！",
}

duansuo:addEffect("active", {
  anim_type = "offensive",
  prompt = "#duansuo",
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(duansuo.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return to_select.chained
  end,
  on_use = function(self, room, effect)
    local tos = table.simpleClone(effect.tos)
    room:sortByAction(tos)

    for _, p in ipairs(tos) do
      p:setChainState(false)
    end
    for _, p in ipairs(tos) do
      if p:isAlive() then
        room:damage({
          from = effect.from,
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = duansuo.name,
        })
      end
    end
  end,
})

return duansuo
