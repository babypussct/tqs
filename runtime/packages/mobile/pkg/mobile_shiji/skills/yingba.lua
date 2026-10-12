local yingba = fk.CreateSkill {
  name = "yingba",
}

Fk:loadTranslationTable{
  ["yingba"] = "英霸",
  [":yingba"] = "出牌阶段限一次，你可以令一名体力上限大于1的其他角色减1点体力上限，并令其获得一枚“平定”标记，然后你减1点体力上限；"..
  "你对拥有“平定”标记的角色使用牌无距离限制。",

  ["#yingba"] = "英霸：与一名角色各减1点体力上限，令其获得1枚“平定”标记",
  ["@yingba_pingding"] = "平定",

  ["$yingba1"] = "从我者可免，拒我者难容！",
  ["$yingba2"] = "卧榻之侧，岂容他人鼾睡！",
}

yingba:addEffect("active", {
  anim_type = "offensive",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yingba.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return to_select ~= player and to_select.maxHp > 1
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:changeMaxHp(target, -1)
    if not target.dead then
      room:addPlayerMark(target, "@yingba_pingding")
    end
    if not player.dead then
      room:changeMaxHp(player, -1)
    end
  end,
})

yingba:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(yingba.name) and card and to and to:getMark("@yingba_pingding") > 0
  end,
})

return yingba
