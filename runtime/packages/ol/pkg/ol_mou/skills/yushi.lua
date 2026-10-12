local yushi = fk.CreateSkill{
  name = "yushi",
}

Fk:loadTranslationTable{
  ["yushi"] = "驭势",
  [":yushi"] = "当你造成或受到伤害后，你可以令一名：有转换技的角色切换其转换技状态；无转换技的角色获得出牌阶段各限一次的〖迁附〗，"..
  "直到其失去最后一张手牌。每轮限X次，有转换技切换状态后，你摸一张牌（X为你的体力上限）。",

  ["#yushi-choose"] = "驭势：切换一名角色的转换技状态，或令一名没有转换技的角色获得“迁附”",
  ["yushi_switch"] = "切换转换技",
  ["yushi_skill"] = "获得迁附",

  ["$yushi1"] = "势者，非由天定，乃凭人谋。",
  ["$yushi2"] = "袁曹相争，乱中取利。",
}

local U = require "packages.utility.utility"

Fk:addTargetTip{
  name = "yushi",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if not selectable then return end
    if table.find(to_select:getSkillNameList(), function (s)
      return Fk.skills[s]:hasTag(Skill.Switch)
    end) then
      return "yushi_switch"
    else
      return "yushi_skill"
    end
  end,
}

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yushi.name)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = yushi.name,
      prompt = "#yushi-choose",
      cancelable = true,
      target_tip_name = yushi.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local yes = false
    for _, skill in ipairs(to:getSkillNameList()) do
      if Fk.skills[skill]:hasTag(Skill.Switch) then
        yes = true
        U.SetSwitchSkillState(to, skill, to:getSwitchSkillState(skill, false) == fk.SwitchYang and fk.SwitchYin or fk.SwitchYang)
      end
    end
    if yes then
      room:setBanner(yushi.name, 1)
    else
      room:setBanner(yushi.name, 0)
      room:handleAddLoseSkills(to, "ol__qianfux")
    end
  end,
}

yushi:addEffect(fk.Damage, spec)
yushi:addEffect(fk.Damaged, spec)

yushi:addEffect(fk.AfterSkillEffect, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(yushi.name) and player:usedEffectTimes(self.name, Player.HistoryRound) < player.maxHp then
      if data.skill.name == yushi.name or data.skill.name == "#yushi_2_trig" then
        return player.room:getBanner(yushi.name) == 1
      else
        return data.skill:hasTag(Skill.Switch) and not data.skill.is_delay_effect
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, yushi.name)
  end,
})

return yushi
