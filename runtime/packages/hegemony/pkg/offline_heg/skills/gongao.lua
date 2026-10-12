
local gongao = fk.CreateSkill {
  name = "ofl_heg__gongao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ofl_heg__gongao"] = "功獒",
  [":ofl_heg__gongao"] = "锁定技，当其他角色死亡时，你加1点体力上限，回复1点体力；准备阶段，你将手牌摸至体力上限。",

  ["$ofl_heg__gongao1"] = "攻城拔寨，建功立业。",
  ["$ofl_heg__gongao2"] = "恪尽职守，忠心事主。",
}

gongao:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gongao.name) and target ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = gongao.name,
      }
    end
  end,
})

gongao:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gongao.name) and player.phase == Player.Start and
      player.maxHp > player:getHandcardNum()
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), gongao.name)
  end,
})

return gongao
