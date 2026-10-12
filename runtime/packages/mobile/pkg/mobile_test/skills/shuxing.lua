local shuxing = fk.CreateSkill {
  name = "shuxing",
}

Fk:loadTranslationTable{
  ["shuxing"] = "束刑",
  [":shuxing"] = "你的回合内每名角色限一次，当一名其他角色成为【杀】的目标时，你可以令此【杀】对其无效，然后展示其所有手牌。" ..
  "若其手牌中有【闪】，则其须选择一项：1.失去1点体力；2.交给你其中所有【闪】，且下次进行“禀法”选择时，改为由你代替其进行选择。",

  ["#shuxing-invoke"] = "束刑：你可令此【杀】对 %dest 无效，展示其手牌，若其中有【闪】则令其做选择",
  ["shuxing_lose"] = "失去1点体力",
  ["shuxing_give"] = "交给你其中所有【闪】，且下次选择“禀法”的律法的选择权交给%src",

  ["$shuxing1"] = "事无目见耳闻，岂可臆断论罪？",
  ["$shuxing2"] = "夫女子之情，以接见而恩生，成妇而义重。",
}

shuxing:addEffect(fk.TargetConfirming, {
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      data.card.trueName == "slash" and
      target:isAlive() and
      player:hasSkill(shuxing.name) and
      player.room:getCurrent() == player and
      not table.contains(player:getTableMark("shuxing_targets-turn"), target.id)
  end,
  on_cost = function(self, event, target, player, data)
    if
      player.room:askToSkillInvoke(
        player,
        { skill_name = shuxing.name, prompt = "#shuxing-invoke::" .. target.id }
      )
    then
      player.room:addTableMark(player, "shuxing_targets-turn", target.id)
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    ---@type string
    local skillName = shuxing.name

    local to = event:getCostData(self).tos[1]
    data.nullified = true
    if not to:isKongcheng() then
      local handcards = to:getCardIds("h")
      to:showCards(handcards, player)

      local jinks = table.filter(handcards, function(id) return Fk:getCardById(id).trueName == "jink" end)
      if to:isAlive() and #jinks > 0 then
        local choices = { "shuxing_lose" }
        if player:isAlive() then
          table.insert(choices, "shuxing_give:" .. player.id)
        end

        local choice = room:askToChoice(
          to,
          {
            choices = choices,
            skill_name = skillName,
            all_choices = { "shuxing_lose", "shuxing_give:" .. player.id },
          }
        )

        if choice == "shuxing_lose" then
          room:loseHp(to, 1, skillName)
        else
          room:obtainCard(player, jinks, true, fk.ReasonGive, to, skillName)
          if to:isAlive() then
            room:addTableMarkIfNeed(to, "bingfa_skip-noclear", player.id)
          end
        end
      end
    end
  end,
})

return shuxing
