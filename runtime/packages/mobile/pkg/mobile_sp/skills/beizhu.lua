local beizhu = fk.CreateSkill {
  name = "beizhu",
}

Fk:loadTranslationTable{
  ["beizhu"] = "备诛",
  [":beizhu"] = "出牌阶段限一次，你可以观看一名其他角色的手牌。若其中有【杀】，则其对你依次使用这些【杀】（当你受到因此使用的【杀】造成的伤害后，"..
  "你摸一张牌），否则你弃置其一张牌并可以令其从牌堆中获得一张【杀】。",

  ["#beizhu-draw"] = "备诛：你可令 %src 从牌堆中获得一张【杀】",
  ["#beizhu-throw"] = "备诛：请弃置 %src 一张牌",
  ["#beizhu-prompt"] = "备诛：你可以观看其他角色的手牌，若有【杀】，其对你使用【杀】；否则你弃置其牌",

  ["$beizhu1"] = "检阅士卒，备将行之役。",
  ["$beizhu2"] = "点选将校，讨乱汉之贼。",
  ["$beizhu3"] = "乱贼势大，且暂勿力战。",
}

beizhu:addEffect("active", {
  mute = true,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  prompt = "#beizhu-prompt",
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(beizhu.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = beizhu.name
    local player = effect.from
    local target = effect.tos[1]
    room:notifySkillInvoked(player, skillName, "control")
    player:broadcastSkillInvoke(skillName, math.random(2))
    target:filterHandcards()
    local ids = table.filter(target:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == "slash" end)
    if #ids > 0 then
      room:viewCards(player, { cards = target:getCardIds("h"), skill_name = skillName, prompt = "$ViewCardsFrom:" .. target.id })
      room:setPlayerMark(player, "beizhu_slash", ids)
      for _, id in ipairs(ids) do
        local card = Fk:getCardById(id)
        if
          room:getCardOwner(id) == target and
          room:getCardArea(id) == Card.PlayerHand and
          card.trueName == "slash" and
          player:isAlive() and
          not target:isProhibited(player, card) and
          not target:prohibitUse(card)
        then
          room:useCard({
            from = target,
            tos = { player },
            card = card,
            extra_data = { beizhu_from = player.id },
            extraUse = true,
          })
        end
      end
    else
      local card_data = {}
      table.insert(card_data, { "$Hand", target:getCardIds("h") })
      if #target:getCardIds("e") > 0 then
        table.insert(card_data, { "$Equip", target:getCardIds("e") })
      end
      local throw = room:askToChooseCard(
        player,
        {
          target = target,
          flag = { card_data = card_data },
          skill_name = skillName,
          prompt = "#beizhu-throw:" .. target.id
        }
      )
      room:throwCard(throw, skillName, target, player)
      local slash = room:getCardsFromPileByRule("slash")
      if
        #slash > 0 and
        target:isAlive() and
        player:isAlive() and
        room:askToSkillInvoke(player, { skill_name = skillName, prompt = "#beizhu-draw:" .. target.id })
      then
        room:obtainCard(target, slash[1], true, fk.ReasonJustMove, target, skillName)
      end
    end
  end,
})

beizhu:addEffect(fk.Damaged, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:isAlive() and data.card then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data
        return use.card == data.card and use.extra_data and use.extra_data.beizhu_from == player.id
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, _, player, data)
    ---@type string
    local skillName = beizhu.name
    player:broadcastSkillInvoke(skillName, 3)
    player:drawCards(1, skillName)
  end,
})

return beizhu
