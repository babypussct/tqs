local daigong = fk.CreateSkill {
  name = "daigong",
}

Fk:loadTranslationTable{
  ["daigong"] = "怠攻",
  [":daigong"] = "每回合限一次，当你受到伤害时，你可展示所有手牌令伤害来源选择一项：1.交给你一张与你以此法展示的所有牌花色均不同的牌；2.防止此伤害。",

  ["#daigong-invoke"] = "怠攻：你可以展示所有手牌，令伤害来源交给你一张花色不同的牌或防止此伤害",
  ["#daigong-give"] = "怠攻：你需交给 %src 一张花色不同的牌，否则防止此伤害",

  ["$daigong1"] = "不急，只等敌军士气渐殆。",
  ["$daigong2"] = "敌谋吾已尽料，可以长策縻之。",
}

daigong:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(daigong.name) and
      data.from and
      not player:isKongcheng() and
      player:usedSkillTimes(daigong.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = daigong.name, prompt = "#daigong-invoke" })
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = daigong.name
    local room = player.room
    room:doIndicate(player, { data.from })
    player:showCards(player:getCardIds("h"))
    if not player:isAlive() then
      return false
    end

    if not data.from:isAlive() or data.from:isNude() then
      data:preventDamage()
      return true
    end
    local suits = {}
    for _, id in ipairs(player:getCardIds("h")) do
      if Fk:getCardById(id).suit ~= Card.NoSuit then
        table.insertIfNeed(suits, Fk:getCardById(id):getSuitString())
      end
    end
    local card = room:askToCards(
      data.from,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        pattern = ".|.|^(" .. table.concat(suits, ",") .. ")",
        prompt = "#daigong-give:" .. player.id,
      }
    )
    if #card > 0 then
      room:obtainCard(player, card[1], true, fk.ReasonGive, data.from, skillName)
    else
      data:preventDamage()
    end
  end,
})

return daigong
