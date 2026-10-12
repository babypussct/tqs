
local kuanqu = fk.CreateSkill {
  name = "kuanqu",
}

Fk:loadTranslationTable{
  ["kuanqu"] = "款曲",
  [":kuanqu"] = "出牌阶段开始时，你可以执行至多两项：1.弃置至多两张牌；2.受到1点伤害；3.回复1点体力。"..
  "然后若你手牌数等于体力值，你获得一名角色一张牌，令其依次执行剩余项。",

  ["#kuanqu-invoke"] = "款曲：执行至多两项，然后若手牌数等于体力值，获得一名角色一张牌并令其执行剩余项",
  ["#kuanqu-choose"] = "款曲：获得一名角色一张牌，令其依次执行剩余项",
  ["kuanqu_discard"] = "弃置至多两张牌",
  ["kuanqu_damage"] = "受到1点伤害",

  ["$kuanqu1"] = "",
  ["$kuanqu2"] = "",
}

kuanqu:addAuxActiveSkill("#kuanqu_active", {
  min_card_num = 0,
  max_card_num = 2,
  target_num = 0,
  interaction = function (self, player)
    local choices = self.choices
    if not table.find(player:getCardIds("he"), function (id)
      return not player:prohibitDiscard(id)
    end) then
      table.removeOne(choices, "kuanqu_discard")
    end
    if not player:isWounded() then
      table.removeOne(choices, "recover")
    end
    return UI.OptionBox { options = choices, all_options = { "kuanqu_discard", "kuanqu_damage", "recover" } }
  end,
  card_filter = function (self, player, to_select, selected)
    return self.interaction.data == "kuanqu_discard" and #selected < 2 and not player:prohibitDiscard(to_select)
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if self.interaction.data == "kuanqu_discard" then
      return #selected_cards > 0
    else
      return #selected_cards == 0
    end
  end,
})

kuanqu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(kuanqu.name) and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#kuanqu_active",
      prompt = "#kuanqu-invoke",
      extra_data = {
        choices = { "kuanqu_discard", "kuanqu_damage", "recover" },
      },
    })
    if success and dat then
      event:setCostData(self, { cards = dat.cards, choice = dat.interaction })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choices = { "kuanqu_discard", "kuanqu_damage", "recover" }
    local cards = event:getCostData(self).cards or {}
    local choice = event:getCostData(self).choice
    for i = 1, 2 do
      table.removeOne(choices, choice)
      if choice == "kuanqu_discard" then
        room:throwCard(cards, kuanqu.name, player, player)
      elseif choice == "kuanqu_damage" then
        room:damage {
          to = player,
          damage = 1,
          skillName = kuanqu.name,
        }
      elseif choice == "recover" then
        room:recover{
          who = player,
          num = 1,
          skillName = kuanqu.name,
        }
      end
      if player.dead then return end
      if i == 1 then
        local success, dat = room:askToUseActiveSkill(player, {
          skill_name = "#kuanqu_active",
          prompt = "#kuanqu-invoke",
          extra_data = {
            choices = choices
          },
        })
        if success and dat then
          cards = dat.cards
          choice = dat.interaction
        end
      else
        break
      end
    end
    if player:getHandcardNum() == player.hp then
      local to = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#kuanqu-choose",
        skill_name = kuanqu.name,
        cancelable = false,
      })[1]
      if (to == player and #player:getCardIds("e") > 0) or (to ~= player and not to:isNude()) then
        local id = room:askToChooseCard(player, {
          target = to,
          flag = to == player and "e" or "he",
          skill_name = kuanqu.name,
        })
        room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, kuanqu.name, nil, false, player)
      end
      for _, c in ipairs(choices) do
        if to.dead then return end
        if c == "kuanqu_discard" then
          room:askToDiscard(to, {
            min_num = 1,
            max_num = 2,
            include_equip = true,
            skill_name = kuanqu.name,
            cancelable = false,
          })
        elseif c == "kuanqu_damage" then
          room:damage {
            to = to,
            damage = 1,
            skillName = kuanqu.name,
          }
        elseif c == "recover" then
          room:recover{
            who = to,
            num = 1,
            skillName = kuanqu.name,
          }
        end
      end
    end
  end,
})

return kuanqu
