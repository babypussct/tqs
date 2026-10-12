local andu = fk.CreateSkill {
  name = "andu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["andu"] = "暗度",
  [":andu"] = "锁定技，当你使用一张<a href='yinping_card'>“阴平”牌</a>结算结束后，随机获得一名其他角色手牌中的一张“阴平”牌。",

  ["yinping_card"] = "牌名第一个字或最后一个字读音为普通话阴平（第一声，如shā、dēng）",
  ["@@yinping_card"] = "阴平",

  ["$andu1"] = "关关难过关关过，阳平今已度，当度阴平。",
  ["$andu2"] = "学海行舟指阴平，真日上竿头，否极泰来。",
}

local yinping_cards = {
  "slash", "collateral", "nullification", "savage_assault", "archery_attack", "amazing_grace",
  "crossbow", "qinggang_sword", "blade", "halberd", "kylin_bow", "eight_diagram", "dayuan", "zixing",
  "fire_attack", "supply_shortage", "fan", "guding_blade",
  --脑洞包
  "n_brick",
  --文和乱武
  "substituting", "replace_with_a_fake",
  --用间
  "bogus_flower", "scrape_poison", "sincere_treat", "seven_stars_precious_sword", "bee_cloth", "women_dress",
  "carrier_pigeon",
  --忠胆英杰
  "diversion", "paranoid", "reinforcement", "abandoning_armor", "crafty_escape", "seven_stars_sword",
  --应变
  "drowning", "unexpectation", "foresight", "black_chain", "dark_armor", "wonder_map",
  --逐鹿
  "yajiao_spear", "night_cloth",
  --衍生牌
  "daggar_in_smile", "enemy_at_the_gates", "raid_and_frontal_attack",
  --国战？
  "befriend_attacking", "known_both", "triblade",
  "lure_tiger", "fight_together", "threaten_emperor", "jingfan",
  "dragon_phoenix", "luminous_pearl",
  --手杀衍生牌
  "ex_eight_diagram", "ex_silver_lion", "catapult", "offensive_siege_engine", "defensive_siege_engine",
  --线下衍生牌
  "jingxiang_golden_age", "caning_whip", "chunqiu_brush", "xuanhua_axe",
  --OL衍生牌
  "shangyang_reform", "qin_dragon_sword", "wheel_cart", "jade_comb", "rhino_comb", "golden_comb",
  "ghost_dragon_blade", "blood_sword", "iron_double_halberd", "golden_coronet", "illusory_coronet", "three_strategies", "sizhao_sword", "sharing_risk",
  --两肋插刀 兄弟齐心 生死与共
  --国际服衍生牌
  "talisman", "moon_spear",
  --十周年衍生牌
  "red_spear", "quenched_blade", "thunder_blade", "siege_engine"
}

andu:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(andu.name) and
        table.contains(yinping_cards, data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      table.insertTable(cards, table.filter(p:getCardIds("h"), function(id)
        return table.contains(yinping_cards, Fk:getCardById(id).trueName)
      end))
    end
    if #cards > 0 then
      local id = room:tableRandomPick(cards)
      room:doIndicate(player, { room:getCardOwner(id) })
      room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, andu.name, nil, false, player)
    end
  end,
})

andu:addAcquireEffect(function(self, player, is_start)
  local room = player.room
  for _, card in ipairs(Fk.cards) do
    if not table.contains(room.disabled_packs, card.package.name) or card.is_derived then
      if table.contains(yinping_cards, card.trueName) then
        room:setCardMark(card, "@@yinping_card", 1)
      end
    end
  end
end)

andu:addLoseEffect(function(self, player, is_death)
  local room = player.room
  for _, card in ipairs(Fk.cards) do
    if card:getMark("@@yinping_card") ~= 0 then
      room:setCardMark(card, "@@yinping_card", 0)
    end
  end
end)

return andu
