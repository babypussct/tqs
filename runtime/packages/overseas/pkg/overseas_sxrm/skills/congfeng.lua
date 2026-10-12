local congfeng = fk.CreateSkill {
  name = "os__congfeng",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["os__congfeng"] = "从风",
  [":os__congfeng"] = "转换技，当你使用牌指定目标后，或当你成为牌的目标后，你可以：" ..
  "阳，弃置使用者两张牌；阴，与使用者各摸一张牌。" ..
  "<font color='gray'>初始为“阴”。</font>",

  ["#os__congfeng-draw"] = "从风：你可以与 %dest 各摸一张牌",
  ["#os__congfeng-discard"] = "从风：你可以弃置 %dest 两张牌",
}

local U = require "packages.utility.utility"

---@type TrigSkelSpec<AimFunc>
local spec = {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(congfeng.name) and
      (player:getSwitchSkillState(congfeng.name) == fk.SwitchYin or (data.from:isAlive() and #data.from:getCardIds("he") > 1))
  end,
  on_cost = function(self, event, target, player, data)
    local skillName = congfeng.name
    local room = player.room
    if player:getSwitchSkillState(skillName) == fk.SwitchYin then
      if room:askToSkillInvoke(player, { skill_name = skillName, prompt = "#os__congfeng-draw::" .. data.from.id }) then
        event:setCostData(self, { swithState = player:getSwitchSkillState(skillName) })
        return true
      end
    else
      if player == data.from then
        local ids = room:askToDiscard(
          player,
          {
            min_num = 2,
            max_num = 2,
            skill_name = skillName,
            include_equip = true,
            prompt = "#os__congfeng-discard::" .. data.from.id,
            skip = true,
          }
        )

        if #ids == 2 then
          event:setCostData(self, { cards = ids, swithState = player:getSwitchSkillState(skillName) })
          return true
        end
      else
        if
          room:askToSkillInvoke(
            player,
            { skill_name = skillName, prompt = "#os__congfeng-discard::" .. data.from.id, }
          )
        then
          event:setCostData(self, { swithState = player:getSwitchSkillState(skillName) })
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local skillName = congfeng.name
    local room = player.room
    local swithState = event:getCostData(self).swithState ---@type integer
    local cards = event:getCostData(self).cards

    if swithState == fk.SwitchYin then
      player:drawCards(1, skillName)
      if data.from:isAlive() then
        data.from:drawCards(1, skillName)
      end
    else
      if cards then
        room:throwCard(cards, skillName, player, player)
      else
        local ids = room:askToChooseCards(
          player,
          {
            min = 2,
            max = 2,
            target = data.from,
            flag = "he",
            skill_name = skillName,
          }
        )

        room:throwCard(ids, skillName, data.from, player)
      end
    end
  end,
}

congfeng:addEffect(fk.TargetSpecified, spec)

congfeng:addEffect(fk.TargetConfirmed, spec)

congfeng:addAcquireEffect(function (self, player, is_start, src)
  U.SetSwitchSkillState(player, congfeng.name, fk.SwitchYin)
end)

return congfeng
