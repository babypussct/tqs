local jinfan = fk.CreateSkill {
  name = "jinfan",
  derived_piles = "jinfan_ling",
}

Fk:loadTranslationTable{
  ["jinfan"] = "锦帆",
  [":jinfan"] = "弃牌阶段开始时，你可以将任意张手牌置于武将牌上，称为“铃”（每种花色限一张），你可以将“铃”如手牌般使用或打出；"..
  "当“铃”离开你的武将牌时，你从牌堆获得一张同花色的牌。",

  ["jinfan_ling"] = "铃",
  ["#jinfan-invoke"] = "锦帆：你可以将任意张手牌置为“铃”",

  ["$jinfan1"] = "扬锦帆，劫四方，快意逍遥！",
  ["$jinfan2"] = "铃声所至之处，再无安宁！",
}

jinfan:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jinfan.name) and player.phase == Player.Discard and not player:isKongcheng() and
      #player:getPile("jinfan_ling") < 4
  end,
  on_cost = function (self, event, target, player, data)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "jinfan_active",
      prompt = "#jinfan-invoke",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player:addToPile("jinfan_ling", event:getCostData(self).cards, true, jinfan.name)
  end,
})
jinfan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(jinfan.name) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromSpecialName == "jinfan_ling" then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local suits = {}
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromSpecialName == "jinfan_ling" then
            table.insertIfNeed(suits, Fk:getCardById(info.cardId):getSuitString())
          end
        end
      end
    end
    for _, suit in ipairs(suits) do
      if player.dead then return end
      local cards = room:getCardsFromPileByRule(".|.|"..suit)
      if #cards > 0 then
        room:obtainCard(player, cards[1], false, fk.ReasonJustMove, player, jinfan.name)
      end
    end
  end,
})

jinfan:addEffect("filter", {
  handly_cards = function (self, player)
    if player:hasSkill(jinfan.name) then
      return player:getPile("jinfan_ling")
    end
  end,
})

return jinfan
