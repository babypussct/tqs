
local xiaoji = fk.CreateSkill{
  name = "hs__xiaoji",
}
xiaoji:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(xiaoji.name) then return end
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.room.current == player and 1 or 3, xiaoji.name)
  end,
})

Fk:loadTranslationTable{
  ["hs__xiaoji"] = "枭姬",
  [":hs__xiaoji"] = "当你失去装备区的装备牌后，若此时是你的回合内，你摸一张牌，否则你摸三张牌。",

  ["$hs__xiaoji1"] = "哼！",
  ["$hs__xiaoji2"] = "看我的厉害！",
}

return xiaoji
