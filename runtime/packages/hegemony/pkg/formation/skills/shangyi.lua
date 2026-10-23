local shangyi = fk.CreateSkill{
  name = "shangyi",
}

Fk:loadTranslationTable{
  ["shangyi"] = "尚义",
  [":shangyi"] = "出牌阶段限一次，你可以令一名其他角色观看你的手牌，然后你选择一项：1.观看其手牌，然后可以弃置其中一张黑色牌；"..
  "2.观看其所有暗置的武将牌。",

  ["#shangyi"] = "尚义：令一名角色观看你的手牌，然后你观看其手牌并弃牌，或观看其所有暗置武将牌",
  ["shangyi_card"] = "观看手牌，然后可以弃置其中一张黑色牌",
  ["shangyi_hidden"] = "观看暗置的武将牌",
  ["#shangyi_card"] = "尚义：请观看 %src 的手牌并弃置其中一张黑色牌",

  ["$shangyi1"] = "大丈夫为人坦荡，看下手牌算什么。",
  ["$shangyi2"] = "敌情已了然于胸，即刻出发！",
}

local H = require "packages.hegemony.util"

shangyi:addEffect("active", {
  anim_type = "control",
  prompt = "#shangyi",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(shangyi.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if player.dead or target.dead or player:isKongcheng() then return end
    room:viewCards(target, {
      cards = player:getCardIds("h"),
      skill_name = shangyi.name,
    })
    local choices = {}
    if not target:isKongcheng() then
      table.insert(choices, "shangyi_card")
    end
    if not H.allGeneralsRevealed(target) then
      table.insert(choices, "shangyi_hidden")
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = shangyi.name,
    })
    if choice == "shangyi_hidden" then
      H.viewGeneral(player, target, shangyi.name, true, true)
    elseif choice == "shangyi_card" then
      local black = table.filter(target:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black
      end)
      local card, _ = room:askToChooseCardsAndChoice(player, {
        cards = black,
        skill_name = shangyi.name,
        prompt = "#shangyi_card:" .. target.id,
        min_num = 0,
        max_num = 1,
        all_cards = target:getCardIds("h"),
      })
      if #card > 0 then
        room:throwCard(card, shangyi.name, target, player)
      end
    end
  end,
})

-- The follow-up card view is safe for the BOT only when the target actually
-- has a hand. Prefer a confirmed enemy with the largest public hand count;
-- the relation model prevents revealing information from turning into an
-- indiscriminate ally-targeting action.
shangyi:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local best_target, best_benefit = nil, -100000
    for _, target in ipairs(ai:getEnabledTargets()) do
      local relation = ai:getFactionRelation(target)
      local targetable = relation.state == "enemy" or
        (relation.state == "unknown" and relation.confidence >= 0.65 and relation.attitude < -0.25)
      local hand_num = type(target.getHandcardNum) == "function" and target:getHandcardNum() or 0
      if targetable and hand_num > 0 then
        local benefit = 35 + math.min(hand_num, 5) * 14
        if benefit > best_benefit then
          best_target, best_benefit = target, benefit
        end
      end
    end

    if best_target and best_benefit > 0 then
      return { {}, { best_target } }, best_benefit
    end
  end,
})

-- Avoid the unsupported hidden-general CustomDialog branch for the first
-- bounded rollout. The card branch has an ordinary, testable request path.
shangyi:addAI(Fk.Ltk.AI.newChoiceStrategy {
  think = function(_, ai)
    local choices = type(ai.data) == "table" and ai.data[1] or Util.DummyTable
    if table.contains(choices, "shangyi_card") then
      return "shangyi_card", 1
    end
  end,
})

return shangyi
