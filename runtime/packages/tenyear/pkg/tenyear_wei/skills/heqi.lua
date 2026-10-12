
local heqi = fk.CreateSkill {
  name = "heqim",
}

Fk:loadTranslationTable{
  ["heqim"] = "合骑",
  [":heqim"] = "游戏开始时，你获得3个“骑”。你不以此法使用【杀】结算后，可以视为对拥有“骑”的其他角色使用X张【杀】"..
  "（X为该角色“骑”的数量，此【杀】造成的伤害无伤害来源），你对拥有“骑”的角色使用牌无距离限制。",

  ["@heqim"] = "骑",
  ["#heqim-invoke"] = "合骑：你可以视为对拥有“骑”的其他角色使用【杀】（无来源伤害）",

  ["$heqim1"] = "羌笛不吹杨柳怨，只听西凉铁蹄声！",
  ["$heqim2"] = "我有铁骑十万，可裂甲、摧城、吞天地！",
}

heqi:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@heqim", 0)
end)

heqi:addEffect(fk.GameStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(heqi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@heqim", 3)
  end,
})

heqi:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(heqi.name) and
      data.card.trueName == "slash" and
      not table.contains(data.card.skillNames, heqi.name) and
      table.find(player.room.alive_players, function(p)
        return p ~= player and p:getMark("@heqim") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = heqi.name,
      prompt = "#heqim-invoke",
    }) then
      event:setCostData(self, {
        tos = table.filter(room:getAlivePlayers(), function(p)
          return p ~= player and p:getMark("@heqim") > 0
        end)
      })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    --神秘逆序结算
    local tos = table.reverse(event:getCostData(self).tos)
    for _, p in ipairs(tos) do
      if player.dead then break end
      for _ = 1, p:getMark("@heqim"), 1 do
        if room:useVirtualCard("slash", {}, player, p, heqi.name, true) == nil then break end
      end
    end
  end,
})

heqi:addEffect(fk.PreDamage, {
  is_delay_effect = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    if not data.card or player ~= data.to then
      return false
    end

    local use = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not use then
      return false
    end

    return table.contains(use.data.card.skillNames, heqi.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.from = nil
  end,
})

heqi:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(heqi.name) and to and to:getMark("@heqim") > 0
  end,
})

heqi:addLoseEffect(function(self, player)
  local room = player.room
  if table.every(room.alive_players, function(p)
    return not p:hasSkill(heqi.name, true)
  end) then
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@heqim", 0)
    end
  end
end)

heqi:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    return ai:getBenefitOfEvents(function(logic)
      for _, p in ipairs(ai.room:getAlivePlayers()) do
        if p ~= ai.player and p:getMark("@heqim") > 0 then
          for _ = 1, p:getMark("@heqim") do
            logic:useCard{
              from = ai.player,
              tos = { p },
              card = Fk:cloneCard("slash"),
            }
          end
        end
      end
    end) >= 0
  end,
})

return heqi
