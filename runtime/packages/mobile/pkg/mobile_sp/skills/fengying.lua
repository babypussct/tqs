
local fengying = fk.CreateSkill {
  name = "mobile__fengying",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["mobile__fengying"] = "奉迎",
  [":mobile__fengying"] = "限定技，出牌阶段，你可以选择一名角色并令其攻击范围内的所有其他角色须将一张手牌当做【无中生有】对其使用。"..
  "若该角色体力上限为全场最大，此回合结束时你获得一个额外的回合。",

  ["#mobile__fengying"] = "奉迎：选择一名角色，令其攻击范围内所有角色将一张手牌当【无中生有】对其使用！",
  ["#mobile__fengying-ask"] = "奉迎：请将一张手牌当【无中生有】对 %dest 使用",

  ["$mobile__fengying1"] = "如今之势，自是奉顺者昌，奉逆者亡。",
  ["$mobile__fengying2"] = "夫天道佐义，民望助顺，得者自成霸业。",
  ["$mobile__fengying3"] = "公既奉迎天子，则天下莫敌矣！",
  ["$mobile__fengying4"] = "为君为公，臣等至死不渝！",
}

fengying:addEffect("active", {
  anim_type = "support",
  prompt = "#mobile__fengying",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(fengying.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return target:inMyAttackRange(p)
    end)
    for _, p in ipairs(targets) do
      local cards = table.filter(p:getCardIds("h"), function (id)
        local card = Fk:cloneCard("ex_nihilo")
        card:addSubcard(id)
        card.skillName = fengying.name
        return not p:isProhibited(target, card)
      end)
      if #cards > 0 then
        local card = room:askToCards(p, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = fengying.name,
          prompt = "#mobile__fengying-ask::"..target.id,
          cancelable = false,
        })
        room:useVirtualCard("ex_nihilo", card, p, target, fengying.name)
        if target.dead then break end
      end
    end
    if not player.dead and
      table.every(room.alive_players, function (p)
        return p.maxHp <= target.maxHp
      end) then
      player:gainAnExtraTurn(true, fengying.name)
    end
  end,
})

return fengying
