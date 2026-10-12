local kuimu = fk.CreateSkill {
  name = "os__kuimu",
}

Fk:loadTranslationTable {
  ["os__kuimu"] = "窥目",
  [":os__kuimu"] = "每轮限一次，当一名角色的判定牌生效前，你可以观看其所有手牌并用其中一张代替之，" ..
      "若两张牌的花色不同，其对你造成1点伤害。",

  ["#os__kuimu-invoke"] = "是否发动“窥目”，观看%dest所有手牌并用其中一张代替判定牌",

  ["$os__kuimu1"] = "孤以一目穷极九州，更何需他哉？",
  ["$os__kuimu2"] = "世人皆曰天意浩渺，于孤不过一目可窥！",
}

kuimu:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kuimu.name) and not target:isKongcheng() and player:usedSkillTimes(kuimu.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
          skill_name = kuimu.name,
          prompt = "#os__kuimu-invoke::" .. target.id,
        }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local old = data.card
    local card = room:askToChooseCard(player, {
      target = target,
      flag = { card_data = { { "$Hand", target:getCardIds("h") } } },
      skill_name = kuimu.name,
    })
    room:changeJudge{
      card = Fk:getCardById(card),
      player = player,
      data = data,
      skillName = kuimu.name,
    }
    if old and old:compareSuitWith(Fk:getCardById(card), true) and player:isAlive() then
      room:damage{
        from = target,
        to = player,
        damage = 1,
        skillName = kuimu.name,
        damageType = fk.NormalDamage,
      }
    end
  end
})

return kuimu
