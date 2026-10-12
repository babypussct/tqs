
local paiyi = fk.CreateSkill {
  name = "ol_ex__paiyi",
}

Fk:loadTranslationTable{
  ["ol_ex__paiyi"] = "排异",
  [":ol_ex__paiyi"] = "出牌阶段限一次，你可以移去一张“权”，指定一名角色并选择：1.其摸两张牌；2.你对其造成1点伤害。"..
  "然后若其手牌数大于你，执行另一项，本阶段此技能改为限两次。",

  ["#ol_ex__paiyi"] = "排异：移去一张“权”，令一名角色执行一项，然后若其手牌数大于你则执行另一项",

  ["$ol_ex__paiyi1"] = "",
  ["$ol_ex__paiyi2"] = "",
}

paiyi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol_ex__paiyi",
  card_num = 1,
  target_num = 1,
  expand_pile = "zhonghui_quan",
  interaction = UI.ComboBox { choices = { "draw2", "damage1" } },
  can_use = function(self, player)
    return #player:getPile("zhonghui_quan") > 0 and
      player:usedSkillTimes(paiyi.name, Player.HistoryPhase) < 1 + player:getMark("ol_ex__paiyi-phase")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getPile("zhonghui_quan"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choice = self.interaction.data
    room:moveCards({
      from = player,
      ids = effect.cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = paiyi.name,
    })
    if player.dead or target.dead then return end
    if choice == "draw2" then
      target:drawCards(2, paiyi.name)
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = paiyi.name,
      }
    end
    if target:getHandcardNum() > player:getHandcardNum() and not target.dead then
      if not player.dead then
        room:setPlayerMark(player, "ol_ex__paiyi-phase", 1)
      end
      if choice == "draw2" then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = paiyi.name,
        }
      else
        target:drawCards(2, paiyi.name)
      end
    end
  end,
})

return paiyi
