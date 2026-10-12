local mobileZhenyi = fk.CreateSkill {
  name = "mobile__zhenyi",
}

Fk:loadTranslationTable{
  ["mobile__zhenyi"] = "真仪",
  [":mobile__zhenyi"] = "你可以在以下时机弃置相应的标记来发动以下效果：<br>"..
  "当一张判定牌生效前，你可以弃置“紫微”，然后将判定结果改为♠5或<font color='red'>♥5</font>并终止此时机；<br>"..
  "当你处于濒死状态时，你可以弃置“后土”，然后将你的一张手牌当【桃】使用；<br>"..
  "当你造成伤害时，你可以弃置“玉清”，然后判定，若结果为黑色，你令伤害值+1；<br>"..
  "当你受到属性伤害后，你可以弃置“勾陈”，然后你从牌堆或弃牌堆中随机获得三种类型的牌各一张。",

  ["#mobile__zhenyi1"] = "真仪：你可以弃置♠紫微，将 %dest 的判定结果改为♠5或<font color='red'>♥5</font>",
  ["#mobile__zhenyi2"] = "真仪：你可以弃置♣后土，将一张手牌当【桃】使用",
  ["#mobile__zhenyi3"] = "真仪：你可以弃置<font color='red'>♥</font>玉清，对 %dest 造成的伤害+1",
  ["#mobile__zhenyi4"] = "真仪：你可以弃置<font color='red'>♦</font>勾陈，从牌堆中随机获得三种类型的牌各一张",
  ["mobile__zhenyi_spade"] = "将判定结果改为♠5",
  ["mobile__zhenyi_heart"] = "将判定结果改为<font color='red'>♥</font>5",

  ["$mobile__zhenyi1"] = "人道常变，天道如恒。",
  ["$mobile__zhenyi2"] = "既明大道，自显真仪。",
}

mobileZhenyi:addEffect("viewas", {
  anim_type = "support",
  pattern = "peach",
  prompt = "#mobile__zhenyi2",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|^equip",
  },
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@@mobile__faluclub", 1)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("peach")
    c.skillName = mobileZhenyi.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player)
    return player.dying and player:getMark("@@mobile__faluclub") > 0
  end,
})

mobileZhenyi:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mobileZhenyi.name) and player:getMark("@@mobile__faluspade") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = mobileZhenyi.name, prompt = "#mobile__zhenyi1::" .. target.id })
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileZhenyi.name
    local room = player.room
    room:removePlayerMark(player, "@@mobile__faluspade", 1)
    local choice = room:askToChoice(player, { choices = { "mobile__zhenyi_spade", "mobile__zhenyi_heart" }, skill_name = skillName })
    local new_card = Fk:cloneCard(data.card.name, choice == "mobile__zhenyi_spade" and Card.Spade or Card.Heart, 5)
    new_card.skillName = skillName
    new_card.id = data.card.id
    data.card = new_card
    room:sendLog{
      type = "#ChangedJudge",
      from = player.id,
      to = { data.who.id },
      arg2 = new_card:toLogString(),
      arg = skillName,
    }
    return true
  end,
})

mobileZhenyi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mobileZhenyi.name) and player:getMark("@@mobile__faluheart") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = mobileZhenyi.name, prompt = "#mobile__zhenyi3::" .. data.to.id })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@@mobile__faluheart", 1)
    local judge = {
      who = player,
      reason = mobileZhenyi.name,
      pattern = ".|.|black",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data:changeDamage(1)
    end
  end,
})

mobileZhenyi:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(mobileZhenyi.name) and
      player:getMark("@@mobile__faludiamond") > 0 and
      data.damageType ~= fk.NormalDamage
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = mobileZhenyi.name, prompt = "#mobile__zhenyi4" })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@@mobile__faludiamond", 1)
    local cards = {}
    for _, type in ipairs({ "basic", "trick", "equip" }) do
      for _, pile in ipairs({ "drawPile", "discardPile" }) do
        local cardIds = room:getCardsFromPileByRule(".|.|.|.|.|" .. type, 1, pile)
        if #cardIds > 0 then
          table.insertTable(cards, cardIds)
          break
        end
      end
    end

    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = mobileZhenyi.name,
      })
    end
  end,
})

return mobileZhenyi
