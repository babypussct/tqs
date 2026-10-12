local zhongjian = fk.CreateSkill{
  name = "ol_ex__zhongjian",
}

Fk:loadTranslationTable{
  ["ol_ex__zhongjian"] = "忠鉴",
  [":ol_ex__zhongjian"] = "出牌阶段限一次，你可以展示一名其他角色X张手牌（X为其体力值），然后你展示一张手牌。若其展示的牌包含：<br>"..
  "与你展示牌颜色相同的牌，你摸一张牌或弃置其一张牌；<br>与你展示牌牌名相同的牌，本阶段此技能改为“出牌阶段限两次”。",

  ["#ol_ex__zhongjian"] = "忠鉴：展示一名角色其体力值张数的手牌，然后你展示一张手牌",
  ["#ol_ex__zhongjian-show"] = "忠鉴：请展示一张手牌，若有颜色相同则摸牌或弃牌，若有牌名相同则改为限两次",
  ["#ol_ex__zhongjian-choice"] = "忠鉴：弃置 %dest 一张牌，或点“取消”摸一张牌",

  ["$ol_ex__zhongjian1"] = "见微知著，观其行可窥其心。",
  ["$ol_ex__zhongjian2"] = "一叶知秋，查其言而觉其志。",
}

zhongjian:addEffect("active", {
  anim_type = "control",
  prompt = "#ol_ex__zhongjian",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhongjian.name, Player.HistoryPhase) < (1 + player:getMark("ol_ex__zhongjian_times-phase"))
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and
      to_select.hp > 0 and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = math.min(target:getHandcardNum(), target.hp)
    local cards = room:askToChooseCards(player, {
      target = target,
      min = n,
      max = n,
      flag = "h",
      skill_name = zhongjian.name,
    })
    target:showCards(cards)
    if player.dead or player:isKongcheng() then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = zhongjian.name,
      cancelable = false,
      prompt = "#ol_ex__zhongjian-show",
    })[1]
    player:showCards(card)
    if player.dead then return end
    if table.find(cards, function(id)
      return Fk:getCardById(id).trueName == Fk:getCardById(card).trueName
    end) then
      room:setPlayerMark(player, "ol_ex__zhongjian_times-phase", 1)
    end
    if table.find(cards, function(id)
      return Fk:getCardById(id):compareColorWith(Fk:getCardById(card))
    end) then
      if target.dead or target:isNude() or
        not room:askToSkillInvoke(player, {
          skill_name = zhongjian.name,
          prompt = "#ol_ex__zhongjian-choice::"..target.id,
        }) then
        player:drawCards(1, zhongjian.name)
      else
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = zhongjian.name,
        })
        room:throwCard(id, zhongjian.name, target, player)
      end
    end
  end,
})

return zhongjian
