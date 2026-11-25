#pragma once
#include "server/user/user_manager.h"
class Server {
public:
  static Server &instance() { static Server value; return value; }
  boost::asio::io_context &context() { return main; }
  UserManager &user_manager() { return users; }
private:
  boost::asio::io_context main;
  UserManager users;
};
