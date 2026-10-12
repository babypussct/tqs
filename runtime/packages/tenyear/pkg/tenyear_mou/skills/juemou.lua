local juemou = fk.CreateSkill {
  name = "juemou",
  tags = { Skill.Switch },
  dynamic_desc = function(self, player)
    return player:getMark("juemou_upgrade") > 0 and "juemou_up" or "juemou"
  end,
}

Fk:loadTranslationTable{
  ["juemou"] = "绝谋",
  [":juemou"] = "转换技，游戏开始时可自选阴阳状态。当你使用锦囊牌时，你可以：阳：对自己造成1点伤害并摸已损失体力值张数的牌；"..
  "阴：令一名角色弃置另一名角色一张牌并受到其造成的1点伤害。若你因此技能的伤害进入濒死状态，你回复体力值至1点。",
  [":juemou_up"] = "转换技，游戏开始时可自选阴阳状态。当你使用锦囊牌时，或回合开始和结束时，你可以：阳：对自己造成1点伤害并摸已损失体力值张数的牌；"..
  "阴：令一名角色弃置另一名角色一张牌并受到其造成的1点伤害。若你因此技能的伤害进入濒死状态，你回复体力值至1点。",

  ["#juemou-yang"] = "绝谋：你可对自己造成1点伤害并摸已损失体力值张牌",
  ["#juemou-yin"] = "绝谋：请选择一名角色弃置另一名角色1张牌",

  ["juemou_discard"] = "被弃置牌",
  ["juemou_damage"] = "受到伤害",

  ["$juemou1"] = "我若束手待缚，四百年来英雄血，岂不枉流！",
  ["$juemou2"] = "武侯遗志，绝不可成泡影！",
}

local U = require "packages.utility.utility"

local juemouOnCost = function(self, event, target, player, data)
  ---@type string
  local skillName = juemou.name
  local room = player.room
  if player:getSwitchSkillState(juemou.name) == fk.SwitchYang then
    if room:askToSkillInvoke(player, { skill_name = skillName, prompt = "#juemou-yang" }) then
      event:setCostData(self, { switchStatus = fk.SwitchYang })
      return true
    end

    return false
  end

  local tos = room:askToChoosePlayers(
    player,
    {
      min_num = 2,
      max_num = 2,
      targets = room:getAlivePlayers(false),
      skill_name = skillName,
      prompt = "#juemou-yin",
      target_tip_name = "juemou_tip",
    }
  )

  if #tos == 2 then
    event:setCostData(self, { switchStatus = fk.SwitchYin, tos = tos })
    return true
  end
end

local juemouOnUse = function(self, event, target, player, data)
  ---@type string
  local skillName = juemou.name
  local room = player.room
  local switchStatus = event:getCostData(self).switchStatus
  U.SetSwitchSkillState(player, skillName, switchStatus == fk.SwitchYang and fk.SwitchYin or fk.SwitchYang)

  if switchStatus == fk.SwitchYang then
    room:damage{
      from = player,
      to = player,
      damage = 1,
      skillName = skillName,
    }

    if player:isAlive() then
      player:drawCards(player:getLostHp(), skillName)
    end
  else
    local tos = event:getCostData(self).tos
    if not tos[2]:isNude() then
      local cid = room:askToChooseCard(
        tos[1],
        {
          flag = "he",
          target = tos[2],
          skill_name = skillName,
        }
      )

      room:throwCard(cid, skillName, tos[2], tos[1])
    end

    if tos[1]:isAlive() and tos[2]:isAlive() then
      room:damage{
        from = tos[2],
        to = tos[1],
        damage = 1,
        skillName = skillName,
      }
    end
  end
end

juemou:addEffect(fk.CardUsing, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.type == Card.TypeTrick and player:hasSkill(juemou.name)
  end,
  on_cost = juemouOnCost,
  on_use = juemouOnUse,
})

juemou:addEffect(fk.TurnStart, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juemou.name) and player:getMark("juemou_upgrade") > 0
  end,
  on_cost = juemouOnCost,
  on_use = juemouOnUse,
})

juemou:addEffect(fk.TurnEnd, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juemou.name) and player:getMark("juemou_upgrade") > 0
  end,
  on_cost = juemouOnCost,
  on_use = juemouOnUse,
})

juemou:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(juemou.name, true) and
      player.hp < 1 and data.damage and
      data.damage.skillName == juemou.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = juemou.name,
    }
  end,
})

juemou:addEffect(fk.GameStart, {
  mute = true,
  is_delay_effect = true,
  priority = 1.5,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(juemou.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = juemou.name
    local room = player.room
    local choice = room:askToChoice(
      player,
      {
        choices = { "tymou_switch:::" .. skillName .. ":yang", "tymou_switch:::" .. skillName .. ":yin" },
        skill_name = skillName,
        prompt = "#tymou_switch-choice:::" .. skillName,
      }
    )
    U.SetSwitchSkillState(player, skillName, choice:endsWith("yang") and fk.SwitchYang or fk.SwitchYin)
  end,
})

juemou:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "juemou_upgrade", 0)
end)

Fk:addTargetTip{
  name = "juemou_tip",
  target_tip = function(_, _, to_select, selected, _, _, selectable)
    if not selectable then
      return
    end

    if #selected > 0 and to_select ~= selected[1] then
      return "juemou_discard"
    end

    return "juemou_damage"
  end,
}

return juemou
