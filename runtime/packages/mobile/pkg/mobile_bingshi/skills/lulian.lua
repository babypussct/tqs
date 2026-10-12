
local lulian = fk.CreateSkill{
  name = "lulian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lulian"] = "戮连",
  [":lulian"] = "锁定技，当你使用手牌结算结束后，若你没有此类别的手牌，且有目标角色：体力值小于等于你，此牌的所有目标横置；"..
  "装备区牌数小于等于你，你摸一张牌。乘势：你对一名体力值不为最小的角色造成1点火焰伤害。",

  ["#lulian-choose"] = "戮连：对一名体力值不为最小的角色造成1点火焰伤害",

  ["$lulian1"] = "本朝可无天子，可无我孙綝否？",
  ["$lulian2"] = "朝事在君，生杀在我！",
  ["$lulian3"] = "莫言泉下孤苦，自有汝族相陪！",
  ["$lulian4"] = "我心性善，不忍见离，自许汝举族团圆！",
}

lulian:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(lulian.name) and
      data:isUsingHandcard(player) and
      not table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).type == data.card.type
      end) and
      table.find(data.tos, function (p)
        return p.hp <= player.hp or #p:getCardIds("e") <= #player:getCardIds("e")
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local activedBranches = {}
    for _, p in ipairs(data.tos) do
      if p.hp <= player.hp then
        table.insert(activedBranches, "branch_one")
      end
      if #p:getCardIds("e") <= #player:getCardIds("e") then
        table.insert(activedBranches, "branch_two")
      end
    end

    if #activedBranches > 0 then
      local audioIndex = #activedBranches < 2 and { 1, 2 } or { 3, 4 }
      event:setCostData(self, { activedBranches = activedBranches, audio_index = table.random(audioIndex) })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local activedBranches = event:getCostData(self).activedBranches

    if table.contains(activedBranches, "branch_one") then
      for _, p in ipairs(room:getAlivePlayers()) do
        if table.contains(data.tos, p) and not p.chained then
          p:setChainState(true)
        end
      end
    end

    if not player:isAlive() then
      return false
    end

    if table.contains(activedBranches, "branch_two") then
      player:drawCards(1, lulian.name)
    end

    if player:isAlive() and #activedBranches > 1 then
      local targets = table.filter(room.alive_players, function (p)
        return table.find(room.alive_players, function (q)
            return p.hp > q.hp
          end) ~= nil
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#lulian-choose",
        skill_name = lulian.name,
        cancelable = false,
      })[1]
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = lulian.name,
      }
    end
  end,
})

return lulian
