local caowei = fk.CreateSkill {
  name = "caowei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["caowei"] = "操微",
  [":caowei"] = "锁定技，当你受到伤害后，你重铸至少一种类别的所有牌并摸一张牌。",

  ["#caowei-choose"] = "操微：请选择至少一种类别，重铸你这些类别的所有牌",

  ["$caowei1"] = "张辽不过死士八百，何敢逆我十万雄兵？",
  ["$caowei2"] = "敌军寡弱，卿等围而击之。",
}

caowei:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(caowei.name)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = caowei.name
    local room = player.room

    local types = {}
    table.forEach(player:getCardIds("he"), function(id)
      table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
    end)

    if #types > 0 then
      local choices = {}

      if #types > 1 then
        choices = room:askToChoices(
          player,
          {
            choices = types,
            min_num = 1,
            max_num = #types,
            skill_name = skillName,
            prompt = "#caowei-choose:::" .. #types,
            cancelable = false,
          }
        )
      else
        choices = { types[1] }
      end

      local toRecast = table.filter(player:getCardIds("he"), function(id)
        return table.contains(choices, Fk:getCardById(id):getTypeString())
      end)
      if #toRecast > 0 then
        room:recastCard(toRecast, player, skillName)

        if not player:isAlive() then
          return false
        end
      end
    end

    player:drawCards(1, skillName)
  end,
})

return caowei
