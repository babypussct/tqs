local osFuzuan = fk.CreateSkill {
  name = "os__fuzuan"
}

Fk:loadTranslationTable{
  ["os__fuzuan"] = "复纂",
  [":os__fuzuan"] = "你可于以下时机点选择一名有转换技的角色，调整其一个转换技的阴阳状态：出牌阶段限一次，你对其他角色造成伤害后，受到伤害后。",

  ["#os__fuzuan-trg"] = "你可对一名有转换技的角色发动“复纂”",
  ["#os__fuzuan"] = "复纂:调整一名角色一个转换技的阴阳状态",
  ["#os__fuzuan-ask"] = "选择改变 %src 一个转换技的阴阳状态",
  ["#ChangeSwitchState"] = "%from 将 %to 的 “%arg” 调整为 %arg2",

  ["$os__fuzuan1"] = "望陛下听臣忠言，勿信资等无知之论。",
  ["$os__fuzuan2"] = "前朝王莽之乱，可为今事之鉴。",
}

local U = require "packages.utility.utility"

--- 改变转换技状态
---@param room Room
---@param player ServerPlayer
---@param target ServerPlayer
---@param reason? string
---@return string @ 被改变的转换技名
local ChangeSwitchState = function(room, player, target, reason)
  local skills = table.filter(target.player_skills, function(s)
    return s:hasTag(Skill.Switch) and s:isPlayerSkill(player)
  end)
  local skillNames = table.map(skills, Util.NameMapper)
  local skillName = room:askToChoice(
    player,
    {
      choices = skillNames,
      skill_name = reason,
      prompt = "#os__fuzuan-ask:" .. target.id,
    }
  )

  U.SetSwitchSkillState(target, skillName)
  room:sendLog{
    type = "#ChangeSwitchState",
    from = player.id,
    to = { target.id },
    arg = skillName,
    arg2 = target:getSwitchSkillState(skillName, false, true),
  }
  return skillName
end

osFuzuan:addEffect("active", {
  anim_type = "control",
  prompt = "#os__fuzuan",
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected ~= 0 then return false end
    for _, skill in ipairs(to_select.player_skills) do
      if skill:hasTag(Skill.Switch) and skill:isPlayerSkill(to_select) then
        return true
      end
    end
    return false
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    ChangeSwitchState(room, effect.from, effect.tos[1], osFuzuan.name)
  end,
})

---@type TrigSkelSpec<DamageTrigFunc>
local spec = {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osFuzuan.name) and
      (event == fk.Damaged or data.to ~= player) and
      table.find(player.room.alive_players, function(p)
        return not not table.find(p.player_skills, function(s) return s:hasTag(Skill.Switch) and s:isPlayerSkill(p) end)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not not table.find(p.player_skills, function(s) return s:hasTag(Skill.Switch) and s:isPlayerSkill(p) end)
    end)
    local to = room:askToChoosePlayers(
      player,
        {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__fuzuan-trg",
        skill_name = osFuzuan.name,
      }
    )
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    ChangeSwitchState(player.room, player, to, osFuzuan.name)
  end,
}

osFuzuan:addEffect(fk.Damage, spec)

osFuzuan:addEffect(fk.Damaged, spec)

return osFuzuan
