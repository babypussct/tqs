local shenli = fk.CreateSkill{
  name = "shenliy",
}

Fk:loadTranslationTable{
  ["shenliy"] = "神离",
  [":shenliy"] = "出牌阶段限一次，你使用【杀】指定目标后，可令所有其他角色均成为此【杀】的目标。然后若此【杀】造成的伤害值：<br>"..
    "⬤大于你的手牌数，你摸X张牌（X为此【杀】造成的伤害值且至多为5）；<br>"..
    "⬤大于你的体力值，你对相同目标再次使用此【杀】。",

  ["#shenliy-invoke"] = "神离：是否选择所有其他角色成为此%arg的目标？",

  ["$shenliy1"] = "沧海之水难覆，将倾之厦难扶。",
  ["$shenliy2"] = "诸君心怀苟且，安能并力西向？",
  ["$shenliy3"] = "联军离心，各逐其利。",
  ["$shenliy4"] = "什么国恩大义，不过弊履而已！",
  ["$shenliy5"] = "本盟主的话，你听还是不听？",
  ["$shenliy6"] = "尔等皆为墙头草，随风而摆。",
}

shenli:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shenli.name) and data.card.trueName == "slash" and
      player.phase == Player.Play and player:usedSkillTimes(shenli.name, Player.HistoryPhase) == 0 and
      #data:getExtraTargets({bypass_distances = true}) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(target, {
      skill_name = shenli.name,
      prompt = "#shenliy-invoke:::"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = data:getExtraTargets({bypass_distances = true})})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos ---@type ServerPlayer[]
    room:sendLog{
      type = "#AddTargetsBySkill",
      from = player.id,
      to = table.map(tos, Util.IdMapper),
      arg = shenli.name,
      arg2 = data.card:toLogString()
    }
    data:addTarget(tos)
    data.extra_data = data.extra_data or {}
    data.extra_data.shenliy = player
  end,
})
shenli:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shenli.name) and data.damageDealt and data.extra_data and data.extra_data.shenliy == player then
      local n = 0
      for _, damage in pairs(data.damageDealt) do
        n = n + damage
      end
      if n > player:getHandcardNum() or n > player.hp then
        event:setCostData(self, {extra_data = n})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).extra_data
    if n > player:getHandcardNum() then
      player:drawCards(math.min(n, 5), shenli.name)
      if player.dead then return end
    end
    if n > player.hp then
      local cardlist = Card:getIdList(data.card)
      if #cardlist == 0 or table.every(cardlist, function (id)
        return room:getCardArea(id) == Card.Processing
      end) then
        local card
        if #cardlist == 1 and Fk:getCardById(cardlist[1]).trueName == "slash" then
          card = Fk:getCardById(cardlist[1])
        else
          card = Fk:cloneCard(data.card.name)
          card:addSubcards(cardlist)
          card.skillName = shenli.name
        end
        if player:prohibitUse(card) then return end
        local targets = table.filter(data.tos, function (p)
          return not (p.dead or player:isProhibited(p, card))
        end)
        if #targets > 0 then
          room:useCard{
            from = player,
            tos = targets,
            card = card,
            extraUse = true,
          }
        end
      end
    end
  end,
})

return shenli
