local miaolue = fk.CreateSkill{
  name = "os__miaolue",
}

Fk:loadTranslationTable{
  ["os__miaolue"] = "妙略",
  [":os__miaolue"] = "游戏开始时，你获得两张<a href=':underhanding'>【瞒天过海】</a>；当你受到1点伤害后，你可以选择一项：" ..
  "1.获得一张【瞒天过海】并摸一张牌；2.从牌堆或弃牌堆获得一张你指定的<a href='bag_of_tricks'>智囊</a>。",

  ["bag_of_tricks"] = "#\"<b>智囊</b>\" ：即【过河拆桥】【无懈可击】【无中生有】。",
  ["os__miaolue_underhanding"] = "获得一张【瞒天过海】并摸一张牌",
  ["os__miaolue_zhinang"] = "获得一张你指定的“智囊”",
  ["#os__miaolue-ask"] = "妙略：选择要获得的一种“智囊”",

  ["$os__miaolue1"] = "智者通权达变，以解临近之难。",
  ["$os__miaolue2"] = "依吾计而行，此患乃除耳。",
}

local U = require "packages.utility.utility"

local miaolue_derivecards = {
  {"underhanding", Card.Spade, 5},
  {"underhanding", Card.Heart, 5},
  {"underhanding", Card.Club, 5},
  {"underhanding", Card.Diamond, 5},
}

miaolue:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(miaolue.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cids = table.filter(room:prepareDeriveCards(miaolue_derivecards, miaolue.name), function (id)
      return room:getCardArea(id) == Card.Void
    end)
    if #cids > 0 then
      room:obtainCard(player, room:tableRandomPick(cids, 2), false, fk.ReasonJustMove, player, miaolue.name, MarkEnum.DestructIntoDiscard)
    end
  end,
})

miaolue:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"os__miaolue_underhanding", "os__miaolue_zhinang", "Cancel"},
      skill_name = miaolue.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "os__miaolue_underhanding" then
      local cids = table.filter(room:prepareDeriveCards(miaolue_derivecards, miaolue.name), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if #cids == 0 then
        cids = table.filter(room:prepareDeriveCards(miaolue_derivecards, miaolue.name), function (id)
          return table.contains(room.draw_pile, id)
        end)
      end
      if #cids > 0 then
        room:obtainCard(player, room:tableRandomPick(cids), false, fk.ReasonJustMove, player, miaolue.name, MarkEnum.DestructIntoDiscard)
        if player.dead then return end
      end
      player:drawCards(1, miaolue.name)
    else
      local choice = room:askToChoice(player, {
        choices = {"dismantlement", "nullification", "ex_nihilo"},
        skill_name = miaolue.name,
        prompt = "#os__miaolue-ask",
      })
      local id = room:getCardsFromPileByRule(choice, 1, "allPiles")
      if #id > 0 then
        room:obtainCard(player, id, false, fk.ReasonJustMove, player, miaolue.name)
      end
    end
  end,
})

return miaolue
