local zhengjing = fk.CreateSkill {
  name = "zhengjing",
}

Fk:loadTranslationTable{
  ["zhengjing"] = "整经",
  [":zhengjing"] = "出牌阶段限一次，你可以整理一次经典，并将你整理出的任意牌置于一名角色的武将牌上，称为“经”，然后你获得剩余的牌。"..
  "武将牌上有“经”的角色准备阶段，其获得所有“经”，然后跳过本回合的判定阶段和摸牌阶段。",

  ["#zhengjing"] = "整经：开始整理经典！",
  ["bomb"] = "炸弹",
  ["#zhengjing_choice"] = "整理经典！",
  ["#ZhengjingChoice"] = "%from 整理出了 %arg",
  ["#zhengjing-give"] = "整经：你可以将整理出的牌置为一名角色的“经”",
  ["$zhengxuan_jing"] = "经",

  ["$zhengjing1"] = "兼采今古，博学并蓄，择善以教之。",
  ["$zhengjing2"] = "君子需通六艺，亦当识明三礼。",
  ["$zhengjing3"] = "关关雎鸠，在河之洲",
  ["$zhengjing4"] = "窈窕淑女，君子好逑",
  ["$zhengjing5"] = "参差荇菜，左右流之",
  ["$zhengjing6"] = "窈窕淑女，寤寐求之",
  ["$zhengjing7"] = "蒹葭苍苍，白露为霜",
  ["$zhengjing8"] = "所谓伊人，在水一方",
  ["$zhengjing9"] = "溯游从之，道阻且长",
  ["$zhengjing10"] = "溯洄从之，宛在水中央",
  ["$zhengjing11"] = "淇则有岸，隰则有泮",
  ["$zhengjing12"] = "总角之宴，言笑晏晏",
  ["$zhengjing13"] = "信誓旦旦，不思其反",
  ["$zhengjing14"] = "反是不思，亦已焉哉",
}

zhengjing:addEffect("active", {
  mute = true,
  card_num = 0,
  target_num = 0,
  prompt = "#zhengjing",
  can_use = function(self, player)
    return player:usedSkillTimes(zhengjing.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:notifySkillInvoked(player, zhengjing.name, "drawcard")
    player:broadcastSkillInvoke(zhengjing.name, math.random(1, 2))
    local basics = {}
    local equips = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeEquip then
        table.insertIfNeed(equips, card.name)
      else
        table.insertIfNeed(basics, card.name)
      end
    end
    local random = math.random()
    local n = 5
    if random < 0.3 then
      n = 4
      if random < 0.1 then
        n = 3
      end
    end
    if #basics == 0 and #equips == 0 then return end
    local all_choices = {}
    if #equips > 0 and math.random() < 0.5 then  --至多只出现一个装备
      all_choices = {room:tableRandomPick(equips)}
    end
    table.insertTable(all_choices, room:tableRandomPick(basics, n - #all_choices))
    table.insert(all_choices, "bomb")
    room:delay(2000)
    local patterns = {}
    local audio = room:tableRandomPick({{3, 4, 5, 6}, {7, 8, 9, 10}, {11, 12, 13, 14}})
    for i = 1, math.random(n, 2 * n), 1 do
      player:broadcastSkillInvoke(zhengjing.name, i % 4 == 0 and audio[4] or audio[i % 4])
      local choices = room:tableRandomPick(all_choices, math.random(math.min(3, #all_choices), #all_choices))
      room:shuffleTable(choices)
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = zhengjing.name,
        prompt = "#zhengjing_choice",
      })
      room:sendLog{
        type = "#ZhengjingChoice",
        from = player.id,
        arg = choice,
        toast = true,
      }
      table.insertIfNeed(patterns, choice)
      if choice == "bomb" then
        break
      end
    end
    if #patterns == 0 or table.contains(patterns, "bomb") then return end
    local cards = {}
    for _, pattern in ipairs(patterns) do
      table.insertTable(cards, room:getCardsFromPileByRule(pattern))
    end
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonJustMove, zhengjing.name, nil, true, player)
    local tos, ids = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = #cards,
      targets = room.alive_players,
      pattern = tostring(Exppattern{ id = cards }),
      skill_name = zhengjing.name,
      prompt = "#zhengjing-give",
      cancelable = true,
      expand_pile = cards,
    })
    if #tos > 0 and #ids > 0 then
      tos[1]:addToPile("$zhengxuan_jing", ids, false, zhengjing.name)
    end
    cards = table.filter(cards, function(id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards > 0 and not player.dead then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, zhengjing.name, nil, true, player)
    end
  end,
})

zhengjing:addEffect(fk.EventPhaseStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and #player:getPile("$zhengxuan_jing") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:skip(Player.Judge)
    player:skip(Player.Draw)
    room:moveCardTo(player:getPile("$zhengxuan_jing"), Card.PlayerHand, player, fk.ReasonPrey, "zhengjing", nil, false, player)
  end,
})

zhengjing:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    return { {}, {} }, ai:getBenefitOfEvents(function(logic)
      logic:drawCards(ai.player, 2)
    end)
  end,
})

return zhengjing
