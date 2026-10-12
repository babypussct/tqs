local daohuo = fk.CreateSkill {
  name = "ol_heg__daohuo",
}

Fk:loadTranslationTable {
  ["ol_heg__daohuo"] = "蹈火",
  [":ol_heg__daohuo"] = "出牌阶段限一次，你可以将两张颜色不同的牌当火【杀】使用。" ..
  "此【杀】指定唯一目标后，其选择一项：1.令你将“阴阳鱼”标记补至1；2.你选择另一名与目标势力相同的角色，" ..
  "其与目标角色副将<a href='heg__yiwei'>易位</a>。",
  ["#ol_heg__daohuo"] = "蹈火：你可以将两张颜色不同的牌当火【杀】使用",

  ["ol_heg__daohuo_getyinyangfish"] = "令 %src 将“阴阳鱼”标记补至1",
  ["ol_heg__daohuo_yiwei"] = "%src 选择你与另一名同势力角色易位",
  ["#heg_getyinyangfish"] = "%from 获得了一枚<font color=\"#DC143C\"><b> 阴阳鱼 </b></font>标记",

  ["$ol_heg__daohuo1"] = "将士们，引火对敌！",
  ["$ol_heg__daohuo2"] = "和我同归于尽吧！",
}

local H = require "packages.hegemony.util"

daohuo:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#ol_heg__daohuo",
  pattern = "fire__slash",
  mute_card = false,
  handly_pile = true,
  filter_pattern = {
    min_num = 2,
    max_num = 2,
    pattern = "",
    subcards = {}
  },
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:getCardById(to_select):compareColorWith(Fk:getCardById(selected[1]), true)
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 then return end
    local c = Fk:cloneCard("fire__slash")
    c.skillName = daohuo.name
    c:addSubcards(cards)
    return c
  end,
  enabled_at_play = function(self, player)
    return player.phase == Player.Play and player:usedSkillTimes(daohuo.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = Util.FalseFunc,
})

daohuo:addEffect(fk.TargetSpecified, {
  anim_type = "special",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(daohuo.name) and table.contains(data.card.skillNames, daohuo.name)
    and data:isOnlyTarget(data.to) and data.card.name == "fire__slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = { "ol_heg__daohuo_getyinyangfish:" .. player.id }
    if table.find(room:getOtherPlayers(data.to), function(p) return H.compareKingdomWith(p, data.to) end) then
      table.insert(choices, "ol_heg__daohuo_yiwei:" .. player.id)
    end
    local choice = room:askToChoice(data.to, {
      choices = choices,
      skill_name = daohuo.name,
      all_choices = { "ol_heg__daohuo_getyinyangfish:" .. player.id, "ol_heg__daohuo_yiwei:" .. player.id },
      cancelable = false,
    })
    if choice == "ol_heg__daohuo_getyinyangfish:" .. player.id then
      if player:getMark("@!!yinyangfish") == 0 then
        H.addHegMark(player, "yinyangfish")
        room:sendLog {
          type = "#heg_getyinyangfish",
          from = player.id,
          toast = true,
        }
      end
    else
      local tos = table.filter(room:getOtherPlayers(data.to), function(p) return H.compareKingdomWith(p, data.to) end)
      local to = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        skill_name = daohuo.name,
        cancelable = false,
      })
      if #to > 0 then
        H.swapDeputy(room, data.to, to[1])
      end
    end
  end,
})

return daohuo
