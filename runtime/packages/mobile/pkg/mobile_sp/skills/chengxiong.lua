local chengxiong = fk.CreateSkill {
  name = "chengxiong",
}

Fk:loadTranslationTable{
  ["chengxiong"] = "惩凶",
  [":chengxiong"] = "当你使用锦囊牌仅指定其他角色为目标后，你可以选择一名牌数不小于X的角色（X为你此阶段使用的牌数），弃置其一张牌，"..
  "若此牌颜色与你使用的锦囊牌颜色相同，你对其造成1点伤害。",

  ["#chengxiong-choose"] = "惩凶：弃置一名角色一张牌，若为%arg，对其造成1点伤害",
  ["#chengxiong-discard"] = "惩凶：弃置 %dest 一张牌",

  ["$chengxiong1"] = "天子殿前，岂容不节之臣。",
  ["$chengxiong2"] = "陛下有令，还不将其斩之。",
}

chengxiong:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(chengxiong.name) and data.card.type == Card.TypeTrick and data.firstTarget and
      not table.contains(data.use.tos, player) then
      local room = player.room
      local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        return e.data.from == player
      end, Player.HistoryPhase)
      return table.find(room.alive_players, function(p)
        return #p:getCardIds("he") >= n
      end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      return e.data.from == player
    end, Player.HistoryPhase)
    local targets = table.filter(room.alive_players, function(p)
      return #p:getCardIds("he") >= n
    end)
    if not table.find(player:getCardIds("he"), function (id)
      return not player:prohibitDiscard(id)
    end) == 0 then
      table.removeOne(targets, player)
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = chengxiong.name,
      prompt = "#chengxiong-choose:::"..data.card:getColorString(),
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
    local card
    if to == player then
      card = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = chengxiong.name,
        prompt = "#chengxiong-discard::"..to.id,
        cancelable = false,
        skip = true,
      })[1]
    else
      card = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = chengxiong.name,
        prompt = "#chengxiong-discard::"..to.id,
      })
    end
    local color = Fk:getCardById(card).color
    room:throwCard(card, chengxiong.name, to, player)
    if color == data.card.color and color ~= Card.NoColor and not to.dead then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = chengxiong.name,
      }
    end
  end,
})

return chengxiong
