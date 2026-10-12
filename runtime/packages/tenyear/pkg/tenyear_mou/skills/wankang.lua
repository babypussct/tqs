local wankang = fk.CreateSkill {
  name = "wankang",
}

Fk:loadTranslationTable {
  ["wankang"] = "顽抗",
  [":wankang"] = "当你处于濒死状态时，你可以回复1点体力，获得一枚“抗”并摸两张牌。若如此做，当前回合结束时，" ..
      "你对本回合对你造成过伤害的角色使用至多“抗”数量张【杀】，每使用一张便移去一枚“抗”，若以此法击杀一名对你造成过伤害的角色，移去所有“抗”；然后若仍有“抗”，你阵亡。",

  ["@wankang-turn"] = "抗",
  ["#wankang-use"] = "顽抗：请使用【杀】以移去一枚“抗”，若剩余“抗”则死亡！",

  ["$wankang1"] = "本将贪杯贪财，何曾贪生怕死！",
  ["$wankang2"] = "弟兄们！给本将军顶住！",
}

wankang:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.hp < 1 and player:hasSkill(wankang.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover {
      who = player,
      num = 1,
      recoverBy = player,
      skillName = wankang.name
    }
    if player.dead then return end
    room:addPlayerMark(player, "@wankang-turn", 1)
    player:drawCards(2, wankang.name)
  end,
})

wankang:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@wankang-turn") > 0 and player:hasSkill(wankang.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    while not player.dead and player:getMark("@wankang-turn") > 0 do
      local targets = {}
      room.logic:getActualDamageEvents(1, function(e)
        if e.data.to == player and e.data.from and e.data.from ~= player and not e.data.from.dead then
          table.insertIfNeed(targets, e.data.from.id)
        end
      end)
      if #targets == 0 then
        break
      end
      local use = room:askToUseCard(player, {
        skill_name = wankang.name,
        pattern = "slash",
        prompt = "#wankang-use",
        extra_data = {
          exclusive_targets = targets,
          bypass_times = true,
        }
      })
      if use then
        room:removePlayerMark(player, "@wankang-turn", 1)
        use.extraUse = true
        use.extra_data=use.extra_data or {}
        use.extra_data.wankang=true
        room:useCard(use)
      else
        break
      end
    end
    if player:getMark("@wankang-turn") > 0 then
      room:killPlayer({ who = player })
    end
  end,
})

wankang:addEffect(fk.Death, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    local usecard=player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return player:getMark("@wankang-turn") > 0 and player:hasSkill(wankang.name) 
      and usecard and usecard.data.extra_data.wankang==true
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@wankang-turn", 0)
  end
})

wankang:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@wankang-turn", 0)
end)

return wankang
