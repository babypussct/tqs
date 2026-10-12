local yuetan = fk.CreateSkill {
  name = "yuetan",
}

Fk:loadTranslationTable{
  ["yuetan"] = "跃檀",
  [":yuetan"] = "当与你距离1以内的角色成为伤害牌的目标后，你可以交给其一张牌（若其为你，则改为可直接发动此技能），" ..
  "此伤害牌结算结束后，若其未受到过此牌造成的伤害，你摸一张牌。你每以此法失去两张牌，你回复1点体力。",

  ["#yuetan-invoke"] = "跃檀：你可以发动本技能，若未受到此牌伤害则摸1张牌",
  ["#yuetan-give"] = "跃檀：你可以交给 %dest 一张牌，若其未受伤害你摸1张牌",
  ["@@yuetan_give"] = "跃檀",

  ["$yuetan1"] = "上跃九天之堑，下渡万仞之渊！",
  ["$yuetan2"] = "让这一跃，震惊天地！",
}

yuetan:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return
      (data.card.is_damage_card or data.card.name == "lightning") and
      data.to:isAlive() and
      player:hasSkill(yuetan.name) and
      (not player:isNude() or data.to == player) and
      data.to:distanceTo(player) <= 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if data.to == player then
      if room:askToSkillInvoke(player, { skill_name = yuetan.name, prompt = "#yuetan-invoke" }) then
        event:setCostData(self, { cards = nil })
        return true
      end
    else
      local ids = room:askToCards(
        player,
        {
          min_num = 1,
          max_num = 1,
          pattern = ".",
          include_equip = true,
          skill_name = yuetan.name,
          prompt = "#yuetan-give::" .. data.to.id,
        }
      )

      if #ids > 0 then
        event:setCostData(self, { cards = ids })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yuetan.name
    local room = player.room
    local toGive = event:getCostData(self).cards
    if toGive then
      room:obtainCard(data.to, toGive, false, fk.ReasonGive, player, skillName)
      local yuetanMark = player:getMark("@@yuetan_give")
      if yuetanMark == 0 then
        room:addPlayerMark(player, "@@yuetan_give")
      else
        room:setPlayerMark(player, "@@yuetan_give", 0)
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = skillName,
        }
      end
    end

    data.extra_data = data.extra_data or {}
    data.extra_data.yuetanRecord = data.extra_data.yuetanRecord or {}
    data.extra_data.yuetanRecord[player] = data.extra_data.yuetanRecord[player] or {}
    table.insertIfNeed(data.extra_data.yuetanRecord[player], data.to)
  end,
})

yuetan:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      next((data.extra_data or {}).yuetanRecord or {}) ~= nil and
      data.extra_data.yuetanRecord[player] and
      player:isAlive() and
      table.find(data.extra_data.yuetanRecord[player], function(to)
        return not (data.damageDealt or {})[to]
      end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(
      #table.filter(data.extra_data.yuetanRecord[player], function(to)
        return not (data.damageDealt or {})[to]
      end),
      yuetan.name
    )
  end,
})

return yuetan
