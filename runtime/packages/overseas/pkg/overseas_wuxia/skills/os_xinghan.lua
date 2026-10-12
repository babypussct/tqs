local osXinghan = fk.CreateSkill {
  name = "os__xinghan"
}

Fk:loadTranslationTable{
  ["os__xinghan"] = "兴汉",
  [":os__xinghan"] = "你的回合外或当你处于濒死状态时，你可如手牌般使用或打出“侠义”牌。准备阶段，" ..
  "若“侠义”牌的数量大于存活角色数，你可依次使用“侠义”牌，然后此回合结束时，你弃置所有手牌并失去X点体力（X为你的体力值-1且至少为1）。",

  ["#os__xinghan-ask"] = "兴汉：你可依次使用“侠义”牌，然后此回合结束时，你弃置所有手牌并失去X点体力（X为你的体力值-1且至少为1）",
  ["#os__xinghan-use"] = "兴汉：使用“侠义”牌 %arg",

  ["$os__xinghan1"] = "继先汉之荣，开万世泰平！",
  ["$os__xinghan2"] = "立此兴汉之志，终不可渝！",
}

-- TriggerSkill Effect
osXinghan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osXinghan.name) and player.phase == Player.Start and #player:getPile("os__chivalry") > #player.room.alive_players
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = osXinghan.name,
      prompt = "#os__xinghan-ask"
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getPile("os__chivalry")
    for i = #cards, 1, -1 do
      local cid = cards[i]
      if player:getPileNameOfId(cid) == "os__chivalry" and room:getCardOwner(cid) == player then
        room:askToUseRealCard(
          player,
          {
            pattern = { cid },
            skill_name = osXinghan.name,
            prompt = "#os__xinghan-use:::" .. Fk:getCardById(cid):toLogString(),
            cancelable = true,
            extra_data = {
              expand_pile = { cid },
            },
          }
        )
      end
    end
  end,
})

-- Delay TriggerSkill Effect
osXinghan:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(osXinghan.name) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("h")
    if player:isAlive() then
      room:loseHp(player, math.max(1, player.hp - 1), osXinghan.name)
    end
  end,
})

-- FilterSkill Effect
osXinghan:addEffect("filter", {
  handly_cards = function(self, player)
    if player:hasSkill(osXinghan.name) and (Fk:currentRoom():getCurrent() ~= player or player.dying) then
      return player:getPile("os__chivalry")
    end
  end,
})

return osXinghan
