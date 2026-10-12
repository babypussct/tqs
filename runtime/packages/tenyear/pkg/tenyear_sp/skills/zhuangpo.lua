local zhuangpo = fk.CreateSkill {
  name = "zhuangpo",
}

Fk:loadTranslationTable{
  ["zhuangpo"] = "壮魄",
  [":zhuangpo"] = "你可以将牌面信息中有【杀】字的牌当【决斗】使用。若你拥有“擎”，则此【决斗】指定目标后，你可以移去任意个“擎”，"..
  "然后令其弃置等量的牌；若此【决斗】指定了有“擎”的角色为目标，则你摸一张牌且此【决斗】伤害+1。",

  ["#zhuangpo"] = "壮魄：将牌面信息中有“【杀】”的牌当【决斗】使用",
  ["@zhengqing_qing"] = "擎",
  ["#zhuangpo-choice"] = "壮魄：你可以移去任意枚“擎”标记，令 %dest 弃置等量的牌",

  ["$zhuangpo1"] = "腹吞龙虎，气撼山河！",
  ["$zhuangpo2"] = "神魄凝威，魍魉辟易！"
}

zhuangpo:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "duel",
  prompt = "#zhuangpo",
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and
      (Fk:getCardById(to_select).trueName == "slash" or
      string.find(Fk:translate(":"..Fk:getCardById(to_select).name, "zh_CN"), "【杀】")) and
      #player:getViewAsCardNames(zhuangpo.name, {"duel"}, {to_select}) > 0
  end,
  handly_pile = true,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("duel")
    c.skillName = zhuangpo.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

zhuangpo:addEffect(fk.TargetSpecified, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhuangpo.name) and
      table.contains(data.card.skillNames, zhuangpo.name) then
      if data.firstTarget and
        table.find(data.use.tos, function(p)
          return p:getMark("@zhengqing_qing") > 0
        end) then
        return true
      end
      if player:getMark("@zhengqing_qing") > 0 and not data.to:isNude() then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@zhengqing_qing") > 0 and not data.to.dead and not data.to:isNude() then
      local choices = {}
      for i = 1, player:getMark("@zhengqing_qing") do
        table.insert(choices, tostring(i))
      end
      table.insert(choices, "Cancel")
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = zhuangpo.name,
        prompt = "#zhuangpo-choice::" .. data.to.id,
      })
      if choice ~= "Cancel" then
        local n = tonumber(choice)  ---@cast n integer
        room:removePlayerMark(player, "@zhengqing_qing", n)
        room:askToDiscard(data.to, {
          min_num = n,
          max_num = n,
          include_equip = true,
          skill_name = zhuangpo.name,
          cancelable = false,
        })
      end
    end
    if data.firstTarget and
      table.find(data.use.tos, function(p)
        return p:getMark("@zhengqing_qing") > 0
      end) then
      if not player.dead then
        player:drawCards(1, zhuangpo.name)
      end
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

return zhuangpo
