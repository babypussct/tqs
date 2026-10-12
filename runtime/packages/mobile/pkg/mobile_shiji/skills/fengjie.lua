local fengjie = fk.CreateSkill {
  name = "fengjie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fengjie"] = "奉节",
  [":fengjie"] = "锁定技，准备阶段，你选择一名其他角色，直到你下回合开始，每名角色结束阶段，若你选择的角色存活，你将手牌摸或弃至"..
  "与该角色的体力值相同（至多摸至四张）。",

  ["#fengjie-choose"] = "奉节：选择一名角色，每回合结束阶段你将手牌调整至与其体力值相同",
  ["@[chara]fengjie"] = "奉节",

  ["$fengjie1"] = "见贤思齐，内自省也。",
  ["$fengjie2"] = "立本于道，置身于正。",
}

fengjie:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fengjie.name) then
      if player.phase == Player.Start then
        return target == player and #player.room:getOtherPlayers(player, false) > 0
      elseif target.phase == Player.Finish then
        if player:getMark("@[chara]fengjie") == 0 then return end
        local to = player.room:getPlayerById(player:getMark("@[chara]fengjie"))
        return not to.dead and (player:getHandcardNum() > to.hp or (player:getHandcardNum()< math.min(4, to.hp)))
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(player, false),
        skill_name = fengjie.name,
        prompt = "#fengjie-choose",
        cancelable = false,
      })[1]
      room:setPlayerMark(player, "@[chara]fengjie", to.id)
    else
      local x, y = room:getPlayerById(player:getMark("@[chara]fengjie")).hp, player:getHandcardNum()
      if x < y then
        room:askToDiscard(player, {
          min_num = y-x,
          max_num = y-x,
          include_equip = false,
          skill_name = fengjie.name,
          cancelable = false,
        })
      else
        local z = math.min(4, x) - y
        if z > 0 then
          player:drawCards(z, fengjie.name)
        end
      end
    end
  end,
})
fengjie:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@[chara]fengjie") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@[chara]fengjie", 0)
  end,
})

return fengjie
