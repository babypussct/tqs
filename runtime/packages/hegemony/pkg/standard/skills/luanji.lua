
local luanji = fk.CreateSkill{
  name = "hs__luanji",
}
local H = require "packages.hegemony.util"
luanji:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "archery_attack",
  card_filter = function(self, player, to_select, selected)
    if #selected == 2 or Fk:currentRoom():getCardArea(to_select) ~= Player.Hand then return false end
    local record = player:getTableMark("@hs__luanji-turn")
    return not table.contains(record, Fk:getCardById(to_select):getSuitString(true))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 then
      return nil
    end
    local c = Fk:cloneCard("archery_attack")
    c.skillName = luanji.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    local record = player:getTableMark("@hs__luanji-turn")
    local cards = use.card.subcards
    for _, cid in ipairs(cards) do
      local suit = Fk:getCardById(cid):getSuitString(true)
      if suit ~= "log_nosuit" then table.insertIfNeed(record, suit) end
    end
    room:setPlayerMark(player, "@hs__luanji-turn", record)
  end
})
luanji:addEffect(fk.CardRespondFinished, {
  anim_type = "drawcard",
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or data.card.name ~= "jink" or player.dead then return false end
    if data.responseToEvent and table.contains(data.responseToEvent.card.skillNames, luanji.name) then
      local yuanshao = data.responseToEvent.from
      if yuanshao and H.compareKingdomWith(player, yuanshao) then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = luanji.name,
      prompt = "#hs__luanji-draw",
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, luanji.name)
  end,
})

-- Pick two legal cards while respecting the once-per-suit-per-turn mark. The
-- Archery Attack has fixed all-other-player targets, so the benefit model
-- decides whether the damage to public enemies outweighs collateral risk to
-- allies/uncertain seats.
luanji:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local skill = Fk.skills[self.skill_name]
    local player = ai.player
    local used = {}
    for _, suit in ipairs(player:getTableMark("@hs__luanji-turn")) do used[suit] = true end

    local cards = ai:getEnabledCards()
    local best, best_value = nil, -100000
    for i = 1, #cards do
      local first = cards[i]
      local first_card = Fk:getCardById(first)
      local first_suit = first_card and first_card:getSuitString(true)
      if first_card and (first_suit == "log_nosuit" or not used[first_suit]) then
        for j = i + 1, #cards do
          local second = cards[j]
          local second_card = Fk:getCardById(second)
          local second_suit = second_card and second_card:getSuitString(true)
          if second_card and (second_suit == "log_nosuit" or not used[second_suit]) then
            ai:selectSkill(self.skill_name, true)
            ai:selectCard(first, true)
            ai:selectCard(second, true)
            local card = skill:viewAs(player, { first, second })
            if card then
              local targets = card:getDefaultTarget(player, ai.data and ai.data[5] or {})
              local value = ai:getBenefitOfEvents(function(logic)
                logic:useCard{ from = player, tos = targets, card = card }
              end)
              value = value - (ai:getCardValue(first, "keep_value") or 0) * 12
              value = value - (ai:getCardValue(second, "keep_value") or 0) * 12
              if #targets > 0 and value > best_value then
                best, best_value = { { first, second }, targets }, value
              end
            end
            ai:unSelectAll()
          end
        end
      end
    end

    if best and best_value > 0 then return best, best_value end
  end,
})

luanji:addAI(Fk.Ltk.AI.newInvokeStrategy {
  think = function(self, ai)
    -- The response-side draw has no card/HP cost.  Keep the decision bounded
    -- by hand capacity instead of invoking blindly when already full.
    local player = ai.player
    return player:getHandcardNum() < player.maxHp
  end,
})

Fk:loadTranslationTable{
  ["hs__luanji"] = "乱击",
  [":hs__luanji"] = "你可将两张手牌当【万箭齐发】使用（不能使用此回合以此法使用过的花色），当与你势力相同的角色打出【闪】响应此牌结算结束后，其可摸一张牌。",

  ["@hs__luanji-turn"] = "乱击",
  ["#hs__luanji-draw"] = "乱击：你可摸一张牌",

  ["$hs__luanji1"] = "弓箭手，准备放箭！",
  ["$hs__luanji2"] = "全都去死吧！",
}

return luanji
