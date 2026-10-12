local rencheng = fk.CreateSkill {
  name = "peixiu_rencheng",
}

Fk:loadTranslationTable {
  ["peixiu_rencheng"] = "任城",
  [":peixiu_rencheng"] = "你每有一张【杀】，手牌上限便+1。",
}

rencheng:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(rencheng.name) then
      local n = 0
      for _, id in ipairs(player:getCardIds("h")) do
        if Fk:getCardById(id).trueName == "slash" then
          n = n + 1
        end
      end
      return n
    end
  end,
})

return rencheng
