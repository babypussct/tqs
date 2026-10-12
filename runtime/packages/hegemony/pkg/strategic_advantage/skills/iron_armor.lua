local H = require "packages.hegemony.util"
local ironArmorSkill = fk.CreateSkill{
  name = "#iron_armor_skill",
  attached_equip = "iron_armor",
  tags = {Skill.Compulsory},
}
ironArmorSkill:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(ironArmorSkill.name) then return false end
    return table.contains({"fire__slash", "burning_camps", "fire_attack"}, data.card.name)
  end,
  on_use = function(self, event, target, player, data)
    data:cancelTarget(player)
    return true
  end
})
ironArmorSkill:addEffect(fk.BeforeChainStateChange, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(ironArmorSkill.name) then return false end
    return H.isSmallKingdomPlayer(player) and not player.chained
  end,
  on_use = function (self, event, target, player, data)
    data.prevented = true
  end,
})

ironArmorSkill:addTest(function (room, me)
  local card = room:printCard("iron_armor")
  local comp2 = room.players[2]
  FkTest.runInRoom(function()
    room:useCard {
      from = me,
      tos = { me },
      card = card,
    }
    room:useCard {
      from = room.players[8],
      tos = { },
      card = Fk:cloneCard("burning_camps"),
    }
    room:useCard {
      from = comp2,
      tos = { me },
      card = Fk:cloneCard("fire_attack"),
    }
    room:useCard {
      from = comp2,
      tos = { me },
      card = Fk:cloneCard("fire__slash"),
    }
  end)
  lu.assertEquals(me.hp, 4)

  local p = table.find(room.alive_players, function(p) return H.isSmallKingdomPlayer(p) end)
  if p then
    -- print(Fk:translate(p.general) .. " is small kingdom player")
    FkTest.runInRoom(function()
      room:useCard {
        from = comp2,
        tos = { me },
        card = Fk:cloneCard("iron_chain"),
      }
    end)
    lu.assertIsFalse(p.chained)
  end
end)

Fk:loadTranslationTable{
  ["iron_armor"] = "明光铠",
  ["#iron_armor_skill"] = "明光铠",
  [":iron_armor"] = "装备牌·防具<br/><b>防具技能</b>：锁定技，当你成为【火烧连营】、【火攻】或火【杀】的目标时，你取消此目标；当你横置前，若你是小势力角色，你防止此次横置。",
}

return ironArmorSkill
