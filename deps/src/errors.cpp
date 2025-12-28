// errors.cpp - Error handling bindings for libsemigroups_julia
//
// This file provides error handling utilities that capture libsemigroups
// exceptions and make them accessible from Julia.

#include "libsemigroups_julia.hpp"

namespace libsemigroups_julia {

// Error log to capture exception messages
static std::vector<std::string> error_log;

// Clear the error log
void clear_error_log()
{
  error_log.clear();
}

// Add an error message to the log
void log_error(const std::string & msg)
{
  error_log.push_back(msg);
}

// Check if there are any logged errors
bool have_error()
{
  return !error_log.empty();
}

// Get all error messages and clear the log
std::string get_and_clear_errors()
{
  std::stringstream ss;
  for (const auto & msg : error_log)
  {
    ss << msg << std::endl;
  }
  error_log.clear();
  return ss.str();
}

void define_errors(jl::Module & m)
{
  // Error checking and retrieval
  m.method("have_error", &have_error);
  m.method("get_and_clear_errors", &get_and_clear_errors);
  m.method("clear_error_log", &clear_error_log);

  // Helper function to safely execute a function and catch exceptions
  // This is used internally by other binding functions
  m.method("_try_catch_test", []() -> bool {
    try
    {
      // Test that exception handling works
      throw std::runtime_error("test exception");
    } catch (const std::runtime_error & e)
    {
      log_error(e.what());
      return false;
    }
    return true;
  });
}

}    // namespace libsemigroups_julia
