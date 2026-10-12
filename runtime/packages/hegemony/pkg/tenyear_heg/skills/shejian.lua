
local shejian = fk.CreateSkill{
  name = "ty_heg__shejian",
}

Fk:loadTranslationTable{
  ["ty_heg__shejian"] = "舌剑",
  [":ty_heg__shejian"] = "当你成为其他角色使用牌的唯一目标后，你可弃置所有手牌。若如此做，你选择一项：1.弃置其等量的牌；2.对其造成1点伤害。",

  ["#ty_heg__shejian-invoke"] = "舌剑：%dest 对你使用 %arg，你可以弃置所有手牌，弃置其等量的牌或对其造成1点伤害",
  ["#ty_heg__shejian-choice"] = "舌剑：弃置 %dest %arg张牌或对其造成1点伤害",
  ["shejian_discard"] = "弃置%dest%arg张牌",
  ["shejian_damage"] = "对%dest造成1点伤害",

  ["$ty_heg__shejian1"] = "伤人的，可不止刀剑！  ",
  ["$ty_heg__shejian2"] = "死公！云等道？",
}

shejian:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shejian.name) and data.from ~= player and #data:getAllTargets() == 1 and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = shejian.name,
      prompt = "#ty_heg__shejian-invoke::"..data.from.id..":"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    local n = player:getHandcardNum()
    player:throwAllCards("h", shejian.name)
    if not (player.dead or from.dead) then
      room:doIndicate(player.id, {data.from.id})
      local choices = {"shejian_damage::" .. data.from.id}
      n = math.min(n, #from:getCardIds("he"))
      if not from:isNude() then
        table.insert(choices, 1, "shejian_discard::" .. data.from.id .. ":" .. n)
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = shejian.name,
        prompt = "#ty_heg__shejian-choice::"..data.from.id..":"..n,
      })
      if choice:startsWith("shejian_discard") then
        local cards = room:askToChooseCards(player, {
          target = from,
          min = n,
          max = n,
          flag = "he",
          skill_name = shejian.name,
        })
        room:throwCard(cards, shejian.name, from, player)
      else
        room:damage{
          from = player,
          to = from,
          damage = 1,
          skillName = shejian.name
        }
      end
    end
  end,
})

return shejian
