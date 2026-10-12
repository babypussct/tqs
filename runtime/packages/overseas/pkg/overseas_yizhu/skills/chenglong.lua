local chenglong = fk.CreateSkill {
  name = "os__chenglong",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["os__chenglong"] = "成龙",
  [":os__chenglong"] = "觉醒技，一名角色的结束阶段，若你已执行过〖慈荫〗的所有选项，你获得武将牌上所有“荫”，" ..
  "然后失去〖慈荫〗，从四张蜀势力或群势力武将牌中选择并获得至多两个描述中含有【杀】或【闪】的技能（觉醒技、限定技、使命技、主公技除外）。",

  ["#os__chenglong-choice"] = "成龙：选择并获得至多两个技能",

  ["$os__chenglong1"] = "这次，换孩儿来保护母亲！",
  ["$os__chenglong2"] = "儿虽年幼，亦当立丈夫之志！",
}

local U = require "packages.utility.utility"

chenglong:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenglong.name) and target.phase == Player.Finish and
      player:usedSkillTimes(chenglong.name, Player.HistoryGame) == 0
  end,
  can_wake = function (self, event, target, player, data)
    return player:getMark("_os__ciyin_choice") == "allDone"
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:obtainCard(player, player:getPile("os__protect"), true, fk.ReasonPrey, player, chenglong.name)
    if player.dead then return end
    room:handleAddLoseSkills(player, "-os__ciyin")
    if player.dead then return end
    local kingdoms = {"shu", "qun"}
    local generals, skillList = {}, {}
    local index = 1
    while #generals < 4 and index <= #room.general_pile do
      local g = room.general_pile[index]
      if (table.contains(kingdoms, Fk.generals[g].kingdom) or table.contains(kingdoms, Fk.generals[g].subkingdom)) then
        local skills = table.filter(Fk.generals[g]:getSkillNameList(false), function(s)
          local skill = Fk.skills[s]
          return table.find({Skill.Wake, Skill.Limited, Skill.Quest, Skill.Lord}, function (tag)
            return skill:hasTag(tag)
          end) == nil and
          (string.find(Fk:getDescription(s, "zh_CN"), "【杀】") ~= nil or string.find(Fk:getDescription(s, "zh_CN"), "【闪】") ~= nil)
        end)
        if #skills > 0 then
          table.insert(generals, table.remove(room.general_pile, index))
          table.insert(skillList, skills)
        else
          index = index + 1
        end
      else
        index = index + 1
      end
    end
    if #generals == 0 then
      return
    end
    if #generals > 0 then
      local choice = U.askToChooseGeneralSkills(player, {
        generals = generals,
        skills = skillList,
        min_num = 1,
        max_num = 2,
        skill_name = chenglong.name,
        prompt = "#os__chenglong-choice",
        cancelable = false
      })
      room:handleAddLoseSkills(player, table.concat(choice, "|"), nil)
      room:returnToGeneralPile(generals, "bottom")
    end
  end
})

return chenglong
