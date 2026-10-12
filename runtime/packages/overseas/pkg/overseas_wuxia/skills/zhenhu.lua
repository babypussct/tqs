local zhenhu = fk.CreateSkill {
  name = "os__zhenhu",
}

Fk:loadTranslationTable{
  ["os__zhenhu"] = "震虎",
  [":os__zhenhu"] = "当你使用伤害牌指定目标时，你可以摸一张牌并与至多三名其他角色<a href='#JointPindianDesc'>共同拼点</a>：" ..
  "若你赢，此牌对没赢的角色造成伤害+1。若你没赢，你失去1点体力。",

  ["#os__zhenhu-ask"] = "震虎：与至多三名角色共同拼点，此牌对没赢的角色伤害+1，你没赢则失去体力",

  ["$os__zhenhu1"] = "戟出势如虎，百兽尽皆服！",
  ["$os__zhenhu2"] = "横戟冲阵，敌纵为猛虎凶豺，亦不敢前！",
}

local U = require "packages.utility.utility"

zhenhu:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(zhenhu.name) and data.card.is_damage_card and
      data.firstTarget and table.find(player.room:getOtherPlayers(player, false), function(p) return player:canPindian(p) end)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = zhenhu.name
    player:drawCards(1, skillName)
    local room = player.room
    local availableTargets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:canPindian(p)
    end)
    if #availableTargets == 0 then return false end
    local targets = room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 3,
      prompt = "#os__zhenhu-ask",
      skill_name = skillName,
      cancelable = false,
    })
    if #targets == 0 then return false end
    local pd = U.jointPindian(player, targets, skillName)
    if pd.winner == player then
      data.extra_data = data.extra_data or {}
      data.extra_data.os__zhenhu = targets
    else
      room:loseHp(player, 1, skillName)
    end
  end,
})

zhenhu:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return parentUseData and type((parentUseData.data.extra_data or {}).os__zhenhu) == "table" and
      table.contains((parentUseData.data.extra_data or {}).os__zhenhu, data.to)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return zhenhu
