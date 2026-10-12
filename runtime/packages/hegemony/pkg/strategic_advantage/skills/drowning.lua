local drowningSkill = fk.CreateSkill{
  name = "sa__drowning_skill",
}
drowningSkill:addEffect("cardskill", {
  prompt = "#sa__drowning_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card, distance_limited)
    return to_select ~= player and #to_select:getCardIds("e") > 0
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    local all_choices = {"sa__drowning_throw", "sa__drowning_damage:" .. from.id}
    local choices = table.clone(all_choices)
    --if not table.find(to:getCardIds("e"), function(id) return not to:prohibitDiscard(Fk:getCardById(id)) end) then
    if #to:getCardIds("e") == 0 then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(to, {choices = choices, all_choices = all_choices, skill_name = "sa__drowning", cancelable = false})
    if choice == "sa__drowning_throw" then
      to:throwAllCards("e")
    else
      room:damage({
        from = from,
        to = to,
        card = effect.card,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = "sa__drowning",
      })
    end
  end
})

drowningSkill:addTest(function(room, me)
  local comp2 = room.players[2]
  local card = Fk:cloneCard("sa__drowning")
  FkTest.runInRoom(function()
    room:useCard {
      from = me,
      tos = { me },
      card = room:printCard("halberd"),
    }
  end)
  lu.assertIsTrue(table.every(room.alive_players, function (p)
    return not me:canUseTo(card, p) -- 目标：有装备牌的其他角色
  end))
  FkTest.runInRoom(function()
    room:useCard {
      from = comp2,
      tos = { comp2 },
      card = room:printCard("eight_diagram"),
    }
    room:useCard {
      from = comp2,
      tos = { comp2 },
      card = room:printCard("axe"),
    }
  end)
  lu.assertIsTrue(me:canUseTo(card, comp2))

  FkTest.setNextReplies(comp2, { "sa__drowning_damage:".. me.id, "sa__drowning_throw" })
  FkTest.runInRoom(function()
    room:useCard {
      from = me,
      card = card,
      tos = { comp2 },
    }
  end)
  lu.assertEquals(comp2.hp, 3)
  lu.assertEquals(#comp2:getCardIds("e"), 2)
  FkTest.runInRoom(function()
    room:useCard {
      from = me,
      card = card,
      tos = { comp2 },
    }
  end)
  lu.assertEquals(comp2.hp, 3)
  lu.assertEquals(#comp2:getCardIds("e"), 0)
end)

Fk:loadTranslationTable{
  ["sa__drowning"] = "水淹七军",
  [":sa__drowning"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名装备区里有牌的其他角色<br/><b>效果</b>：目标角色选择：1.弃置装备区里的所有牌；2.受到你造成的1点雷电伤害。",
  ["sa__drowning_skill"] = "水淹七军",
  ["sa__drowning_throw"] = "弃置装备区里的所有牌",
  ["sa__drowning_damage"] = "受到%src造成的1点雷电伤害",
  ["#sa__drowning_skill"] = "选择一名装备区里有牌的其他角色，其选择：<br/>1.弃置装备区里的所有牌；2.受到你造成的1点雷电伤害",
}

return drowningSkill
