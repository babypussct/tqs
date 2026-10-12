
local shenfeng = fk.CreateSkill {
  name = "shenfeng",
}

Fk:loadTranslationTable{
  ["shenfeng"] = "神锋",
  [":shenfeng"] = "当你使用【杀】指定一个目标后，你可以弃置一张装备牌，然后选择一项："..
  "1.此【杀】伤害+1；2.令此【杀】造成的伤害视为失去体力；3.令目标角色弃置两张牌。",

  ["#shenfeng-invoke"] = "神锋：你可以弃置一张装备牌，选择一项",
  ["#shenfeng-choice"] = "神锋：为此【杀】选择一项效果",
  ["shenfeng_damage"] = "伤害+1",
  ["shenfeng_losehp"] = "伤害改为失去体力",
  ["shenfeng_discard"] = "%dest弃置两张牌",

  ["$shenfeng1"] = "",
  ["$shenfeng2"] = "",
}

shenfeng:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shenfeng.name) and
      data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = shenfeng.name,
      cancelable = true,
      pattern = ".|.|.|.|.|equip",
      prompt = "#shenfeng-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    room:throwCard(cards, shenfeng.name, player, player)
    if player.dead then return end
    local choice = room:askToChoice(player, {
      skill_name = shenfeng.name,
      prompt = "#shenfeng-choice",
      choices = { "shenfeng_damage", "shenfeng_losehp", "shenfeng_discard::"..data.to.id },
    })
    if choice == "shenfeng_damage" then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    elseif choice == "shenfeng_losehp" then
      data.extra_data = data.extra_data or {}
      data.extra_data.shenfeng = player
    elseif not data.to.dead then
      room:askToDiscard(data.to, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = shenfeng.name,
        cancelable = false,
      })
    end
  end,
})

shenfeng:addEffect(fk.PreDamage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.card and not data.prevented then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return use_event and (use_event.data.extra_data or {}).shenfeng
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event then
      room:loseHp(data.to, data.damage, shenfeng.name, use_event.data.extra_data.shenfeng)
      data:preventDamage()
    end
  end,
})

return shenfeng
