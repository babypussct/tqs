local cuizhen = fk.CreateSkill {
  name = "cuizhen",
}

Fk:loadTranslationTable{
  ["cuizhen"] = "摧阵",
  [":cuizhen"] = "游戏开始时，你可以选择至多三名其他角色，废除其武器栏；"..
  "当你于出牌阶段内使用【杀】或伤害类锦囊牌指定其他角色为目标后，若其手牌数不小于体力值，则你可以废除其武器栏；"..
  "摸牌阶段，你额外摸X张牌（X为场上被废除的武器栏数+1，至多为3）。",

  ["#cuizhen-choose"] = "摧阵：你可以废除至多三名角色的武器栏！",
  ["#cuizhen-invoke"] = "摧阵：是否废除 %dest 的武器栏？",

  ["$cuizhen1"] = "欲活命者，还不弃兵卸甲！",
  ["$cuizhen2"] = "全军大进，誓讨司马乱贼！",
}

cuizhen:addEffect(fk.GameStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(cuizhen.name) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return #p:getAvailableEquipSlots(Card.SubtypeWeapon) > 0
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return #p:getAvailableEquipSlots(Card.SubtypeWeapon) > 0
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 3,
      targets = targets,
      skill_name = cuizhen.name,
      prompt = "#cuizhen-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(event:getCostData(self).tos)
    for _, p in ipairs(targets) do
      if not p.dead and #p:getAvailableEquipSlots(Card.SubtypeWeapon) > 0 then
        room:abortPlayerArea(p, Player.WeaponSlot)
      end
    end
  end,
})
cuizhen:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cuizhen.name) and player.phase == Player.Play and
      data.card.is_damage_card and not data.to.dead and
      data.to:getHandcardNum() >= data.to.hp and #data.to:getAvailableEquipSlots(Card.SubtypeWeapon) > 0
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = cuizhen.name,
      prompt = "#cuizhen-choose",
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:abortPlayerArea(data.to, Player.WeaponSlot)
  end,
})
cuizhen:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(cuizhen.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local n = 1
    for _, p in ipairs(player.room.alive_players) do
      for _, slot in ipairs(p.sealedSlots) do
        if slot == Player.WeaponSlot then
          n = n + 1
        end
      end
    end
    data.n = data.n + math.min(n, 3)
  end,
})

return cuizhen
