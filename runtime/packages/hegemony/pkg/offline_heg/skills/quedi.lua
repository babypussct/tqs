local quedi = fk.CreateSkill {
  name = "ofl_heg__quedi",
}

Fk:loadTranslationTable{
  ["ofl_heg__quedi"] = "却敌",
  [":ofl_heg__quedi"] = "当你使用【杀】或【决斗】指定唯一目标时，你可以选择一项：1.获得其一张手牌；2.弃置一张基本牌，令此牌伤害基数+1。"..
  "当你杀死一名角色后，你可以交换你的主副将。",

  ["#ofl_heg__quedi-invoke"] = "却敌：是否对 %dest 发动“却敌”？",
  ["ofl_heg__quedi_prey"] = "获得 %dest 一张手牌",
  ["ofl_heg__quedi_damage"] = "弃一张基本牌，令此牌伤害+1",
  ["#ofl_heg__quedi-discard"] = "却敌：弃置一张基本牌，令此%arg伤害+1",
  ["#ofl_heg__quedi-transform"] = "却敌：是否交换你的主副将？",

  ["$ofl_heg__quedi1"] = "力摧敌阵，如视天光破云！",
  ["$ofl_heg__quedi2"] = "让尔等有命追，无命回！",
}

local H = require "packages.hegemony.util"

quedi:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(quedi.name) and
      table.contains({ "slash", "duel" }, data.card.trueName) and
      data:isOnlyTarget(data.to) and not (data.to:isKongcheng() and player:isKongcheng())
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = { "ofl_heg__quedi_prey::"..data.to.id, "ofl_heg__quedi_damage", "Cancel" }
    local choices = table.simpleClone(all_choices)
    if player:isKongcheng() then
      table.remove(choices, 2)
    end
    if data.to:isKongcheng() then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = quedi.name,
      prompt = "#ofl_heg__quedi-invoke::"..data.to.id,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      if choice == "ofl_heg__quedi_damage" then
        local card = room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = quedi.name,
          pattern = ".|.|.|.|.|basic",
          cancelable = true,
          prompt = "#ofl_heg__quedi-discard:::" .. data.card:toLogString(),
          skip = true,
        })
        if #card > 0 then
          event:setCostData(self, { tos = { data.to }, choice = choice, cards = card })
          return true
        end
      else
        event:setCostData(self, { tos = { data.to }, choice = choice })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice:startsWith("ofl_heg__quedi_prey") then
      local id = room:askToChooseCard(player, {
        target = data.to,
        flag = "h",
        skill_name = quedi.name,
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, quedi.name)
      if player.dead then return end
    else
      data.additionalDamage = (data.additionalDamage or 0) + 1
      room:throwCard(event:getCostData(self).cards, quedi.name, player, player)
    end
  end,
})

quedi:addEffect(fk.Deathed, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(quedi.name) and data.killer == player and
      H.hasGeneral(player, true) and Fk.generals[player.general].kingdom ~= "wild"
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = quedi.name,
      prompt = "#ofl_heg__quedi-transform",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local main, deputy = player.general, player.deputyGeneral
    room:setPlayerMark(player, "__heg_general", deputy)
    room:setPlayerMark(player, "__heg_deputy", main)
    local all_skills = table.connectIfNeed(Fk.generals[main]:getSkillNameList(false), Fk.generals[deputy]:getSkillNameList(false))
    local skills = ""
    for _, s in ipairs(all_skills) do
      if Fk.skills[s]:hasTag(Skill.MainPlace) and not player:hasSkill(s, true) then
        
      end
    end
  end,
})

return quedi
