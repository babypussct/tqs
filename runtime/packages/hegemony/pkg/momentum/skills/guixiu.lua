local guixiu = fk.CreateSkill{
  name = "guixiu",
}
local H = require "packages.hegemony.util"
guixiu:addEffect(fk.GeneralRevealed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(guixiu.name) then return false end
    for _, v in pairs(data) do
      if table.contains(Fk.generals[v]:getSkillNameList(),
        guixiu.name) then return true end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = guixiu.name,
      propmt = "#guixiu-draw"
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, guixiu.name)
  end
})
guixiu:addEffect(H.GeneralRemoved, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isWounded() and
      table.contains(Fk.generals[data.origName]:getSkillNameList(), guixiu.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = guixiu.name,
      propmt = "#guixiu-recover"
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      skillName = guixiu.name,
    }
  end
})

guixiu:addTest(function (room, me)
  FkTest.runInRoom(function () room:changeHero(me, "ld__mifuren") end)
  FkTest.setNextReplies(me, {"1", "1", "1"})
  FkTest.runInRoom(function ()
    me:hideGeneral()
    room:loseHp(me, 1)
    me:revealGeneral()
    H.removeGeneral(me, false)
  end)
end)

Fk:loadTranslationTable{
  ["guixiu"] = "闺秀",
  [":guixiu"] = "当你：1.明置此武将牌后，你可摸两张牌：2.移除此武将牌后，你回复1点体力。",

  ["#guixiu-draw"] = "是否发动“闺秀”，摸两张牌",
  ["#guixiu-recover"] = "是否发动“闺秀”，回复1点体力",

  ["$guixiu1"] = "闺中女子，亦可秀气英拔。",
  ["$guixiu2"] = "闺楼独看花月，倚窗顾影自怜。",
}

return guixiu
