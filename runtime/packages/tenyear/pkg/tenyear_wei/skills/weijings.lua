local weijing = fk.CreateSkill {
  name = "weijings",
}

Fk:loadTranslationTable{
  ["weijings"] = "威靖",
  [":weijings"] = "其他吴势力角色的回合开始时，你可以选择一项令其执行：1.受到你造成的1点伤害；2.交给你一张牌，然后其可发动一次对应条件的“猘锋”。",

  ["#weijings-invoke"] = "威靖：你可以选择一项令 %dest 执行",
  ["weijings_damage"] = "受到你造成的1点伤害",
  ["weijings_give"] = "交给你一张牌，然后其可发动一次对应条件的“猘锋”",
  ["#weijings-give"] = "威靖：请交给 %src 一张牌，然后你可发动一次对应条件的“猘锋”",

  ["$weijings1"] = "既称吴臣，方可免死！",
  ["$weijings2"] = "天无二日，虎犬安能并列！",
}

weijing:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target ~= player and target.kingdom == "wu" and target:isAlive() and player:hasSkill(weijing.name)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = { "weijings_damage", "weijings_give", "Cancel" }
    if target:isNude() then
      table.remove(choices, 2)
    end
    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = weijing.name,
        prompt = "#weijings-invoke::" .. target.id,
        all_choices = { "weijings_damage", "weijings_give", "Cancel" }
      }
    )

    if choice ~= "Cancel" then
      event:setCostData(self, { tos = { target }, choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = weijing.name
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "weijings_damage" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skillName,
      }
    else
      if target:isNude() then
        return false
      end

      local id = room:askToCards(
        target,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skillName,
          prompt = "#weijings-give:" .. player.id,
          cancelable = false,
        }
      )

      room:obtainCard(player, id, false, fk.ReasonGive, player, skillName)

      if target:isAlive() then
        local prompt = "#zhifeng-analeptic"
        local handcardNum = target:getHandcardNum()
        if handcardNum == target.hp then
          prompt = "#zhifeng-duel"
        elseif handcardNum < target.hp then
          prompt = "#zhifeng-slash"
        end
        local success, dat = room:askToUseActiveSkill(
          target,
          {
            skill_name = "zhifeng",
            prompt = prompt,
          }
        )

        if success and dat and dat.cards then
          local card = Fk.skills["zhifeng"]:viewAs(target, dat.cards)
          if not card then
            return false
          end

          local use = {
            from = target,
            tos = dat.targets,
            card = card,
          }
          Fk.skills["zhifeng"]:beforeUse(target, use)

          room:useCard(use)

          Fk.skills["zhifeng"]:afterUse(target, use)
        end
      end
    end
  end,
})

return weijing
