local difei = fk.CreateSkill {
  name = "difei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["difei"] = "抵诽",
  [":difei"] = "锁定技，每回合限一次，当你受到伤害后，你摸一张牌或弃置一张手牌，然后你展示所有手牌，若对你造成伤害的牌无花色或"..
  "你的手牌中没有与对你造成伤害的牌花色相同的牌，你回复1点体力。",

  ["#difei-discard"] = "抵诽：弃置一张手牌，或点“取消”摸一张牌",
  ["#difei-discard-recover1"] = "抵诽：弃置一张手牌，或点“取消”摸一张牌，然后展示所有手牌并回复1点体力",
  ["#difei-discard-recover2"] = "抵诽：弃置一张手牌，或点“取消”摸一张牌，然后展示所有手牌，若其中没有%arg牌则回复1点体力",

  ["$difei1"] = "称病不见，待其自露马脚。",
  ["$difei2"] = "孙氏之诽，伤不到我分毫。",
}

difei:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(difei.name) and
      player:usedSkillTimes(difei.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#difei-discard"
    if data.card then
      if data.card.suit == Card.NoSuit then
        prompt = prompt.."-recover1"
      else
        prompt = prompt.."-recover2:::" .. data.card:getSuitString(true)
      end
    end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = difei.name,
      cancelable = true,
      prompt = prompt,
    })
    if #card == 0 then
      player:drawCards(1, difei.name)
    end
    if player.dead or player:isKongcheng() then return end
    player:showCards(player:getCardIds("h"))
    if player:isWounded() and not player.dead and data.card and
      (data.card.suit == Card.NoSuit or
      not table.find(player:getCardIds("h"), function (id)
        return data.card:compareSuitWith(Fk:getCardById(id))
      end)) then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = difei.name
      }
    end
  end,
})

return difei
