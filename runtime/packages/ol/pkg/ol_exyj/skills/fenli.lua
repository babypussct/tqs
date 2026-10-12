
local fenli = fk.CreateSkill {
  name = "ol_ex__fenli",
}

Fk:loadTranslationTable{
  ["ol_ex__fenli"] = "奋励",
  [":ol_ex__fenli"] = "若你的手牌数/体力值/装备区里的牌数为全场最大，你可以跳过摸牌阶段/出牌阶段/弃牌阶段。",

  ["#ol_ex__fenli-invoke"] = "奋励：你可以跳过%arg",

  ["$ol_ex__fenli1"] = "",
  ["$ol_ex__fenli2"] = "",
}

fenli:addEffect(fk.EventPhaseChanging, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fenli.name) and not data.skipped then
      if data.phase == Player.Draw then
        return table.every(player.room:getOtherPlayers(player), function (p)
          return p:getHandcardNum() <= player:getHandcardNum()
        end)
      elseif data.phase == Player.Play then
        return table.every(player.room:getOtherPlayers(player), function (p)
          return p.hp <= player.hp
        end)
      elseif data.phase == Player.Discard then
        return table.every(player.room:getOtherPlayers(player), function (p)
          return #p:getCardIds("e") <= #player:getCardIds("e")
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = fenli.name,
      prompt = "#ol_ex__fenli-invoke:::"..Util.PhaseStrMapper(data.phase),
    })
  end,
  on_use = function(self, event, target, player, data)
    player:skip(data.phase)
    data.skipped = true
  end,
})

return fenli
