local xianjian = fk.CreateSkill {
  name = "xianjian",
}

Fk:loadTranslationTable{
  ["xianjian"] = "陷坚",
  [":xianjian"] = "当你使用【杀】指定唯一目标后，你可以选择一项：1.你摸一张牌，其弃置X张牌（X为其场上的牌数且至少为1）；"..
  "2.此【杀】结算结束后，你将此【杀】置入其一个空置装备栏中，称为“陷坚”牌。",

  ["#xianjian-invoke"] = "陷坚：你可以对 %dest 发动“陷坚”，选择一项",
  ["xianjian_draw"] = "%src摸一张牌，%dest弃%arg张牌",
  ["xianjian_put"] = "此【杀】结算后置为%dest的“陷坚”牌",
  ["#xianjian-put"] = "陷坚：将此【杀】置入 %dest 的一个空置装备栏",

  ["$xianjian1"] = "纵尔固若金汤，不若吾刃之利！",
  ["$xianjian2"] = "攻城有进无退，吾当身先士卒！",
}

local mapper = {
  [Player.WeaponSlot] = "weapon",
  [Player.ArmorSlot] = "armor",
  [Player.OffensiveRideSlot] = "offensive_horse",
  [Player.DefensiveRideSlot] = "defensive_horse",
  [Player.TreasureSlot] = "treasure",
}

xianjian:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xianjian.name) and
      data.card.trueName == "slash" and data:isOnlyTarget(data.to)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = math.max(#data.to:getCardIds("ej"), 1)
    local choice = room:askToChoice(player, {
      choices = { "xianjian_draw:"..player.id..":"..data.to.id..":"..n, "xianjian_put::"..data.to.id, "Cancel" },
      skill_name = xianjian.name,
      prompt = "#xianjian-invoke::"..data.to.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { tos = { data.to }, choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    data.extra_data = data.extra_data or {}
    if choice:startsWith("xianjian_draw") then
      data.extra_data.xianjian1 = { player, data.to }
      player:drawCards(1, xianjian.name)
      local n = math.max(#data.to:getCardIds("ej"), 1)
      if not data.to:isNude() then
        room:askToDiscard(data.to, {
          min_num = n,
          max_num = n,
          include_equip = true,
          skill_name = xianjian.name,
          cancelable = false,
        })
      end
    else
      data.extra_data.xianjian2 = { player, data.to }
    end
  end,
})

xianjian:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return data.card.trueName == "slash" and
      data.extra_data and data.extra_data.xianjian2 and
      data.extra_data.xianjian2[1] == player and not player.dead and
      not data.extra_data.xianjian2[2].dead and data.extra_data.xianjian2[2]:hasEmptyEquipSlot() and
      #Card:getIdList(data.card) == 1 and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = data.extra_data.xianjian2[2]
    local choices = {}
    for _, t in ipairs({ 3, 4, 5, 6, 7 }) do
      if to:hasEmptyEquipSlot(t) then
        table.insert(choices, Util.convertSubtypeAndEquipSlot(t))
      end
    end
    local choice = room:askToChoice(player, {
      skill_name = xianjian.name,
      choices = choices,
      prompt = "#xianjian-put::"..to.id,
    })
    local id = Card:getIdList(data.card)[1]
    local card = Fk:cloneCard(mapper[choice].."__xianjian")
    card:addSubcard(id)
    room:moveCardIntoEquip(to, card, xianjian.name, true, player)
  end,
})

return xianjian
