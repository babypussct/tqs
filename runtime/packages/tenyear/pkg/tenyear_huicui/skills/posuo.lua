local posuo = fk.CreateSkill {
  name = "posuo",
}

Fk:loadTranslationTable{
  ["posuo"] = "婆娑",
  [":posuo"] = "出牌阶段每种花色限一次，若你本阶段未对其他角色造成过伤害，你可以将一张手牌当此花色有的一张伤害牌使用。",

  ["#posuo"] = "婆娑：将一张手牌当此花色有的一张伤害牌使用",
  ["posuo_name"] = "%arg [%arg2]",

  ["$posuo1"] = "绯纱婆娑起，佳人笑靥红。",
  ["$posuo2"] = "红烛映俏影，一舞影斑斓。",
}

posuo:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#posuo",
  handly_pile = true,
  filter_pattern = function(self, player, card_name, selected)
    local suits = { "spade", "heart", "club", "diamond" }
    for _, v in ipairs(player:getTableMark("posuo-phase")) do
      table.removeOne(suits, v)
    end
    if #suits > 0 then
      return {
        max_num = 1,
        min_num = 1,
        pattern = ".|.|".. table.concat(suits, ",") .. "|^equip",
      }
    end
  end,
  interaction_helper = function(self, player, selected_cards)
    if #selected_cards == 0 then return end
    local names = player:getMark("posuo_names")
    if names == 0 then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          local suit = card:getSuitString()
          names[suit] = names[suit] or {}
          table.insertIfNeed(names[suit], card.name)
        end
      end
      player:setMark("posuo_names", names)
    end
    local card = Fk:getCardById(selected_cards[1])
    names = names[card:getSuitString()] or {}
    return UI.CardNameBox {
      choices = player:getViewAsCardNames(posuo.name, names, selected_cards),
      all_choices = names
    }
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    return Fk:cloneCard(self.interaction.data, nil, nil, posuo.name, cards)
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, "posuo-phase", use.card:getSuitString())
  end,
  enabled_at_play = function(self, player)
    local mark = player:getMark("posuo-phase")
    return mark ~= "posuo_prohibit" and mark == 0 or (#mark < 4)
  end,
})

posuo:addAcquireEffect(function(self, player, is_start)
  if player.phase == Player.Play then
    local room = player.room
    room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data
      if damage.from == player then
        room:setPlayerMark(player, "posuo-phase", "posuo_prohibit")
        return true
      end
    end, Player.HistoryPhase)
  end
end)

posuo:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(posuo.name, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "posuo-phase", "posuo_prohibit")
  end,
})

return posuo
