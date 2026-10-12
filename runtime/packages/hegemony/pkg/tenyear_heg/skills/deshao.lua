local deshao = fk.CreateSkill{
  name = "ty_heg__deshao",
}
local H = require "packages.hegemony.util"
deshao:addEffect(fk.TargetSpecified, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return target ~= player and player:hasSkill(deshao.name) and data:isOnlyTarget(player)
      and data.card.color == Card.Black and H.getGeneralsRevealedNum(player) >= H.getGeneralsRevealedNum(target)
      and player:usedSkillTimes(deshao.name, Player.HistoryTurn) < player.hp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = deshao.name,
      prompt = "#ty_heg__deshao-invoke::"..data.from.id,
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local from = data.from
    if not from:isNude() then
      local id = room:askToChooseCard(player, {
    target = from,
    flag = "he",
    skill_name = deshao.name,
  })
      room:throwCard(id, deshao.name, from, player)
    end
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__deshao"] = "德劭",
  [":ty_heg__deshao"] = "每回合限X次（X为你的体力值），当其他角色使用黑色牌指定你为唯一目标后，若其已明置的武将牌数不大于你，你可弃置其一张牌。",

  ["#ty_heg__deshao-invoke"] = "德劭：你可以弃置 %dest 一张牌",

  ["$ty_heg__deshao1"] = "名德远播，朝野俱瞻。",
  ["$ty_heg__deshao2"] = "增修德信，以诚服人。",
}

return deshao
