local shanxi = fk.CreateSkill{
  name = "mobile__shanxi",
}

Fk:loadTranslationTable{
  ["mobile__shanxi"] = "闪袭",
  [":mobile__shanxi"] = "出牌阶段开始时，你可以弃置一张红色基本牌并指定一名其他角色，将其至多X张牌置于其武将牌上（X为你的体力值），"..
  "本回合结束时其获得之。",

  ["#mobile__shanxi-choose"] = "闪袭：你可以弃置一张红色基本牌，将一名其他角色的牌扣置于其武将牌上直到回合结束",
  ["#mobile__shanxi-cards"] = "闪袭：将 %dest 至多%arg张牌扣置于其武将牌上直到回合结束",
  ["$mobile__shanxi"] = "闪袭",

  ["$mobile__shanxi1"] = "有进无退，溃敌图克！",
  ["$mobile__shanxi2"] = "速破叛寇，不容敌守！",
}

shanxi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanxi.name) and player.phase == Player.Play and
      not player:isKongcheng() and player.hp > 0 and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      pattern = ".|.|heart,diamond|.|.|basic",
      skill_name = shanxi.name,
      prompt = "#mobile__shanxi-choose",
      cancelable = true,
      will_throw = true,
    })
    if #tos > 0 and #cards == 1 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:throwCard(event:getCostData(self).cards, shanxi.name, player, player)
    if player.hp < 1 or to.dead or to:isNude() then return end
    local cards = room:askToChooseCards(player, {
      target = to,
      min = 1,
      max = player.hp,
      flag = "he",
      skill_name = shanxi.name,
      prompt = "#mobile__shanxi-cards::"..to.id..":"..player.hp,
    })
    to:addToPile("$mobile__shanxi", cards, false, shanxi.name)
  end,
})
shanxi:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("$mobile__shanxi") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("$mobile__shanxi"), Card.PlayerHand, player, fk.ReasonJustMove)
  end,
})

return shanxi
