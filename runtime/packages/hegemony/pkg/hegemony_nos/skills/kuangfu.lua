local kuangfu = fk.CreateSkill {
  name = "nos_heg__kuangfu",
}

Fk:loadTranslationTable{
  ["nos_heg__kuangfu"] = "狂斧",
  [":nos_heg__kuangfu"] = "当你使用【杀】对目标角色造成伤害后，你可以选择一项：1.弃置其装备区里的一张牌；2.将其装备区里的一张牌移至你的装备区。",

  ["#nos_heg__kuangfu-invoke"] = "狂斧：你可以弃置或移动 %dest 一张装备",
  ["nos_heg__kuangfu_discard"] = "弃置此牌",
  ["nos_heg__kuangfu_move"] = "将此牌移至你的装备区",

  ["$nos_heg__kuangfu1"] = "吾乃上将潘凤，可斩华雄！",
  ["$nos_heg__kuangfu2"] = "这家伙，还是给我用吧！",
}

kuangfu:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuangfu.name) and
      data.card and data.card.trueName == "slash" and
      not data.to.dead and #data.to:getCardIds("e") > 0 and player.room.logic:damageByCardEffect()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = kuangfu.name,
      prompt = "#nos_heg__kuangfu-invoke::"..data.to.id,
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = "e",
      skill_name = kuangfu.name,
    })
    local choices = { "nos_heg__kuangfu_discard" }
    if data.to:canMoveCardInBoardTo(player, card) then
      table.insert(choices, "nos_heg__kuangfu_move")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = kuangfu.name,
    })
    if choice == "nos_heg__kuangfu_discard" then
      room:throwCard(card, kuangfu.name, data.to, player)
    else
      room:moveCardIntoEquip(player, card, kuangfu.name, true, player)
    end
  end
})

return kuangfu