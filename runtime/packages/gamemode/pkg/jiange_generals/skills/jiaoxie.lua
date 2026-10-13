local jiaoxie = fk.CreateSkill {
  name = "jiange__jiaoxie",
}

Fk:loadTranslationTable{
  ["jiange__jiaoxie"] = "缴械",
  [":jiange__jiaoxie"] = "出牌阶段限一次，你可以令至多两名敌方攻城器械各交给你一张牌。",

  ["#jiange__jiaoxie"] = "缴械：令至多两名敌方攻城器械各交给你一张牌",
  ["#jiange__jiaoxie-give"] = "缴械：你须交给 %src 一张牌",
}

jiaoxie:addEffect("active", {
  anim_type = "control",
  prompt = "#jiange__jiaoxie",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(jiaoxie.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2 and to_select:isEnemy(player) and
      Fk.generals[to_select.general].jiange_machine and not to_select:isNude()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    for _, target in ipairs(effect.tos) do
      if player.dead then return end
      if not target.dead and not target:isNude() then
        local card = room:askToCards(target, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = jiaoxie.name,
          cancelable = false,
          prompt = "#jiange__jiaoxie-give:"..player.id,
        })
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, jiaoxie.name, nil, false, target)
      end
    end
  end,
})

return jiaoxie
