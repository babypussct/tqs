#pragma once
#include "server/task/task_manager.h"
#include "server/gamelogic/roomthread.h"
class Server {
public:
  static Server &instance() { static Server value; return value; }
  boost::asio::io_context &context() { return ctx; }
  TaskManager &task_manager() { return manager; }
  RoomThread &getAvailableThread() { return *thread; }
  void flush() { ctx.restart(); ctx.poll(); }
  boost::asio::io_context ctx;
  std::shared_ptr<RoomThread> thread = std::make_shared<RoomThread>();
  TaskManager manager;
};
