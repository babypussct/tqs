local kuangfu = fk.CreateSkill {
  name = "m_heg__kuangfu",
}

Fk:loadTranslationTable{
  ["m_heg__kuangfu"] = "狂斧",
  [":m_heg__kuangfu"] = "当你使用【杀】对目标角色造成伤害后，你可以弃置或获得其一张牌。",

  ["#m_heg__kuangfu-invoke"] = "狂斧：你可以弃置或获得 %dest 一张牌",
  ["m_heg__kuangfu_discard"] = "弃置此牌",
  ["m_heg__kuangfu_prey"] = "获得此牌",

  ["$m_heg__kuangfu1"] = "吾乃上将潘凤，可斩华雄！",
  ["$m_heg__kuangfu2"] = "这家伙，还是给我用吧！",
}

kuangfu:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuangfu.name) and
      data.card and data.card.trueName == "slash" and
      not data.to.dead and not data.to:isNude() and player.room.logic:damageByCardEffect()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = kuangfu.name,
      prompt = "#m_heg__kuangfu-invoke::"..data.to.id,
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = "he",
      skill_name = kuangfu.name,
    })
    local choice = room:askToChoice(player, {
      choices = { "m_heg__kuangfu_discard", "m_heg__kuangfu_prey" },
      skill_name = kuangfu.name,
    })
    if choice == "m_heg__kuangfu_discard" then
      room:throwCard(card, kuangfu.name, data.to, player)
    else
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, kuangfu.name, nil, false, player)
    end
  end
})

return kuangfu