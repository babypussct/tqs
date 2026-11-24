// SPDX-License-Identifier: GPL-3.0-or-later

#include "server/main-context-call.h"
#include <atomic>
#include <cstdlib>
#include <iostream>
#include <thread>

using namespace std::chrono_literals;
namespace asio = boost::asio;

static void require(bool condition, const char *message) {
  if (!condition) {
    std::cerr << "FAIL " << message << std::endl;
    std::exit(1);
  }
  std::cout << "PASS " << message << std::endl;
}

int main() {
  {
    asio::io_context context;
    bool called = false;
    asio::post(context, [&] {
      dispatchMainAndWait(context, [&] { called = true; });
      require(called, "inline dispatch completes synchronously");
    });
    context.run();
  }
  {
    asio::io_context context;
    auto guard = asio::make_work_guard(context);
    std::atomic<bool> called = false;
    std::promise<void> returned;
    auto done = returned.get_future();
    std::thread main([&] { context.run(); });
    std::thread worker([&] {
      dispatchMainAndWait(context, [&] { called = true; });
      returned.set_value();
    });
    require(done.wait_for(2s) == std::future_status::ready && called,
            "worker dispatch waits for main callback");
    worker.join();
    guard.reset();
    main.join();
  }
  {
    asio::io_context context;
    context.stop();
    bool called = false;
    dispatchMainAndWait(context, [&] { called = true; });
    require(!called, "already stopped context skips callback");
    context.restart();
    require(context.poll() == 0, "already stopped context enqueues nothing");
  }
  {
    asio::io_context context;
    std::atomic<bool> called = false;
    std::promise<void> starting, returned;
    auto started = starting.get_future();
    auto done = returned.get_future();
    std::thread worker([&] {
      starting.set_value();
      dispatchMainAndWait(context, [&] { called = true; });
      returned.set_value();
    });
    require(started.wait_for(2s) == std::future_status::ready,
            "worker begins pending call");
    require(done.wait_for(50ms) == std::future_status::timeout,
            "pending callback remains synchronous before stop");
    context.stop();
    require(done.wait_for(2s) == std::future_status::ready && !called,
            "stop releases worker without executing pending callback");
    worker.join();
    context.restart();
    require(context.poll() == 1 && !called,
            "cancelled callback cannot run after test-only restart");
  }
  {
    asio::io_context context;
    auto guard = asio::make_work_guard(context);
    std::promise<void> running, release, returned;
    auto entered = running.get_future();
    auto permit = release.get_future();
    auto done = returned.get_future();
    std::atomic<bool> completed = false;
    std::thread main([&] { context.run(); });
    std::thread worker([&] {
      dispatchMainAndWait(context, [&] {
        running.set_value();
        permit.wait();
        completed = true;
      });
      returned.set_value();
    });
    require(entered.wait_for(2s) == std::future_status::ready,
            "main callback is running before stop");
    context.stop();
    require(done.wait_for(50ms) == std::future_status::timeout,
            "stop does not release worker during running callback");
    release.set_value();
    require(done.wait_for(2s) == std::future_status::ready && completed,
            "worker releases after running callback completes");
    worker.join();
    main.join();
  }
}
