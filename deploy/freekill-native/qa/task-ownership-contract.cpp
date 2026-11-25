#include "server/server.h"
#include "server/task/task.h"
#include <cassert>
#include <future>
#include <iostream>
#include <thread>

int main() {
  auto &server = Server::instance();
  auto &registry = server.task_manager();
  auto &worker = *server.thread;
  auto created = registry.createTask("probe", "payload");
  const auto id = created->getId();
  registry.attachTaskToUser(id, 123);
  registry.setTaskExpectedReplyId(id, 456);
  assert(registry.getTaskByRequestId(456) == created);
  assert(registry.getTaskIdsByUser(123) == std::vector<int>{id});
  created.reset();
  std::promise<void> lookedUp;
  std::promise<void> removed;
  auto ready = lookedUp.get_future();
  auto gone = removed.get_future();
  std::thread reader([&] {
    auto task = registry.getTask(id);
    lookedUp.set_value();
    gone.wait();
    assert(task->getId() == id);
    assert(task->getData() == "payload");
    task->resume("late");
    task->delay(10);
  });
  ready.wait();
  worker.onRetire = [&] { assert(!registry.getTask(id)); };
  registry.removeTask(id);
  removed.set_value();
  reader.join();
  server.flush();
  assert(!registry.getTask(id));
  assert(!registry.getTaskByRequestId(456));
  assert(registry.getTaskIdsByUser(123).empty());
  assert(worker.refs == 0 && worker.aborts == 1 && worker.delayed == 0);
  assert(worker.reasons == std::vector<std::string>{"abort"});
  std::cout << "PASS lookup/remove lifetime, index cleanup, reentrant retirement, stale callback rejection\n";
  worker.onRetire = {};
  auto task = registry.createTask("probe", "");
  std::thread caller([&] {
    task->resume(std::string("a\0b", 3));
    task->delay(42);
  });
  caller.join();
  server.flush();
  assert(worker.reasons.back() == std::string("a\0b", 3));
  assert(worker.delayed == 42);
  std::cout << "PASS worker resume/delay dispatch, owned binary reason\n";
  worker.onPush = [&] {
    assert(task->getRefCount() == 1);
    std::thread completion([&] { task->decreaseRefCount(); task->decreaseRefCount(); });
    completion.join();
  };
  task->start();
  server.flush();
  assert(!registry.getTask(task->getId()));
  assert(task->getRefCount() == 0 && worker.refs == 0 && worker.aborts == 2);
  std::cout << "PASS immediate completion, duplicate decrement, exactly-once retirement\n";
  worker.onPush = {};
  auto first = registry.createTask("first", "");
  auto second = registry.createTask("second", "");
  registry.attachTaskToUser(first->getId(), 123);
  registry.attachTaskToUser(second->getId(), 123);
  registry.setTaskExpectedReplyId(first->getId(), 456);
  registry.setTaskExpectedReplyId(second->getId(), 456);
  registry.removeTask(first->getId());
  assert(registry.getTaskByRequestId(456) == second);
  registry.removeAllTasksByUser(123);
  assert(!registry.getTask(second->getId()) && !registry.getTaskByRequestId(456));
  assert(worker.refs == 0 && worker.aborts == 4);
  std::cout << "PASS request index replacement and user cleanup\n";
  auto third = registry.createTask("third", "");
  registry.removeTasksForThread(worker);
  assert(!registry.getTask(third->getId()) && worker.refs == 0 && worker.aborts == 5);
  std::cout << "PASS worker cleanup with held snapshot\n";
  auto duplicate = registry.createTask("duplicate", "");
  const auto pushes = worker.pushes;
  duplicate->start();
  duplicate->start();
  assert(worker.pushes == pushes + 1 && duplicate->getRefCount() == 1);
  registry.removeTask(duplicate->getId());
  std::cout << "PASS duplicate start\n";
  for (bool reject : {false, true}) {
    auto failed = registry.createTask("failed", "");
    registry.attachTaskToUser(failed->getId(), 777);
    worker.accept = !reject;
    if (!reject) worker.onPush = [] { throw std::runtime_error("injected failure"); };
    bool threw = false;
    try { failed->start(); } catch (const std::exception &) { threw = true; registry.removeTask(failed->getId()); }
    assert(threw && failed->getRefCount() == 0 && worker.refs == 0);
    assert(!registry.getTask(failed->getId()) && registry.getTaskIdsByUser(777).empty());
    worker.onPush = {};
    worker.accept = true;
  }
  std::cout << "PASS rejected and throwing start rollback\n";
  auto live = registry.createTask("live", "");
  registry.attachTaskToUser(live->getId(), 123);
  registry.setTaskExpectedReplyId(live->getId(), 456);
  live->start();
  std::atomic<bool> done = false;
  std::thread concurrent([&] {
    while (!done.load()) {
      auto current = registry.getTask(live->getId());
      auto request = registry.getTaskByRequestId(456);
      auto users = registry.getTaskIdsByUser(123);
      if (current) assert(current == live);
      if (request) assert(request == live);
      assert(users.empty() || users == std::vector<int>{live->getId()});
    }
  });
  for (int i = 0; i < 1000; ++i) registry.setTaskExpectedReplyId(live->getId(), i % 2 ? 456 : 457);
  registry.clear();
  done = true;
  concurrent.join();
  assert(worker.refs == 0 && !registry.getTask(live->getId()) && live->getRefCount() == 0);
  assert(!registry.getTaskByRequestId(456) && !registry.getTaskByRequestId(457));
  assert(registry.getTaskIdsByUser(123).empty());
  live->resume("stale");
  server.flush();
  assert(worker.reasons.back() == "abort");
  registry.clear();
  std::cout << "PASS concurrent lookup/index updates and idempotent shutdown clear\n";
}
