---@param room AbstractRoom
---@param player Player
---@param friend string
---@return boolean
local function HeyuFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    not not table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general:endsWith(friend) or p.deputyGeneral:endsWith(friend))
    end)
end

local heyu = fk.CreateSkill {
  name = "lidian__heyu",
  tags = { Skill.Compulsory },
  dynamic_desc = function(self, player)
    local yuejin, zhangliao = HeyuFriend(Fk:currentRoom(), player, "thoroughbred__yuejin"),
      HeyuFriend(Fk:currentRoom(), player, "thoroughbred__zhangliao")
    if yuejin and zhangliao then
      return "lidian__heyu"
    elseif yuejin then
      return "lidian__heyu_yuejin"
    elseif zhangliao then
      return "lidian__heyu_zhangliao"
    end
    return "dummyskill"
  end,
}

Fk:loadTranslationTable{
  ["lidian__heyu"] = "合御",
  [":lidian__heyu"] = "锁定技，若友方骥乐进在场，你获得因〖断津〗弃置的牌；"..
  "若友方骥张辽在场，〖慨公〗使用的牌不可被响应。（仅斗地主和2v2模式生效）",

  [":lidian__heyu_yuejin"] = "锁定技，若友方骥乐进在场，你获得因〖断津〗弃置的牌。",
  [":lidian__heyu_zhangliao"] = "锁定技，若友方骥张辽在场，〖慨公〗使用的牌不可被响应。",

  ["$lidian__heyu1"] = "",
  ["$lidian__heyu2"] = "",
}

heyu:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(heyu.name) and
      HeyuFriend(player.room, player, "thoroughbred__zhangliao") and
      data.extra_data and data.extra_data.gaigong == player
  end,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

return heyu
