local paiyi = fk.CreateSkill {
  name = "ld__paiyi",
}

Fk:loadTranslationTable {
  ["ld__paiyi"] = "排异",
  [":ld__paiyi"] = "出牌阶段限一次，你可将一张“权”置入弃牌堆并选择一名角色，其摸X张牌，若其手牌数大于你，你对其造成1点伤害（X为“权”的数量且至多为7）。",

  ["#ld__paiyi-active"] = "发动排异，选择一张“权”牌置入弃牌堆并选择一名角色，令其摸 %arg 张牌",
  ["$ld__paiyi1"] = "排斥异己，为王者必由之路！",
  ["$ld__paiyi2"] = "非吾友，则必敌也！",
}

paiyi:addEffect("active", {
  anim_type = "control",
  prompt = function(self, player)
    return "#ld__paiyi-active:::" .. math.min(#player:getPile("ld__zhonghui_power") - 1, 7)
  end,
  card_num = 1,
  target_num = 1,
  expand_pile = "ld__zhonghui_power",
  can_use = function(self, player)
    return #player:getPile("ld__zhonghui_power") > 0 and player:usedSkillTimes(paiyi.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:getPileNameOfId(to_select) == "ld__zhonghui_power"
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, paiyi.name, "ld__zhonghui_power",
      true, player)
    if not target.dead then
      room:drawCards(target, math.min(#player:getPile("ld__zhonghui_power"), 7), paiyi.name)
    end
    if not player.dead and not target.dead and target:getHandcardNum() > player:getHandcardNum() then
      room:damage {
        from = player,
        to = target,
        damage = 1,
        skillName = paiyi.name,
      }
    end
  end,
})

return paiyi
