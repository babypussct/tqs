local weisi = fk.CreateSkill {
  name = "mobile__weisi",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = {"qun"},
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "mobile__weisi_1v2"
    else
      return "mobile__weisi_role_mode"
    end
  end,
}

Fk:loadTranslationTable{
  ["mobile__weisi"] = "威肆",
  [":mobile__weisi"] = "群势力技，出牌阶段限一次，你可以选择一名其他角色，令其将任意张手牌移出游戏直到回合结束，然后视为对其使用一张【决斗】，"..
  "此牌对其造成伤害后，你获得其所有手牌（若为斗地主模式，所有改为一张）。",

  [":mobile__weisi_role_mode"] = "群势力技，出牌阶段限一次，你可以选择一名其他角色，令其将任意张手牌移出游戏直到回合结束，"..
  "然后视为对其使用一张【决斗】，此牌对其造成伤害后，你获得其所有手牌。",
  [":mobile__weisi_1v2"] = "群势力技，出牌阶段限一次，你可以选择一名其他角色，令其将任意张手牌移出游戏直到回合结束，然后视为对其使用一张【决斗】，"..
  "此牌对其造成伤害后，你获得其一张手牌。",

  ["#mobile__weisi"] = "威肆：令一名角色将任意张手牌移出游戏直到回合结束，然后视为对其使用【决斗】！",
  ["#mobile__weisi-ask"] = "威肆：%src 将对你使用【决斗】！请将任意张手牌本回合移出游戏，【决斗】对你造成伤害后其获得你手牌！",
  ["$mobile__weisi"] = "威肆",

  ["$mobile__weisi1"] = "城破之日，定诛此逆贼三族！",
  ["$mobile__weisi2"] = "平叛淮南，吾司马氏当再立不世之功！",
  ["$mobile__weisi3"] = "众将平乱所获，皆为陛下所赐！", --威肆（获得手牌）
}

weisi:addEffect("active", {
  mute = true,
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__weisi",
  can_use = function(self, player)
    return player:usedSkillTimes(weisi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:broadcastSkillInvoke(weisi.name, math.random(1, 2))
    room:notifySkillInvoked(player, weisi.name, "offensive")
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = weisi.name,
      prompt = "#mobile__weisi-ask:"..player.id,
      cancelable = true,
    })
    if #cards > 0 then
      target:addToPile("$mobile__weisi", cards, false, weisi.name, target)
    end
    if player.dead or target.dead then return end
    room:useVirtualCard("duel", nil, player, target, weisi.name)
  end,
})

weisi:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.room.logic:damageByCardEffect() and
      data.card and table.contains(data.card.skillNames, weisi.name) and
      not data.to:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = data.to:getCardIds("h")
    if room:isGameMode("1v2_mode") then
      cards = room:tableRandomPick(cards, 1)
    end
    player:broadcastSkillInvoke(weisi.name, 3)
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, weisi.name, nil, false, player)
  end,
})

weisi:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("$mobile__weisi") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("$mobile__weisi"), Card.PlayerHand, player, fk.ReasonJustMove, weisi.name, nil, false, player)
  end,
})

weisi:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local targets, benefit = ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 0,
      max_num = 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        logic:useCard({
          from = ai.player,
          tos = { p },
          card = Fk:cloneCard("duel"),
        })
        logic:moveCardTo(p:getCardIds("h")[1], Card.PlayerHand, ai.player, fk.ReasonPrey, self.skill_name, nil, false, ai.player)
      end,
    })
    if #targets > 0 then
      return { { }, targets }, benefit
    end
  end,
})

return weisi
