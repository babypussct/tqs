
local fuyuz = fk.CreateSkill {
  name = "fuyuz",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = { "wu" },
}

Fk:loadTranslationTable {
  ["fuyuz"] = "抚驭",
  [":fuyuz"] = "吴势力技，每回合限一次，当你造成或受到伤害后，你可以交给一名角色一张牌，获得其X张牌（X为你已损失体力值）。"..
  "若你与其获得牌类型均相同，你回复1点体力或令其摸一张牌。",

  ["#fuyuz-give"] = "抚驭：你可以交给一名角色一张牌，获得其%arg张牌",
  ["#fuyuz-prey"] = "抚驭：获得 %dest %arg张牌",
  ["fuyuz_draw"] = "%dest摸一张牌",

  ["$fuyuz1"] = "",
  ["$fuyuz2"] = "",
}

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuyuz.name) and
        player:usedSkillTimes(fuyuz.name, Player.HistoryTurn) == 0 and
        not player:isNude() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to, card = room:askToChooseCardsAndPlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = 1,
      prompt = "#fuyuz-give:::"..player:getLostHp(),
      skill_name = fuyuz.name,
    })
    if #to > 0 and #card > 0 then
      event:setCostData(self, { tos = to, cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = event:getCostData(self).cards or {}
    local t = Fk:getCardById(card[1]).type
    local n = player:getLostHp()
    local yes = true
    room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, fuyuz.name, nil, false, player)
    if player.dead then return end
    if not to:isNude() and n > 0 then
      local cards = room:askToChooseCards(player, {
        min = n,
        max = n,
        target = to,
        flag = "he",
        skill_name = fuyuz.name,
      })
      yes = table.every(card, function (id)
        return Fk:getCardById(id).type == t
      end)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, fuyuz.name, nil, false, player)
    end
    if yes and not player.dead then
      local choices = { "recover" }
      if not to.dead then
        table.insert(choices, "fuyuz_draw::"..to.id)
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = fuyuz.name,
      })
      if choice == "recover" then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = fuyuz.name,
        }
      else
        to:drawCards(1, fuyuz.name)
      end
    end
  end,
}
fuyuz:addEffect(fk.Damage, spec)
fuyuz:addEffect(fk.Damaged, spec)

return fuyuz
