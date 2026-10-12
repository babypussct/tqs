
local ranshang = fk.CreateSkill{
  name = "mobile__ranshang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__ranshang"] = "燃殇",
  [":mobile__ranshang"] = "锁定技，当你受到1点火焰伤害后，获得1个“燃”标记；结束阶段，你失去X点体力（X为“燃”数），"..
  "若“燃”数大于1，你减2点体力上限并摸两张牌。",

  ["$mobile__ranshang1"] = "你会后悔的！啊……",
  ["$mobile__ranshang2"] = "这是要赶尽杀绝吗？！",
}

ranshang:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ranshang.name) and data.damageType == fk.FireDamage
  end,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@wutugu_ran", data.damage)
  end,
})

ranshang:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ranshang.name) and player.phase == Player.Finish and
      player:getMark("@wutugu_ran") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:loseHp(player, player:getMark("@wutugu_ran"), ranshang.name)
    if player:getMark("@wutugu_ran") > 1 then
      room:changeMaxHp(player, -2)
      if not player.dead then
        player:drawCards(2, ranshang.name)
      end
    end
  end,
})

ranshang:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@wutugu_ran", 0)
end)

return ranshang
