local gongmou = fk.CreateSkill{
  name = "os_shi__gongmou",
  related_skills = { "qice" },
}

Fk:loadTranslationTable{
  ["os_shi__gongmou"] = "共谋",
  [":os_shi__gongmou"] = "准备阶段，你可以与一名其他角色交换手牌，若如此做，你获得技能〖奇策〗直到回合结束。",

  ["#os_shi__gongmou-choose"] = "共谋：与一名角色交换手牌，你本回合获得“奇策”",

  ["$os_shi__gongmou1"] = "夫举事而不本于义，未有不败者也。",
  ["$os_shi__gongmou2"] = "君必欲立功明义，全福远祸，不宜与之同也。",
}

gongmou:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(gongmou.name) and player.phase == Player.Start and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = gongmou.name,
      prompt = "#os_shi__gongmou-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if not (player:isKongcheng() and to:isKongcheng()) then
      room:swapAllCards(player, {player, to}, gongmou.name)
    end
    if not player.dead and not player:hasSkill("qice", true) then
      room:handleAddLoseSkills(player, "qice")
      room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
        room:handleAddLoseSkills(player, "-qice")
      end)
    end
  end,
})

return gongmou
