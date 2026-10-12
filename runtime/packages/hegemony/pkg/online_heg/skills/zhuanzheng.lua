local zhuanzheng = fk.CreateSkill {
  name = "ol_heg__zhuanzheng",
}

Fk:loadTranslationTable {
  ["ol_heg__zhuanzheng"] = "转征",
  [":ol_heg__zhuanzheng"] = "每轮限两次，出牌阶段，你可以选择一名距离1以内的与你势力相同的角色，你摸X张牌，然后其可与你副将<a href='heg__yiwei'>易位</a> (X为你与其之间的角色数且至少为1)。",

  ["#ol_heg__zhuanzheng"] = "转征：选择一名距离1以内的与你势力相同的角色，你摸X张牌，然后其可与你副将易位 (X为你与其之间的角色数且至少为1)",
  ["ol_heg__zhuanzheng__yiwei"] = "与 %src 易位",
  ["ol_heg__zhuanzheng_num"] = "摸%arg张牌",

  ["$ol_heg__zhuanzheng1"] = "急调旌旅，合兵一处。",
  ["$ol_heg__zhuanzheng2"] = "整戎挥师，鼓噪八方。",
}

local H = require "packages.hegemony.util"

zhuanzheng:addEffect("active", {
  prompt = "#ol_heg__zhuanzheng",
  target_num = 1,
  times = function(self, player)
    return 2 - (Fk:currentRoom():getBanner("ol_heg__zhuanzheng-round") or 0)
  end,
  can_use = function(self, player)
    return (Fk:currentRoom():getBanner("ol_heg__zhuanzheng-round") or 0) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards, card, extra_data)
    return #selected == 0 and player:distanceTo(to_select) <= 1 and H.compareKingdomWith(to_select, player)
  end,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not H.compareKingdomWith(to_select, player) then return end
    local tos1 = {}
    local tos2 = {}
    local temp = to_select.next
    while temp ~= player do
      if not temp.dead then
        table.insert(tos1, temp)
      end
      temp = temp.next
    end
    temp = player.next
    while temp ~= to_select do
      if not temp.dead then
        table.insert(tos2, temp)
      end
      temp = temp.next
    end
    local n = math.min(math.max(#tos1, 1), math.max(#tos2, 1))
    if to_select == player then
      n = 1
    end
    if n < 1 then
      return
    else
      return { { content = "ol_heg__zhuanzheng_num:::" .. n, type = "warning" } }
    end
end,
on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    --防止易位后刷新技能
    local n = room:getBanner("ol_heg__zhuanzheng-round") or 0
    room:setBanner("ol_heg__zhuanzheng-round", n + 1)
    local tos1 = {}
    local tos2 = {}
    local temp = to.next
    while temp ~= player and to ~= player do
      if not temp.dead then
        table.insert(tos1, temp)
      end
      temp = temp.next
    end
    temp = player.next
    while temp ~= to and to ~= player do
      if not temp.dead then
        table.insert(tos2, temp)
      end
      temp = temp.next
    end
    player:drawCards(math.min(math.max(#tos1, 1), math.max(#tos2, 1)), zhuanzheng.name)
    local choices = { "ol_heg__zhuanzheng__yiwei:" .. player.id, "Cancel" }
    local choice = to == player and "Cancel" or room:askToChoice(to, {
      choices = choices,
      skill_name = zhuanzheng.name,
      cancelable = true,
    })
    if choice == "ol_heg__zhuanzheng__yiwei:" .. player.id then
      H.swapDeputy(room, player, to)
    end
  end,
})

return zhuanzheng
