local dongfeng = fk.CreateSkill {
  name = "rouge_dongfeng",
  mode_skill = true,
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["rouge_dongfeng"] = "东风",
  [":rouge_dongfeng"] = "锁定技，当你造成过属性伤害后，本轮你造成的属性伤害+1。",
}

local RougeUtil = require "packages.ol.pkg.ol_gamemode.rougelike1v1.util"

dongfeng:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and RougeUtil.hasTalent(player, dongfeng.name) and
      data.damageType ~= fk.NormalDamage
  end,
  on_use = function(self, event, target, player, data)
    RougeUtil.sendTalentLog(player, dongfeng.name)
    player.room:addPlayerMark(player, "rouge_dongfeng-round", 1)
  end,
})

dongfeng:addEffect(fk.DamageCaused, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("rouge_dongfeng-round") > 0 and
      data.damageType ~= fk.NormalDamage
  end,
  on_refresh = function (self, event, target, player, data)
    data:changeDamage(player:getMark("rouge_dongfeng-round"))
  end,
})

return dongfeng
