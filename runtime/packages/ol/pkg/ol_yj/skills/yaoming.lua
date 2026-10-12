local yaoming = fk.CreateSkill {
  name = "ol__yaoming",
}

Fk:loadTranslationTable{
  ["ol__yaoming"] = "邀名",
  [":ol__yaoming"] = "每回合限一次，当你造成或受到伤害后，你可以选择一项：1.弃置手牌数大于你的一名角色一张手牌；2.令手牌数小于你的一名角色摸一张牌。",

  ["#ol__yaoming-choose"] = "邀名：你可选择一名手牌数与你不同的角色，大于你则弃置其一张牌，小于你则其摸一张牌",
  ["#ol__yaoming-discard"] = "邀名：请选择 %dest 的一张手牌弃置",
  ["ol__yaoming_discard"] = "弃牌",
  ["ol__yaoming_draw"] = "摸牌",

  ["$ol__yaoming1"] = "民食足，则国安。",
  ["$ol__yaoming2"] = "惜得手中米，安得众人心。",
}

local yaomingSpec = {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(yaoming.name) and
      player:usedSkillTimes(yaoming.name) == 0 and
      table.find(player.room.alive_players, function(p) return p:getHandcardNum() ~= player:getHandcardNum() end)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function(p)
      return p:getHandcardNum() ~= player:getHandcardNum()
    end)
    if #targets == 0 then
      return false
    end

    local tos = player.room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = yaoming.name,
        prompt = "#ol__yaoming-choose",
        target_tip_name = "#ol__yaoming-tip",
      }
    )

    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yaoming.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if to:getHandcardNum() > player:getHandcardNum() then
      local id = room:askToChooseCard(
        player,
        {
          target = to,
          flag = "h",
          skill_name = skillName,
          prompt = "#ol__yaoming-discard::" .. to.id,
        }
      )

      room:throwCard(id, skillName, to, player)
    elseif to:getHandcardNum() < player:getHandcardNum() then
      to:drawCards(1, skillName)
    end
  end,
}

yaoming:addEffect(fk.Damage, yaomingSpec)

yaoming:addEffect(fk.Damaged, yaomingSpec)

Fk:addTargetTip({
  name = "#ol__yaoming-tip",
  target_tip = function(self, player, to_select)
    if to_select:getHandcardNum() > player:getHandcardNum() then
      return "ol__yaoming_discard"
    elseif to_select:getHandcardNum() < player:getHandcardNum() then
      return "ol__yaoming_draw"
    end
  end,
})

return yaoming
