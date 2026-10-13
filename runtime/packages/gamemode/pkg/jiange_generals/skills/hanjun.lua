local hanjun = fk.CreateSkill({
  name = "jiange__hanjun",
})

Fk:loadTranslationTable{
  ["jiange__hanjun"] = "撼军",
  [":jiange__hanjun"] = "出牌阶段限一次，你可以随机弃置所有敌方角色各一张牌，然后你可以选择获得其中的装备牌或非装备牌。",

  ["#jiange__hanjun"] = "撼军：随机弃置所有敌方各一张牌，然后你获得其中的装备牌或非装备牌",
  ["#jiange__hanjun-prey"] = "撼军：你可以获得其中的装备牌或非装备牌",
  ["jiange__hanjun_non_equip"] = "非装备牌",
}

local U = require "packages.utility.utility"

hanjun:addEffect("active", {
  anim_type = "control",
  prompt = "#jiange__hanjun",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(hanjun.name, Player.HistoryPhase) == 0 and #player:getEnemies() > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = player:getEnemies()
    room:sortByAction(targets)
    room:doIndicate(player, targets)
    local all_cards = {}
    for _, target in ipairs(targets) do
      if not target.dead and not target:isNude() then
        local id = room:tableRandomPick(target:getCardIds("he"))
        table.insert(all_cards, id)
        room:throwCard(id, hanjun.name, target, player)
      end
    end
    all_cards = table.filter(all_cards, function(id)
      return table.contains(room.discard_pile, id)
    end)
    if player.dead or #all_cards == 0 then return end
    local listNames = { "equip", "jiange__hanjun_non_equip" }
    local listCards = { {}, {} }
    for _, id in ipairs(all_cards) do
      local type = Fk:getCardById(id).type
      if type == Card.TypeEquip then
        table.insert(listCards[1], id)
      else
        table.insert(listCards[2], id)
      end
    end
    local choice = U.askForChooseCardList(room, player, listNames, listCards, 1, 1, hanjun.name, "#jiange__hanjun-prey")
    if #choice > 0 then
      if choice[1] == "equip" then
        room:moveCardTo(listCards[1], Card.PlayerHand, player, fk.ReasonJustMove, hanjun.name, nil, true, player)
      else
        room:moveCardTo(listCards[2], Card.PlayerHand, player, fk.ReasonJustMove, hanjun.name, nil, true, player)
      end
    end
  end,
})

return hanjun
