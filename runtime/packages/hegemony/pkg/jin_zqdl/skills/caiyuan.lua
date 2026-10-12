local caiyuan = fk.CreateSkill{
  name = "heg__caiyuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["heg__caiyuan"] = "才媛",
  [":heg__caiyuan"] = "锁定技，若你的武将牌均明置：回合开始时，你摸两张牌；当你受到伤害时，你令此伤害-1并暗置此武将牌。",

  ["$heg__caiyuan1"] = "柳絮轻舞，撷芳赋诗。",
  ["$heg__caiyuan2"] = "秀媛才德，知书达理。",
}

local H = require "packages.hegemony.util"

caiyuan:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(caiyuan.name) and H.allGeneralsRevealed(player)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, caiyuan.name)
  end,
})

caiyuan:addEffect(fk.DamageInflicted, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(caiyuan.name) and H.allGeneralsRevealed(player)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
    H.hideBySkillName(player, caiyuan.name)
  end,
})

return caiyuan

