local dejiao = fk.CreateSkill {
  name = "dejiao",
}

Fk:loadTranslationTable{
  ["dejiao"] = "德教",
  [":dejiao"] = "当你受到伤害后，你可以观看并重铸一名角色的至多X张手牌（X为此技能发动次数），若重铸的牌中没有伤害类牌，重置X。",

  ["#dejiao-choose"] = "德教：观看并重铸一名角色的至多%arg张手牌",
  ["#dejiao-recast"] = "德教：重铸 %dest 的至多%arg张手牌",

  ["$dejiao1"] = "师之善，在启迪，在明德。",
  ["$dejiao2"] = "学问之道，以德为先。",
}

dejiao:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dejiao.name) and
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#dejiao-choose:::"..(player:usedSkillTimes(dejiao.name, Player.HistoryGame) + 1),
      skill_name = dejiao.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = player:usedSkillTimes(dejiao.name, Player.HistoryGame)
    local cards = room:askToChooseCards(player, {
      target = to,
      min = 1,
      max = n,
      flag = { card_data = { { to.general, to:getCardIds("h") } } },
      skill_name = dejiao.name,
      prompt = "#dejiao-recast::"..to.id..":"..n,
    })
    local yes = not table.find(cards, function (id)
      return Fk:getCardById(id).is_damage_card
    end)
    room:recastCard(cards, to, dejiao.name)
    if yes then
      player:setSkillUseHistory(dejiao.name, 0, Player.HistoryGame)
    end
  end,
})

return dejiao
