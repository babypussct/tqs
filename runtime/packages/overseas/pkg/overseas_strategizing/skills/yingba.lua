local yingba = fk.CreateSkill {
  name = "os__yingba",
}

Fk:loadTranslationTable {
  ["os__yingba"] = "英霸",
  [":os__yingba"] = "出牌阶段限一次，你可以令一名体力上限大于1的其他角色，令其失去1点体力并减1点体力上限，并令其获得一枚“平定”标记，然后你减1点体力上限。" ..
      "你对拥有“平定”标记的角色使用牌无距离限制。有“平定”标记的角色每回合前X张牌不能指定你为目标（X为其拥有的“平定”标记数）。",

  ["#os__yingba"] = "英霸：令一名角色失去1点体力、减1点体力上限、获得1枚“平定”标记",
  ["@os__yingba_pingding"] = "平定",
  ["@os__yingba_pingding_use-turn"] = "平定禁止",

  ["$os__yingba1"] = "你现在只有两条路，卸甲归降，或者引颈就戮！",
  ["$os__yingba2"] = "今倾吴地之兵，伐尔等不臣之贼。",
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
    room:loseHp(target, 1, yingba.name, player)
    if not target.dead then
      room:changeMaxHp(target, -1)
      room:addPlayerMark(target, "@os__yingba_pingding")
    end
    if not player.dead then
      room:changeMaxHp(player, -1)
    end
  end,
})

yingba:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(yingba.name) and card and to and to:getMark("@os__yingba_pingding") > 0
  end,
})

yingba:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@os__yingba_pingding") > 0 and
    table.find(player.room.alive_players, function(t) return t:hasSkill(yingba.name, true) end)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@os__yingba_pingding_use-turn", player:getMark("@os__yingba_pingding"))
  end,
})

yingba:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return player == target and player:getMark("@os__yingba_pingding_use-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:removePlayerMark(player, "@os__yingba_pingding_use-turn")
  end,
})

yingba:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and from and from:getMark("@os__yingba_pingding_use-turn") > 0 and to:hasSkill(yingba.name)
  end,
})

yingba:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if table.every(room.alive_players, function(t) return not t:hasSkill(yingba.name, true) end) then
    table.forEach(room.alive_players, function(t)
      if t:getMark("@os__yingba_pingding") > 0 then
        room:setPlayerMark(t, "@os__yingba_pingding", 0)
      end
    end)
  end
end)

return yingba
