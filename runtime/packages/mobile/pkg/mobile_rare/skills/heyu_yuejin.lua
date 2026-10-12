---@param room AbstractRoom
---@param player Player
---@param friend string
---@return boolean
local function HeyuFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    not not table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general:endsWith(friend) or p.deputyGeneral:endsWith(friend))
    end)
end

local heyu = fk.CreateSkill {
  name = "yuejin__heyu",
  tags = { Skill.Compulsory },
  dynamic_desc = function(self, player)
    local lidian, zhangliao = HeyuFriend(Fk:currentRoom(), player, "thoroughbred__lidian"),
      HeyuFriend(Fk:currentRoom(), player, "thoroughbred__zhangliao")
    if lidian and zhangliao then
      return "yuejin__heyu"
    elseif zhangliao then
      return "yuejin__heyu_zhangliao"
    elseif lidian then
      return "yuejin__heyu_lidian"
    end
    return "dummyskill"
  end,
}

Fk:loadTranslationTable{
  ["yuejin__heyu"] = "合御",
  [":yuejin__heyu"] = "锁定技，若友方骥张辽在场，你发动〖陷坚〗的【杀】造成伤害后，你可以对目标角色执行未选择的一项；"..
  "若友方骥李典在场，每回合有角色首次失去“陷坚”牌后，你摸一张牌。（仅斗地主和2v2模式生效）",

  [":yuejin__heyu_zhangliao"] = "锁定技，若友方骥张辽在场，你发动〖陷坚〗的【杀】造成伤害后，你可以对目标角色执行未选择的一项。",
  [":yuejin__heyu_lidian"] = "锁定技，若友方骥李典在场，每回合有角色首次失去“陷坚”牌后，你摸一张牌。",

  ["#yuejin__heyu-put"] = "陷坚：你可以将此【杀】置入 %dest 的一个空置装备栏",

  ["$yuejin__heyu1"] = "",
  ["$yuejin__heyu2"] = "",
}

local mapper = {
  [Player.WeaponSlot] = "weapon",
  [Player.ArmorSlot] = "armor",
  [Player.OffensiveRideSlot] = "offensive_horse",
  [Player.DefensiveRideSlot] = "defensive_horse",
  [Player.TreasureSlot] = "treasure",
}

heyu:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(heyu.name) and HeyuFriend(player.room, player, "thoroughbred__zhangliao") and
      data.card and data.card.trueName == "slash" then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event and use_event.data.card == data.card then
        local dat = use_event.data
        if dat.extra_data.xianjian1 and dat.extra_data.xianjian1[1] == player then
          if #Card:getIdList(data.card) == 1 and player.room:getCardArea(data.card) == Card.Processing then
            local to = dat.extra_data.xianjian1[2]
            return not to.dead and to:hasEmptyEquipSlot()
          end
        elseif dat.extra_data.xianjian2 and dat.extra_data.xianjian2[1] == player then
          return not dat.extra_data.xianjian2[2].dead
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event and use_event.data.card == data.card then
      local dat = use_event.data
      if dat.extra_data.xianjian1 and dat.extra_data.xianjian1[1] == player then
        if #Card:getIdList(data.card) == 1 and room:getCardArea(data.card) == Card.Processing then
          local to = dat.extra_data.xianjian1[2]
          local choices = {}
          for _, t in ipairs({ 3, 4, 5, 6, 7 }) do
            if to:hasEmptyEquipSlot(t) then
              table.insert(choices, Util.convertSubtypeAndEquipSlot(t))
            end
          end
          table.insert(choices, "Cancel")
          local choice = room:askToChoice(player, {
            skill_name = "xianjian",
            choices = choices,
            prompt = "#yuejin__heyu-put::"..to.id,
          })
          if choice ~= "Cancel" then
            local id = Card:getIdList(data.card)[1]
            local card = Fk:cloneCard(mapper[choice].."__xianjian")
            card:addSubcard(id)
            room:moveCardIntoEquip(to, card, "xianjian", true, player)
          end
        end
      elseif dat.extra_data.xianjian2 and dat.extra_data.xianjian2[1] == player then
        local to = dat.extra_data.xianjian2[2]
        local n = math.max(#to:getCardIds("ej"), 1)
        local choice = room:askToChoice(player, {
          choices = { "xianjian_draw:"..player.id..":"..to.id..":"..n, "Cancel" },
          skill_name = "xianjian",
          prompt = "#xianjian-invoke::"..to.id,
        })
        if choice ~= "Cancel" then
          player:drawCards(1, "xianjian")
          if not to:isNude() then
            room:askToDiscard(to, {
              min_num = n,
              max_num = n,
              include_equip = true,
              skill_name = "xianjian",
              cancelable = false,
            })
          end
        end
      end
    end
  end,
})

heyu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(heyu.name) and HeyuFriend(player.room, player, "thoroughbred__lidian") and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and info.beforeCard.trueName == "xianjian" then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, heyu.name)
  end,
})

return heyu
