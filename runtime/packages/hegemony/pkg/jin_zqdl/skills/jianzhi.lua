local jianzhi = fk.CreateSkill{
  name = "heg__jianzhi",
}

Fk:loadTranslationTable{
  ["heg__jianzhi"] = "奸志",
  [":heg__jianzhi"] = "当你造成致命伤害时，你可以弃置所有手牌（至少一张），然后本回合下次击杀奖励改为三倍。",

  ["#heg__jianzhi-invoke"] = "奸志：是否弃置所有手牌，令本回合下次击杀奖励改为三倍？",

  ["$heg__jianzhi1"] = "怀志拥权，谁敢不服？",
  ["$heg__jianzhi2"] = "天下凶凶，由我一人。",
}

jianzhi:addEffect(fk.DamageCaused, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianzhi.name) and
      data.damage >= (data.to.hp + data.to.shield) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if not table.find(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id)
      end) then
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = jianzhi.name,
        pattern = "false",
        prompt = "#heg__jianzhi-invoke",
        cancelable = true,
      })
      return
    end
    return room:askToSkillInvoke(player, {
      skill_name = jianzhi.name,
      prompt = "#heg__jianzhi-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("h", jianzhi.name)
    local n = room:getBanner(jianzhi.name) or 0
    room:setBanner(jianzhi.name, n + 1)
    n = room:getBanner("additional_reward") or 0
    room:setBanner("additional_reward", n + 2)
  end,
})

local spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room:getBanner(jianzhi.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = room:getBanner(jianzhi.name) or 0
    room:setBanner(jianzhi.name, 0)
    local n2 = room:getBanner("additional_reward") or 0
    n2 = math.min(0, n2 - 2 * n)
    room:setBanner("additional_reward", n)
  end,
}
jianzhi:addEffect(fk.Deathed, spec)
jianzhi:addEffect(fk.TurnEnd, spec)

jianzhi:addTest(function(room, me)
  local comp2 = room.players[2]
end)

return jianzhi

