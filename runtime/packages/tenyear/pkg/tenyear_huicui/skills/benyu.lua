local benyu = fk.CreateSkill {
  name = "ty__benyu",
}

Fk:loadTranslationTable{
  ["ty__benyu"] = "贲育",
  [":ty__benyu"] = "当你受到伤害后，你可以选择一项：1.将手牌摸至与伤害来源相同（最多摸至5张）；2.弃置大于伤害来源手牌数张牌，"..
  "然后对其造成1点伤害。",

  ["ty__benyu_damage"] = "弃置至少%arg张牌，对 %dest 造成1点伤害",
  ["ty__benyu_draw"] = "将手牌摸至%arg张",

  ["$ty__benyu1"] = "助曹公者昌，逆曹公者亡！",
  ["$ty__benyu2"] = "愚民不可共济大事，必当与智者为伍。",
}

benyu:addAuxActiveSkill("ty__benyu_active", {
  interaction = function(self, player)
    local from = Fk:currentRoom():getPlayerById(self.ty__benyu)
    local all_choices, choices = {}, {}
    local n1 = math.min(from:getHandcardNum(), 5)
    local n2 = from:getHandcardNum() + 1
    table.insert(all_choices, "ty__benyu_draw:::"..n1)
    if player:getHandcardNum() < n1 then
      table.insert(choices, "ty__benyu_draw:::"..n1)
    end
    table.insert(all_choices, "ty__benyu_damage::"..from.id..":"..n2)
    if #player:getCardIds("he") >= n2 then
      table.insert(choices, "ty__benyu_damage::"..from.id..":"..n2)
    end
    if #choices == 0 then return end
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data:startsWith("ty__benyu_damage") then
      return not player:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if self.interaction.data:startsWith("ty__benyu_damage") then
      return #selected_cards > Fk:currentRoom():getPlayerById(self.ty__benyu):getHandcardNum()
    else
      return #selected_cards == 0
    end
  end,
})

benyu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(benyu.name) and
      data.from and not data.from.dead and
      (player:getHandcardNum() < math.min(data.from:getHandcardNum(), 5) or
      #player:getCardIds("he") > data.from:getHandcardNum())
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty__benyu_active",
      cancelable = true,
      extra_data = {
        ty__benyu = data.from.id,
      },
    })
    if success and dat then
      event:setCostData(self, {tos = {data.from}, cards = dat.cards, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice:startsWith("ty__benyu_damage") then
      room:throwCard(event:getCostData(self).cards, benyu.name, player, player)
      if not data.from.dead then
        room:damage{
          from = player,
          to = data.from,
          damage = 1,
          skillName = benyu.name,
        }
      end
    else
      player:drawCards(math.min(5, data.from:getHandcardNum()) - player:getHandcardNum())
    end
  end,
})

return benyu
