
local zhuiyi = fk.CreateSkill {
  name = "ol_ex__zhuiyi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ol_ex__zhuiyi"] = "追忆",
  [":ol_ex__zhuiyi"] = "限定技，结束阶段，你可以令一名其他角色摸三张牌并回复1点体力。然后你死亡时，可以再次对其发动本技能。",

  ["#ol_ex__zhuiyi-choose"] = "追忆：你可以令一名角色摸三张牌并回复1点体力",
  ["#ol_ex__zhuiyi-invoke"] = "追忆：是否令 %dest 摸三张牌并回复1点体力？",

  ["$ol_ex__zhuiyi1"] = "夜阑听呓语，凉风慰相思。",
  ["$ol_ex__zhuiyi2"] = "朱颜随流水，一忆一段愁。",
}

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(player, zhuiyi.name, to)
    to:drawCards(3, zhuiyi.name)
    if to:isWounded() and not to.dead then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = zhuiyi.name,
      }
    end
  end,
}

zhuiyi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuiyi.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 0 and
      player:usedSkillTimes(zhuiyi.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      skill_name = zhuiyi.name,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      prompt = "#ol_ex__zhuiyi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = spec.on_use,
})

zhuiyi:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuiyi.name, false, true) and
      player:getMark(zhuiyi.name) ~= 0 and not player:getMark(zhuiyi.name).dead
  end,
  on_cost = function(self, event, target, player, data)
    local to = player:getMark(zhuiyi.name)
    if player.room:askToSkillInvoke(player, {
      skill_name = zhuiyi.name,
      prompt = "#ol_ex__zhuiyi-invoke::"..to.id,
    }) then
      event:setCostData(self, { tos = { to } })
      return true
    end
  end,
  on_use = spec.on_use,
})

local AI = Fk.Ltk.AI
zhuiyi:addAI(AI.reuse("zhuiyi", AI.ChoosePlayersStrategy))

zhuiyi:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local target = ai.room:getPlayerById(tonumber(string.split(ai.data[2], ":")[3]))
    return ai:getBenefitOfEvents(function(logic)
      logic:drawCards(target, 3)
      logic:recover{
        who = target,
        num = 1,
        recoverBy = ai.player,
      }
    end) >= 0
  end,
})

return zhuiyi
