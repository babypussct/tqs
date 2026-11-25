#pragma once
#include "server/user/serverplayer.h"
class UserManager {
public:
  std::weak_ptr<ServerPlayer> findPlayerByConnId(int id) const {
    auto it = players.find(id);
    return it == players.end() ? std::weak_ptr<ServerPlayer>{} : it->second;
  }
  std::unordered_map<int, std::weak_ptr<ServerPlayer>> players;
};
