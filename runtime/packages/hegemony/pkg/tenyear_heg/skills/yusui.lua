local yusui = fk.CreateSkill{
  name = "ty_heg__yusui",
}
local H = require "packages.hegemony.util"
yusui:addEffect(fk.TargetConfirmed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yusui.name) and data.from ~= player and data.card.color == Card.Black and
      player:usedSkillTimes(yusui.name, Player.HistoryTurn) == 0 and H.compareKingdomWith(data.from, player, true) and
      player.hp > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.from
    room:loseHp(player, 1, yusui.name)
    if player.dead then return end
    local choices = {}
    if not to:isKongcheng() then
      table.insert(choices, "ty_heg__yusui_discard::" .. to.id .. ":" .. to.maxHp)
    end
    if to.hp > player.hp then
      table.insert(choices, "ty_heg__yusui_loseHp::" .. to.id .. ":" .. player.hp)
    end
    if #choices == 0 then return false end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = yusui.name,
    })
    if choice:startsWith("ty_heg__yusui_discard") then
      room:askToDiscard(to, {
        min_num = to.maxHp,
        max_num = to.maxHp,
        include_equip = false,
        skill_name = yusui.name,
        cancelable = false,
      })
    else
      room:loseHp(to, to.hp - player.hp, yusui.name)
    end
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__yusui"] = "玉碎",
  [":ty_heg__yusui"] = "每回合限一次，当你成为其他角色使用黑色牌的目标后，若你与其势力不同，你可失去1点体力，然后选择一项：1.令其弃置X张手牌"..
    "（X为其体力上限）；2.令其失去体力值至与你相同。",
  ["ty_heg__yusui_discard"] = "令%dest弃置%arg张手牌",
  ["ty_heg__yusui_loseHp"] = "令%dest失去体力至%arg",
  ["$ty_heg__yusui1"] = "宁为玉碎，不为瓦全！",
  ["$ty_heg__yusui2"] = "生义相左，舍生取义。",
}

return yusui
