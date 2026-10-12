
local jiaojie = fk.CreateSkill {
  name = "jiaojie",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = { "wei" },
}

Fk:loadTranslationTable{
  ["jiaojie"] = "矫节",
  [":jiaojie"] = "魏势力技，当你使用牌后，你可以获得其他目标角色各一张牌。若你获得牌与本回合被使用的首张牌类型不同，你失去1点体力或变更势力至吴。",

  ["#jiaojie-invoke"] = "矫节：你可以获得其他目标角色各一张牌",
  ["jiaojie_kingdom"] = "变更势力至吴",

  ["$jiaojie1"] = "",
  ["$jiaojie2"] = "",
}

jiaojie:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiaojie.name) and
      table.find(data.tos, function (p)
        return p ~= player and not p:isNude()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = jiaojie.name,
      prompt = "#jiaojie-invoke",
    }) then
      local tos = data.tos
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local t
    if room.logic:getCurrentEvent():findParent(GameEvent.Turn) then
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        t = e.data.card.type
        return true
      end, Player.HistoryTurn)
    end
    for _, to in ipairs(data.tos) do
      if player.dead then return end
      if to ~= player and not to:isNude() then
        local id = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = jiaojie.name,
        })
        local yes = t ~= nil and Fk:getCardById(id) ~= t
        room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, jiaojie.name, nil, false, player)
        if player.dead then return end
        if yes then
          local choice = room:askToChoice(player, {
            choices = { "loseHp", "jiaojie_kingdom" },
            skill_name = jiaojie.name,
          })
          if choice == "loseHp" then
            room:loseHp(player, 1, jiaojie.name)
          else
            room:changeKingdom(player, "wu", true)
          end
        end
      end
    end
  end,
})

return jiaojie
