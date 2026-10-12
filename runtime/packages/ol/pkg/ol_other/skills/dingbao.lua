local dingbao = fk.CreateSkill {
  name = "dingbao",
  tags = { Skill.Limited, },
}

Fk:loadTranslationTable {
  ["dingbao"] = "定宝",
  [":dingbao"] = "限定技，出牌阶段，你可以直接完成一次“摸金”并结束此阶段。",

  ["#dingbao"] = "定宝：直接完成“摸金”并结束此阶段！",

  ["$dingbao1"] = "好宝贝，商周的，九成九新稀罕物！",
  ["$dingbao2"] = "挖着了，挖着了！一等一的稀世珍宝！",
}

dingbao:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#dingbao",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:getMark("@mojin") ~= 0 and player:usedSkillTimes(dingbao.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:setPlayerMark(player, "@mojin", 0)
    local rewards = Fk.skill_skels["mojin"].rewards
    local card, names, name = nil, {}, ""
    if math.random() < 0.5 then
      for n, _ in pairs(rewards) do
        table.insert(names, n)
      end
      name = room:tableRandomPick(names)
      card = room:printCard(name, rewards[name][1], rewards[name][2])
    else
      for _, c in ipairs(Fk.cards) do
        if (c.package.name == "standard" or c.package.name == "maneuvering") and
          c.type == Card.TypeTrick then
          table.insertIfNeed(names, c.name)
        end
      end
      table.removeOne(names, "lighting")
      table.insertTable(names, { "jink", "peach", "thunder__slash", "fire__slash", "ice__slash" })
      name = room:tableRandomPick(names)
      card = room:printCard(room:tableRandomPick(names), math.random(1, 4), math.random(1, 13))
      room:setCardMark(card, MarkEnum.DestructIntoDiscard, 1)
      if table.contains({"peach", "analeptic"}, name) then
        room:setCardMark(card, "@@mojin_recover", 1)
      else
        room:setCardMark(card, "@@mojin_disresponsive", 1)
      end
    end
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, "mojin", nil, false, player)
    if player.dead then return end

    local choices = {}
    for i = 1, 15 do
      table.insert(choices, "mojin_choice"..i)
    end
    local choice = room:askToChoice(player, {
      choices = room:tableRandomPick(choices, 3),
      skill_name = "mojin",
    })
    room:setPlayerMark(player, "@mojin", choice)
    player:endPlayPhase()
  end,
})

return dingbao
