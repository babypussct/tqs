local yaopan = fk.CreateSkill {
  name = "ol_heg__yaopan",
  tags = { Skill.DeputyPlace },
}

Fk:loadTranslationTable{
  ["ol_heg__yaopan"] = "邀叛",
  [":ol_heg__yaopan"] = "副将技，你杀死过角色的回合结束时，你可以指定一名同势力角色，其可以与你副将<a href='heg__yiwei'>易位</a>。"..
  "然后控制此武将牌的角色获得所有“权”，执行一个额外出牌阶段。",

  ["#ol_heg__yaopan-choose"] = "邀叛：令一名同势力角色可以与你副将易位，控制钟会的角色获得“权”并执行额外出牌阶段",
  ["ol_heg__yaopan__yiwei"] = "与 %src 易位",

  ["$ol_heg__yaopan1"] = "得蜀而望天下，事成，当为汉高祖！",
  ["$ol_heg__yaopan2"] = "猛将锐卒尽在我手，怎能再居于人下！"
}

local H = require "packages.hegemony.util"

yaopan:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yaopan.name) and data.phase == Player.Finish and
      #player.room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
        return e.data.killer == player
      end, Player.HistoryTurn) > 0 and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return H.compareKingdomWith(p, player)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return H.compareKingdomWith(p, player)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = yaopan.name,
      prompt = "#ol_heg__yaopan-choose",
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
    local choices = { "ol_heg__yaopan__yiwei:" .. player.id, "Cancel" }
    local choice = to == player and "Cancel" or room:askToChoice(to, {
      choices = choices,
      skill_name = yaopan.name,
      cancelable = true,
    })
    if choice == "ol_heg__yaopan__yiwei:" .. player.id then
      H.swapDeputy(room, player, to)
    else
      to = player
    end
    if #player:getPile("ol_heg__zhonghui_quan") > 0 then
      room:moveCardTo(player:getPile("ol_heg__zhonghui_quan"), Card.PlayerHand, to, fk.ReasonJustMove, yaopan.name, nil, true, to)
    end
    if not to.dead then
      to:gainAnExtraPhase(Player.Play, yaopan.name)
    end
  end,
})

return yaopan
