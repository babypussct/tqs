
local shuangren = fk.CreateSkill{
  name = "shuangren",
}

Fk:loadTranslationTable{
  ["shuangren"] = "双刃",
  [":shuangren"] = "出牌阶段开始时，你可以与一名角色拼点。若你：赢，你视为对任意名与其势力相同的角色使用【杀】；"..
  "没赢，其他角色于此回合内不是你使用牌的合法目标。",

  ["#shuangren-ask"] = "双刃：你可与一名角色拼点",
  ["#shuangren_slash-ask"] = "双刃：你视为对任意名与 %src 势力相同的角色使用【杀】",
  ["@@shuangren-turn"] = "双刃 没赢",

  ["$shuangren1"] = "仲国大将纪灵在此！",
  ["$shuangren2"] = "吃我一记三尖两刃刀！",
}

local H = require "packages.hegemony.util"

shuangren:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shuangren.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:canPindian(p)
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#shuangren-ask",
      skill_name = shuangren.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target = event:getCostData(self).tos[1]
    local pindian = player:pindian({target}, shuangren.name)
    if pindian.results[target].winner == player then
      if player.dead then return end
      local slash = Fk:cloneCard("slash", nil, nil, shuangren.name)
      if player:prohibitUse(slash) then return false end
      local availableTargets = table.filter(room:getOtherPlayers(player, false), function(p)
        return H.compareKingdomWith(p, target) and player:canUseTo(slash, p)
      end)
      if #availableTargets == 0 then return false end
      local victims = room:askToChoosePlayers(player, {
        targets = availableTargets,
        min_num = 1,
        max_num = #availableTargets,
        prompt = "#shuangren_slash-ask:" .. target.id,
        skill_name = shuangren.name,
        cancelable = false,
      })
      if #victims > 0 then
        local tos = victims
        room:useVirtualCard("slash", nil, player, tos, shuangren.name, true)
      end
    else
      room:setPlayerMark(player, "@@shuangren-turn", 1)
    end
  end,
})

shuangren:addEffect("prohibit", {
  name = "#shuangren_prohibit",
  is_prohibited = function(self, from, to, card)
    if from and from:hasSkill(shuangren.name) then
      return from:getMark("@@shuangren-turn") > 0 and from ~= to
    end
  end,
})

return shuangren
