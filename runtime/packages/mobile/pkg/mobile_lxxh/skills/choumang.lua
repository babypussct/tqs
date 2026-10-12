local choumang = fk.CreateSkill {
  name = "choumang",
}

Fk:loadTranslationTable{
  ["choumang"] = "仇铓",
  [":choumang"] = "每回合限一次，当你使用【杀】指定唯一目标后或当你成为【杀】的唯一目标后，你可以选择一项：1.令此【杀】伤害+1；" ..
  "2.令此【杀】被抵消后，你可以获得你与其距离1以内的一名其他角色区域内的一张牌。背水：弃置你与其装备区里的武器牌（你或其装备区里有武器牌才可选择）。",

  ["choumang_damage"] = "此【杀】伤害+1",
  ["choumang_prey"] = "此【杀】被抵消后你获得角色牌",
  ["choumang_beishui"] = "背水：弃置双方武器",
  ["#choumang-invoke"] = "仇铓：你可以选择一项",
  ["#choumang_delay-choose"] = "仇铓：你可以获得其中一名角色区域内的一张牌",

  ["$choumang1"] = "司马氏之罪，尽洛水亦难清！",
  ["$choumang2"] = "汝司马氏世受魏恩，今安敢如此！",
}

local choumang_spec = {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(choumang.name) and data.card.trueName == "slash" and
      data:isOnlyTarget(data.use.tos[1]) and player:usedSkillTimes(choumang.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = { "choumang_damage", "choumang_prey", "Cancel" }
    if #data.from:getEquipments(Card.SubtypeWeapon) > 0 or
      #data.to:getEquipments(Card.SubtypeWeapon) > 0
    then
      table.insert(choices, 3, "choumang_beishui")
    end
    local choice = room:askToChoice(player,{
      choices = choices,
      skill_name = choumang.name,
      prompt = "#choumang-invoke",
      all_choices = {
        "choumang_damage",
        "choumang_prey",
        "choumang_beishui",
        "Cancel",
      }
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice, tos = {data.from == player and data.to or data.from}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice ~= "choumang_prey" then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
    if choice ~= "choumang_damage" then
      data.extra_data = data.extra_data or {}
      data.extra_data.choumang = data.extra_data.choumang or {}
      table.insert(data.extra_data.choumang, { from = player, tos = {data.from, data.to} })
    end
    if choice == "choumang_beishui" then
      local players = { data.from, data.to }
      room:sortByAction(players)
      for _, p in ipairs(players) do
        local weapons = p:getEquipments(Card.SubtypeWeapon)
        if #weapons > 0 then
          room:throwCard(weapons, choumang.name, p, player)
        end
      end
    end
  end,
}

choumang:addEffect(fk.TargetSpecified, choumang_spec)
choumang:addEffect(fk.TargetConfirmed, choumang_spec)

choumang:addEffect(fk.CardEffectCancelledOut, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if data.card.trueName == "slash" and not player.dead and
      data.extra_data and data.extra_data.choumang then
      for _, info in ipairs(data.extra_data.choumang) do
        if info.from == player then
          return table.find(player.room:getOtherPlayers(player, false), function (p)
            return (info.tos[1]:distanceTo(p) < 2 or info.tos[2]:distanceTo(p) < 2) and not p:isAllNude()
          end)
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, info in ipairs(data.extra_data.choumang) do
      if info.from == player then
        table.insertTable(targets, table.filter(player.room:getOtherPlayers(player, false), function (p)
          return (info.tos[1]:distanceTo(p) < 2 or info.tos[2]:distanceTo(p) < 2) and not p:isAllNude()
        end))
      end
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = choumang.name,
      prompt = "#choumang_delay-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "hej",
      skill_name = choumang.name,
    })
    room:obtainCard(player, id, false, fk.ReasonPrey, player, choumang.name)
  end,
})

return choumang
