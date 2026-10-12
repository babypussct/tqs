local quedi = fk.CreateSkill {
  name = "quedi",
}

Fk:loadTranslationTable{
  ["quedi"] = "却敌",
  [":quedi"] = "每回合限一次，当你使用【杀】或【决斗】指定唯一目标后，你可以选择一项：1.获得其一张手牌；2.弃置一张基本牌，令此【杀】或【决斗】"..
  "伤害基数+1；背水：减1点体力上限。",

  ["#quedi-choice"] = "却敌：你可以是否对 %dest 发动“却敌”？（已用：%arg/%arg2）",
  ["quedi_prey"] = "获得%dest一张手牌",
  ["quedi_damage"] = "弃一张基本牌，令此【%arg】伤害+1",
  ["quedi_beishui"] = "背水：减1点体力上限",
  ["#quedi-discard"] = "却敌：你可以弃置一张基本牌，令此【%arg】伤害+1",

  ["$quedi1"] = "力摧敌阵，如视天光破云！",
  ["$quedi2"] = "让尔等有命追，无命回！",
}

quedi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(quedi.name) and
      player:usedSkillTimes(quedi.name, Player.HistoryTurn) < (1 + player:getMark("choujue_buff-turn")) and
      table.contains({ "slash", "duel" }, data.card.trueName) and
      data:isOnlyTarget(data.to) and not (data.to:isKongcheng() and player:isKongcheng())
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = { "quedi_prey::"..data.to.id, "quedi_damage:::"..data.card.trueName, "quedi_beishui", "Cancel" }
    local choices = table.simpleClone(all_choices)
    if player:isKongcheng() then
      table.remove(choices, 2)
    end
    if data.to:isKongcheng() then
      table.remove(choices, 1)
    end
    local prompt = "#quedi-choice::"..data.to.id..":"..player:usedSkillTimes(quedi.name, Player.HistoryTurn)..":"
    ..(1 + player:getMark("choujue_buff-turn"))
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = quedi.name,
      prompt = prompt,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {data.to}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if not choice:startsWith("quedi_damage") and data.to:isAlive() and not data.to:isKongcheng() then
      local id = room:askToChooseCard(player, {
        target = data.to,
        flag = "h",
        skill_name = quedi.name,
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, quedi.name)
      if player.dead then return end
    end
    if not choice:startsWith("quedi_prey") then
      if #room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = quedi.name,
        pattern = ".|.|.|.|.|basic",
        cancelable = true,
        prompt = "#quedi-discard:::" .. data.card.trueName,
      }) > 0 then
        data.additionalDamage = (data.additionalDamage or 0) + 1
        if player.dead then return end
      end
    end
    if choice == "quedi_beishui" then
      room:changeMaxHp(player, -1)
    end
  end,
})

return quedi
