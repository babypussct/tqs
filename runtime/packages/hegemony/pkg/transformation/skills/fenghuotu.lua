local fenghuotu = fk.CreateSkill{
  name = "#fenghuotu",
  tags = {Skill.Compulsory},
}

Fk:loadTranslationTable{
  ["$fenghuotu1"] = "保卫国家，人人有责。",
  ["$fenghuotu2"] = "连绵的烽火，就是对敌人最好的震慑！",
  ["$fenghuotu3"] = "有敌来犯，速速御敌。",
  ["$fenghuotu4"] = "来，扶孤上马迎敌！",

  ["#ld__jiahe_damaged"] = "缘江烽火图：将一张“烽火”置入弃牌堆",

  ["#fenghuotu-choose"] = "缘江烽火图：可选择%arg个技能",
}
local H = require "packages.hegemony.util"
local U = require "packages.utility.utility"

fenghuotu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return H.compareKingdomWith(player, target) and player:hasSkill(fenghuotu.name) and #player:getPile("lord_fenghuo") > 0 and target.phase == Player.Start
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local skills = {"ld__lordsunquan_yingzi", "ld__lordsunquan_haoshi", "ld__lordsunquan_shelie", "ld__lordsunquan_duoshi"}
    local num = #player:getPile("lord_fenghuo") >= 5 and 2 or 1
    local choice = U.askToChooseSkills(target, {
      skills = table.slice(skills, 1, #player:getPile("lord_fenghuo") + 1),
      min_num = num,
      max_num = num,
      skill_name = fenghuotu.name,
      prompt = "#fenghuotu-choose:::" .. tostring(num),
    })
    if #choice > 0 then
      room:handleAddLoseSkills(target, table.concat(choice, "|"), nil, true, false)
      room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
        room:handleAddLoseSkills(target, '-' .. table.concat(choice, "|-"), nil, true, false)
      end)
    end
  end,
})
fenghuotu:addEffect(fk.Damaged, {
  can_trigger = function (self, event, target, player, data)
    local type_remove = data.card and (data.card.type == Card.TypeTrick or data.card.trueName == "slash")
    if table.find(player.room.alive_players, function (p) return p:getMark("@@wk_heg__huanglong_change") ~= 0 end) then
      type_remove = data.card and (data.card.trueName == "slash")
    end
    return player == target and player:hasSkill(fenghuotu.name) and #player:getPile("lord_fenghuo") > 0 and type_remove
  end,
  on_cost = function (self, event, target, player, data)
    local card = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fenghuotu.name,
      pattern = ".|.|.|lord_fenghuo",
      prompt = "#ld__jiahe_damaged",
      cancelable = true,
      expand_pile = "lord_fenghuo",
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self).cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, fenghuotu.name, nil, true, player)
  end,
})
local fenghuotu_attach = function (player)
  local room = player.room
  local players = room.alive_players
  local lordsunquans = table.filter(players, function(p) return p:hasShownSkill(fenghuotu.name) end)
  local jiahe_map = {}
  for _, p in ipairs(players) do
    local will_attach = false
    for _, ld in ipairs(lordsunquans) do
      if H.compareKingdomWith(ld, p) then
        will_attach = true
        break
      end
    end
    jiahe_map[p] = will_attach
  end
  for p, v in pairs(jiahe_map) do
    if v ~= p:hasSkill("ld__jiahe_other&") then
      room:handleAddLoseSkills(p, v and "ld__jiahe_other&" or "-ld__jiahe_other&", nil, false, true)
    end
  end
end
fenghuotu:addAcquireEffect(function (self, player, is_start)
  fenghuotu_attach(player)
end)
fenghuotu:addLoseEffect(function (self, player, is_death)
  fenghuotu_attach(player)
end)
fenghuotu:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    fenghuotu_attach(player)
  end,
})

return fenghuotu
