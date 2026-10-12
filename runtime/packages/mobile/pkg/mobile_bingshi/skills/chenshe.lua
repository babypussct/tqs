local chenshe = fk.CreateSkill {
  name = "chenshe",
}

Fk:loadTranslationTable{
  ["chenshe"] = "陈赦",
  [":chenshe"] = "当一名其他角色进入濒死状态时，你可以依次弃置你、其、伤害来源的各一张牌，若这些角色均被因此弃置了牌且花色均相同，" ..
  "其回复体力至上限，然后你失去此技能。",

  ["#chenshe-invoke"] = "陈赦：你可弃置你、%src、%dest各一张牌，若花色相同则%src回复满体力",
  ["#chenshe-invokeNoSource"] = "陈赦：你可弃置你、%src各一张牌，若花色相同则%src回复满体力",
  ["#chenshe-discard"] = "陈赦：请弃置 %dest 一张牌，当前花色：%arg",
  ["chenshe_none"] = "无",

  ["$chenshe1"] = "此等余党，非为首恶，请曹公免于行刑。",
  ["$chenshe2"] = "田银、苏伯既破，余党复何虑哉。",
  ["$chenshe3"] = "今者千人得生，全赖曹公恩德。",
}

chenshe:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      player:hasSkill(chenshe.name) and
      (
        not player:isNude() or
        (target:isAlive() and not target:isNude()) or
        (data.damage and data.damage.from and data.damage.from:isNude())
      )
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = (data.damage and data.damage.from) and
      ("#chenshe-invoke:" .. target.id .. ":" .. data.damage.from.id) or
      ("#chenshe-invokeNoSource:" .. target.id)
    return player.room:askToSkillInvoke(
      player,
      {
        skill_name = chenshe.name,
        prompt = prompt,
      }
    )
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = chenshe.name
    local room = player.room
    local suitsDiscard = {}
    local targets = { player, target }
    if data.damage and data.damage.from then
      table.insert(targets, data.damage.from)
    end
    for _, p in ipairs(targets) do
      if p:isAlive() and not p:isNude() then
        local suitsPrompt = table.concat(table.map(suitsDiscard, function(suit) return Fk:translate(suit) end), "、")
        local id
        if p == player then
          local ids = room:askToDiscard(
            p,
            {
              min_num = 1,
              max_num = 1,
              skill_name = skillName,
              include_equip = true,
              prompt = "#chenshe-discard::" .. p.id .. (#suitsDiscard > 0 and ":" .. suitsPrompt or ":chenshe_none"),
              cancelable = false,
              skip = true,
            }
          )

          if #ids > 0 then
            id = ids[1]
          end
        else
          id = room:askToChooseCard(
            player,
            {
              target = p,
              flag = "he",
              skill_name = skillName,
              prompt = "#chenshe-discard::" .. p.id .. (#suitsDiscard > 0 and ":" .. suitsPrompt or ":chenshe_none"),
            }
          )
        end

        if id then
          table.insert(suitsDiscard, Fk:getCardById(id):getSuitString())
          room:throwCard(id, skillName, p, player)
        end
      end
    end

    if
      #suitsDiscard == 3 and
      target:isAlive() and
      table.every(suitsDiscard, function(suit) return suit ~= "nosuit" and suit == suitsDiscard[1] end)
    then
      room:recover{
        who = target,
        num = target.maxHp - target.hp,
        skillName = skillName,
        recoverBy = player,
      }

      room:handleAddLoseSkills(player, "-" .. skillName)
    end
  end,
})

return chenshe
