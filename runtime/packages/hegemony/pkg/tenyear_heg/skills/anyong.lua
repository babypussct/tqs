local anyong = fk.CreateSkill{
  name = "ty_heg__anyong",
}
local H = require "packages.hegemony.util"
anyong:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target and H.compareKingdomWith(target, player)
      and player:hasSkill(anyong.name)
      and data.to ~= player and data.to ~= target
      and player:usedSkillTimes(anyong.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = anyong.name,
      prompt = "#ty_heg__anyong-invoke:"..data.from.id .. ":" .. data.to.id .. ":" .. data.damage
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = data.to
    local num = H.getGeneralsRevealedNum(to)
    if num == 1 then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = false,
        skill_name = anyong.name,
        cancelable = false,
      })
    elseif num == 2 then
      room:loseHp(player, 1, anyong.name)
      room:handleAddLoseSkills(player, "-ty_heg__anyong")
    end
    data:changeDamage(data.damage)
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__anyong"] = "暗涌",
  ["#ty_heg__anyong-invoke"] = "暗涌：是否令 %src 对 %dest 造成的 %arg 点伤害翻倍！",
  [":ty_heg__anyong"] = "每回合限一次，当与你势力相同的一名角色对另一名其他角色造成伤害时，你可令此伤害翻倍，然后若受到伤害的角色："..
    "武将牌均明置，你失去1点体力并失去此技能；只明置了一张武将牌，你弃置两张手牌。",

  ["$ty_heg__anyong1"] = "冀州暗潮汹涌，群仕居危思变。",
  ["$ty_heg__anyong2"] = "殿上太守且相看，殿下几人还拥韩。",
}

return anyong
