local quanqian = fk.CreateSkill {
  name = "os__quanqian",
  tags = { Skill.Spirited },
}

Fk:loadTranslationTable {
  ["os__quanqian"] = "劝迁",
  [":os__quanqian"] = "<a href='#SpiritedSkillDesc'>昂扬技</a>，其他角色摸牌阶段结束时，" ..
      "你可以将手牌摸至等同于场上手牌数最多的角色（至多摸五张），然后你可以交给当前回合角色任意张牌，你以此法给出的牌：" ..
      "每有一种类别，你摸一张牌；每有一种花色，其本回合使用【杀】次数+1。" ..
      "<a href='#SpiritedSkillDesc'>激昂</a>：累计X名目标角色未受到以其为目标的伤害类牌造成的伤害（X为你上次发动此技能交出的牌数，至少为1）。",

  ["@os__quanqian"] = "劝迁",
  ["#os__quanqian-invoke"] = "劝迁：你可以摸%arg张牌，然后交给 %dest 任意张牌",
  ["#os__quanqian-invoke_nodraw"] = "劝迁：你可以发动此技能，然后交给 %dest 任意张牌",
  ["#os__quanqian-give"] = "劝迁：交给 %dest 任意张牌，每交出一种类别你摸一张牌，每交出一种花色其本回合使用【杀】次数+1",

  ["$os__quanqian1"] = "欲承奕世之基，当迁龙兴之地。",
  ["$os__quanqian2"] = "吴郡僻远，宜迁都秣陵，以承王业。",
}

quanqian:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(quanqian.name) and
      target ~= player and
      target.phase == Player.Draw and
      player:getMark("@os__quanqian") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum()
    for _, p in ipairs(room.alive_players) do
      n = math.max(p:getHandcardNum(), n)
    end
    n = math.min(n - player:getHandcardNum(), 5)

    local prompt = "#os__quanqian-invoke::" .. target.id .. ":" .. n
    if n < 1 then
      prompt = "#os__quanqian-invoke_nodraw::" .. target.id
    end

    if room:askToSkillInvoke(player, {
      skill_name = quanqian.name,
      prompt = prompt,
    }) then
      event:setCostData(self, { choice = n })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).choice
    player:drawCards(n, quanqian.name)
    if player.dead then return end
    if target.dead or player:isNude() then
      room:setPlayerMark(player, "@os__quanqian", 1)
      return
    end
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = quanqian.name,
      prompt = "#os__quanqian-give::" .. target.id,
      cancelable = true,
    })
    if #cards == 0 then
      room:setPlayerMark(player, "@os__quanqian", 1)
      return
    else
      local n1, n2 = {}, {}
      for _, id in ipairs(cards) do
        local card = Fk:getCardById(id)
        table.insertIfNeed(n1, card.type)
        table.insertIfNeed(n2, card.suit)
      end
      table.removeOne(n2, Card.NoSuit)
      room:addPlayerMark(target, MarkEnum.SlashResidue .. "-turn", #n2)
      room:obtainCard(target, cards, false, fk.ReasonGive, player, quanqian.name)
      if not player.dead then
        player:drawCards(#n1, quanqian.name)
        if not player.dead then
          room:setPlayerMark(player, "@os__quanqian", #cards)
        end
      end
    end
  end,
})

quanqian:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__quanqian") > 0 and data.card.is_damage_card
  end,
  on_refresh = function(self, event, target, player, data)
    for _, p in ipairs(data.tos) do
      if not (data.damageDealt and data.damageDealt[p]) then
        player.room:removePlayerMark(player, "@os__quanqian", 1)
      end
    end
  end,
})

quanqian:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@os__quanqian", 0)
end)

return quanqian
