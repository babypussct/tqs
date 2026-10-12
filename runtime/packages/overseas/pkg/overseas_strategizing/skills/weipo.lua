local weipo = fk.CreateSkill {
  name = "os__weipo",
}

Fk:loadTranslationTable{
  ["os__weipo"] = "危迫",
  [":os__weipo"] = "出牌阶段限一次，你可以令一名角色弃置一张牌，其获得一张由你指定的<a href=':enemy_at_the_gates'>【兵临城下】</a>或"..
  "一种<a href='bag_of_tricks'>智囊</a>。",

  ["#os__weipo"] = "危迫：令一名角色弃置一张牌，获得你指定的智囊牌",

  ["$os__weipo1"] = "想必……将军心中已有所计较。",
  ["$os__weipo2"] = "谌言尽于此，采纳与否还凭将军。",
}

local U = require "packages.utility.utility"

local weipo_derivecards = {
  {"enemy_at_the_gates", Card.Spade, 7},
  {"enemy_at_the_gates", Card.Heart, 7},
  {"enemy_at_the_gates", Card.Club, 7},
  {"enemy_at_the_gates", Card.Diamond, 7},
}

weipo:addEffect("active", {
  anim_type = "control",
  prompt = "#os__weipo",
  times = function (self, player)
    return 1 - player:usedSkillTimes(weipo.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(weipo.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not to_select:isNude()
  end,
  interaction_helper = UI.CardNameBox{ choices = { "enemy_at_the_gates", "dismantlement", "nullification", "ex_nihilo" } },
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = weipo.name,
      cancelable = false,
    })
    if target.dead then return end
    local choice = self.interaction.data
    local card
    if choice == "enemy_at_the_gates" then
      local cids = table.filter(room:prepareDeriveCards(weipo_derivecards, weipo.name), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if #cids == 0 then
        cids = table.filter(room:prepareDeriveCards(weipo_derivecards, weipo.name), function (id)
          return table.contains(room.draw_pile, id)
        end)
      end
      if #cids > 0 then
        card = room:tableRandomPick(cids)
        room:setCardMark(Fk:getCardById(card), MarkEnum.DestructIntoDiscard, 1)
      end
    else
      card = room:getCardsFromPileByRule(choice)
    end
    if card then
      room:obtainCard(target, card, false, fk.ReasonJustMove, effect.from, weipo.name)
    end
  end,
})

return weipo
