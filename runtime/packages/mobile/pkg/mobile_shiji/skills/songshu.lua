local songshu = fk.CreateSkill {
  name = "mobile__songshu",
}

Fk:loadTranslationTable{
  ["mobile__songshu"] = "颂蜀",
  [":mobile__songshu"] = "一名体力值大于你的其他角色摸牌阶段开始时，若“仁”区有牌，你可以令其放弃摸牌，改为获得X张“仁”区牌"..
  "（X为你的体力值，且最大为5）。若如此做，本回合其使用牌时不能指定其他角色为目标。",

  ["#mobile__songshu-invoke"] = "颂蜀：你可以令 %dest 放弃摸牌，改为获得“仁”，且其本回合其使用牌不能指定其他角色为目标",
  ["@@mobile__songshu-turn"] = "颂蜀",
  ["#mobile__songshu-choose"] = "颂蜀：获得%arg张“仁”区牌",

  ["$mobile__songshu1"] = "称美蜀政，祛其疑贰之心。",
  ["$mobile__songshu2"] = "蜀地君明民乐，实乃太平之治。",
}

local U = require "packages.utility.utility"

songshu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(songshu.name) and target.phase == Player.Draw and
      target.hp > player.hp and #U.GetRenPile(player.room) > 0 and not data.phase_end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = songshu.name,
      prompt = "#mobile__songshu-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    room:setPlayerMark(target, "@@mobile__songshu-turn", 1)
    local n = math.min(player.hp, 5, #U.GetRenPile(room))
    local cards = room:askToChooseCards(target, {
      target = target,
      min = n,
      max = n,
      flag = {
        card_data = {{"@$RenPile", U.GetRenPile(room)}}
      },
      prompt = "#mobile__songshu-choose:::"..n,
      skill_name = songshu.name,
    })
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonJustMove, songshu.name, nil, true, target)
  end,
})
songshu:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return from and from:getMark("@@mobile__songshu-turn") > 0 and from ~= to
  end,
})

return songshu
