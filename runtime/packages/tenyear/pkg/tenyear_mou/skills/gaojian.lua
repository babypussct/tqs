local gaojian = fk.CreateSkill {
  name = "gaojian",
}

Fk:loadTranslationTable{
  ["gaojian"] = "告谏",
  [":gaojian"] = "出牌阶段限一次，你可令一名角色亮出牌堆顶一张牌，若为伤害牌其受到X点火焰伤害，若不为伤害牌，其选择一项执行："..
    "1.获得此牌并再次亮牌（次数不能超过存活人数）；2.直至其回合结束其攻击范围-X。（X为因此亮出的牌数）",

  ["#gaojian"] = "告谏：选择一名角色，其亮出牌堆顶牌",
  ["gaojian_gain"] = "获得亮出的牌",
  ["gaojian_debuff"] = "减少攻击范围",
  ["@gaojian"] = "告谏",

  ["$gaojian1"] = "江东不乏能人，主公不可小觑。",
  ["$gaojian2"] = "狮子搏兔，亦需尽其全力。",
}

gaojian:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#gaojian",
  card_num = 0,
  target_num = 1,
  max_phase_use_time = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local x = 0
    local ids = room:getNCards(1)
    while x < #room.alive_players do
      x = x + 1
      room:turnOverCardsFromDrawPile(target, ids, gaojian.name)
      if Fk:getCardById(ids[1]).is_damage_card then
        room:damage {
          from = player,
          to = target,
          damage = x,
          damageType = fk.FireDamage
        }
        break
      else
        local choice = room:askToChoice(target, {
          choices = { "gaojian_gain", "gaojian_debuff" },
          skill_name = gaojian.name,
        })
        if choice == "gaojian_gain" then
          room:obtainCard(target, ids, true, fk.ReasonJustMove, target, gaojian.name)
          ids = room:getNCards(1)
        else
          room:setPlayerMark(target, "@gaojian", target:getMark("@gaojian") - x)
          break
        end
      end
    end
    room:cleanProcessingArea(ids, gaojian.name)
  end,
})

gaojian:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@gaojian") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@gaojian", 0)
  end,
})

gaojian:addEffect("atkrange", {
  correct_func = function(self, from, to)
    return from:getMark("@gaojian")
  end,
})

return gaojian
