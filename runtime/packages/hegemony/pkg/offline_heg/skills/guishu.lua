local guishu = fk.CreateSkill{
  name = "guishu",
}
guishu:addEffect("viewas", {
  pattern = "known_both,befriend_attacking",
  anim_type = "drawcard",
  interaction = function(self, player)
    local all_choices = {"befriend_attacking", "known_both"}
    local names = table.filter(all_choices, function(name) return
      player:getMark("_guishu-turn") ~= name and player:canUse(Fk:cloneCard(name))
    end)
    if #names == 0 then return end
    return UI.ComboBox {choices = names, all_choices = all_choices }
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Spade
      and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = guishu.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "_guishu-turn", use.card.name)
  end
})

Fk:loadTranslationTable{
  ["guishu"] = "鬼术",
  [":guishu"] = "出牌阶段，你可将一张♠手牌当【远交近攻】或【知己知彼】使用（不可与你此回合上一次以此法使用的牌相同）。",

  ["$guishu1"] = "契约已定！",
  ["$guishu2"] = "准备好，听候女王的差遣了吗？",
}

return guishu
