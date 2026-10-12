local qinghan = fk.CreateSkill {
  name = "os__qinghan"
}

Fk:loadTranslationTable{
  ["os__qinghan"] = "擎汉",
  [":os__qinghan"] = "出牌阶段限一次，你可以用一张装备牌与一名角色拼点：若你赢，你可视为对其使用一张以其为唯一目标的普通锦囊牌；" ..
  "若你没赢，你获得所有拼点牌。",

  ["#os__qinghan"] = "擎汉：你可以用一张装备牌与一名角色拼点，若赢，视为对其使用锦囊牌",
  ["#os__qinghan-use"] = "擎汉：你可以视为对 %dest 使用一张普通锦囊牌",

  ["$os__qinghan1"] = "二十四代终未竟，今以一隅誓还天！",
  ["$os__qinghan2"] = "维继丞相遗托，当负擎汉之重。",
}

local U = require "packages.utility.utility"

qinghan:addEffect("active", {
  anim_type = "control",
  prompt = "#os__qinghan",
  card_num = 1,
  target_num = 1,
  can_use = function (self, player)
    return player:usedSkillTimes(qinghan.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected_cards == 1 and player:canPindian(to_select, true)
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, qinghan.name, Fk:getCardById(effect.cards[1]))
    if pindian.results[target].winner == player and not player.dead and not target.dead then
      local names = table.filter(Fk:getAllCardNames("t"), function (name)
        local card = Fk.all_card_types[name]
        return player:canUseTo(card, target, {bypass_distances = true, bypass_times = true, extraUse = true})
      end)
      if #names > 0 then
        room:askToUseVirtualCard(player, {
          name = names,
          skill_name = qinghan.name,
          prompt = "#os__qinghan-use::"..target.id,
          extra_data = {
            bypass_distances = true,
            bypass_times = true,
            extraUse = true,
            exclusive_targets = {target.id},
          },
        })
      end
    end
    if pindian.results[target].winner ~= player and not player.dead then
      room:delay(1000)
      local cards = {}
      if pindian.results[target].toCard then
        table.insert(cards, room:getSubcardsByRule(pindian.results[target].toCard, {Card.DiscardPile}))
      end
      if pindian.fromCard then
        table.insert(cards, room:getSubcardsByRule(pindian.fromCard, {Card.DiscardPile}))
      end
      if #cards > 0 then
        room:obtainCard(player, cards, nil, fk.ReasonPrey, player, qinghan.name)
      end
    end
  end,
})


return qinghan
