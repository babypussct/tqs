#pragma once
#include "network/router.h"
class ServerPlayer {
public:
  explicit ServerPlayer(int id) : id(id), routing(this, nullptr, Router::TYPE_SERVER) {}
  std::string getScreenName() const { return "fixture"; }
  int getConnId() const { return id; }
  Router &router() { return routing; }
  void onDisconnected() { ++disconnects; routing.setSocket(nullptr); }
  int disconnects = 0;
private:
  int id;
  Router routing;
};
