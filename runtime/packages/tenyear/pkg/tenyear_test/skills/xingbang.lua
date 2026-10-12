
local xingbang = fk.CreateSkill {
  name = "xingbang",
}

Fk:loadTranslationTable {
  ["xingbang"] = "兴邦",
  [":xingbang"] = "出牌阶段限一次，你可以摸一张牌并交给一名其他角色一张牌。然后你获得其一张手牌，若此牌："..
  "是你交给该角色的牌，视为对其使用一张【杀】；不是你交给该角色的牌，重复获得牌的流程（至多获得三张）。",

  ["#xingbang"] = "兴邦：你可以摸一张牌，交给一名其他角色一张牌，再获得其一张手牌",
  ["#xingbang-give"] = "兴邦：请交给一名其他角色一张牌",
  ["#xingbang-prey"] = "兴邦：获得 %dest 一张手牌，根据是否为你交给其的牌执行效果",

  ["$xingbang1"] = "",
  ["$xingbang2"] = "",
}

xingbang:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#xingbang",
  card_num = 0,
  target_num = 0,
  times = function(self, player)
    return player.phase == Player.Play and player:getMark("@@fanhuo-turn") > 0 and
      3 - player:usedSkillTimes(xingbang.name, Player.HistoryPhase) or -1
  end,
  can_use = function (self, player)
    return player:usedSkillTimes(xingbang.name, Player.HistoryPhase) < (player:getMark("@@fanhuo-turn") > 0 and 3 or 1)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    player:drawCards(1, xingbang.name)
    if player:isNude() or #room:getOtherPlayers(player, false) == 0 then return end
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".",
      skill_name = xingbang.name,
      prompt = "#xingbang-give",
      cancelable = false,
    })
    to = to[1]
    room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, xingbang.name, nil, false, player)
    for _ = 1, 3 do
      if player.dead or to:isKongcheng() then return end
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "h",
        skill_name = xingbang.name,
        prompt = "#xingbang-prey::"..to.id,
      })
      room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, xingbang.name, nil, false, player)
      if id == card[1] then
        if not to.dead then
          room:useVirtualCard("slash", {}, player, to, xingbang.name, true)
        end
        return
      end
    end
  end,
})

return xingbang
